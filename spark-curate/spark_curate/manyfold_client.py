"""kubectl exec wrapper for Manyfold (INIT-021/SPEC-013).

Dump-derived names never enter a ``rails runner`` script body. Paths travel
as a JSON array on stdin. Invocation is an argument vector — never a shell
string a quote can break out of.

Transient kubelet failures (502/503/timeout dialing) retry with bounded
exponential backoff. Exhausting retries is a STOP. 401/403 are permanent
and stop on the first attempt.
"""
from __future__ import annotations

import json
import re
import subprocess
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from typing import Any, Literal

PROVENANCE = "INIT-021/SPEC-013"

DEFAULT_NAMESPACE = "manyfold"
DEFAULT_TARGET = "deploy/manyfold"
DEFAULT_MAX_RETRIES = 5
DEFAULT_BACKOFF_SECONDS = 1.0
DEFAULT_TIMEOUT_SECONDS = 120.0
VERIFY_PAGE_SIZE = 100  # must match the runner's each_slice; never load Model.all

# Static runners — no dump-derived text is interpolated into these strings.
# Paths arrive as JSON on stdin (newlines inside a name stay escaped).
SCAN_RUNNER = """
require "json"
raw = STDIN.read
paths = JSON.parse(raw)
raise "expected JSON array" unless paths.is_a?(Array)
library = Library.order(:id).first
raise "no library" unless library
paths.each do |rel|
  raise "path must be a String" unless rel.is_a?(String)
  library.create_model_from_path_later(rel)
end
puts({enqueued: paths.size}.to_json)
""".strip()

# Batched by path — never Model.all. tag_list non-empty = tags applied.
# On-disk datapackage.json is not consulted.
VERIFY_RUNNER = """
require "json"
raw = STDIN.read
paths = JSON.parse(raw)
raise "expected JSON array" unless paths.is_a?(Array)
page = 100
results = []
paths.each_slice(page) do |batch|
  models = Model.where(path: batch)
  by_path = models.index_by(&:path)
  batch.each do |rel|
    m = by_path[rel]
    if m.nil?
      results << {path: rel, status: "absent"}
    elsif m.tag_list.empty?
      results << {path: rel, status: "untagged", model_id: m.id, tag_count: 0}
    else
      results << {path: rel, status: "tagged", model_id: m.id, tag_count: m.tag_list.size}
    end
  end
end
puts({results: results}.to_json)
""".strip()

# Read-only archive_entries page — offset/limit on stdin JSON; no dump paths in script.
LIBRARY_MEMBERS_RUNNER = """
require "json"
req = JSON.parse(STDIN.read)
raise "expected JSON object" unless req.is_a?(Hash)
offset = req.fetch("offset", 0).to_i
limit = req.fetch("limit", 5000).to_i
limit = 5000 if limit <= 0 || limit > 5000
rows = ArchiveEntry
  .joins(model_file: :model)
  .where(kind: "mesh")
  .order("archive_entries.id ASC")
  .offset(offset)
  .limit(limit)
  .pluck(
    "archive_entries.pathname",
    "archive_entries.size",
    "models.path",
    "model_files.id",
    "model_files.digest"
  )
entries = rows.map do |pathname, size, model_path, model_file_id, digest|
  {
    pathname: pathname,
    size: size,
    model_path: model_path,
    model_file_id: model_file_id,
    digest: digest
  }
end
puts({offset: offset, limit: limit, count: entries.size, entries: entries}.to_json)
""".strip()

# Coverage stats for archive recall summary — read-only, no side effects.
LIBRARY_COVERAGE_RUNNER = """
require "json"
ae_total = ArchiveEntry.count
ae_with_size = ArchiveEntry.where.not(size: nil).count
mesh_total = ArchiveEntry.where(kind: "mesh").count
mesh_distinct = ActiveRecord::Base.connection.select_value(
  "SELECT COUNT(*) FROM (SELECT DISTINCT pathname, size FROM archive_entries WHERE kind = 'mesh') t"
).to_i
mf_total = ModelFile.count
mf_with_size = ModelFile.where.not(size: nil).count
mf_with_digest = ModelFile.where.not(digest: nil).count
archives_total = ModelFile.where("filename ~* ?", "\\\\.(zip|rar|7z|sevenz)$").count
archives_indexed = ArchiveEntry.select(:model_file_id).distinct.count
puts({
  archive_entries_total: ae_total,
  archive_entries_with_size: ae_with_size,
  mesh_entries: mesh_total,
  mesh_distinct_pathname_size: mesh_distinct,
  model_files_total: mf_total,
  model_files_with_size: mf_with_size,
  model_files_with_digest: mf_with_digest,
  library_archives_total: archives_total,
  library_archives_indexed: archives_indexed,
  library_archives_unindexed: archives_total - archives_indexed
}.to_json)
""".strip()

_RE_401 = re.compile(r"\b401\b")
_RE_403 = re.compile(r"\b403\b")
_RE_502 = re.compile(r"\b502\b")
_RE_503 = re.compile(r"\b503\b")
_SECRET_RE = re.compile(
    r"(bearer\s+\S+|kubeconfig\s+\S+|BEGIN [A-Z ]*PRIVATE[A-Z ]*|eyJ[A-Za-z0-9_-]{20,})",
    re.IGNORECASE,
)

LogFn = Callable[..., None]
SleepFn = Callable[[float], None]
RunFn = Callable[..., subprocess.CompletedProcess[bytes]]


class KubectlError(Exception):
    """Base for kubectl exec failures."""

    def __init__(
        self,
        message: str,
        *,
        returncode: int | None = None,
        classification: str = "permanent",
    ) -> None:
        super().__init__(message)
        self.returncode = returncode
        self.classification = classification


class TransientKubectlError(KubectlError):
    """A single transient kubelet/proxy failure (may be retried)."""


class PermanentKubectlError(KubectlError):
    """Authorization or other non-retryable failure. Stop immediately."""


class KubectlRetriesExhausted(KubectlError):
    """Transient failures exhausted the retry budget. STOP, do not skip."""


def redact_stderr(text: str, limit: int = 240) -> str:
    """Trim kubectl stderr for logs — never kubeconfig/token material."""
    redacted = _SECRET_RE.sub("<redacted>", text)
    return redacted[:limit]


def classify_kubectl_failure(stderr: str, returncode: int) -> Literal["transient", "permanent"]:
    """Classify a non-zero kubectl exec. Permanent wins over transient.

    401/403 are always permanent so an auth failure cannot be retried as a
    502. Unknown non-zero is permanent (fail closed).
    """
    text = stderr.lower()
    if (
        _RE_401.search(stderr)
        or _RE_403.search(stderr)
        or "unauthorized" in text
        or "forbidden" in text
    ):
        return "permanent"
    if (
        _RE_502.search(stderr)
        or _RE_503.search(stderr)
        or "bad gateway" in text
        or "service unavailable" in text
        or ("timeout" in text and "dial" in text)
        or "i/o timeout" in text
        or ("proxy error" in text and "10250" in text)
    ):
        return "transient"
    return "permanent"


def default_log(event: str, **fields: Any) -> None:
    rec = {"event": event, "provenance": PROVENANCE}
    rec.update(fields)
    print(json.dumps(rec, ensure_ascii=False), flush=True)


def _default_run(
    argv: Sequence[str],
    **kwargs: Any,
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        list(argv),
        input=kwargs.get("input"),
        capture_output=True,
        timeout=kwargs.get("timeout"),
        check=False,
        shell=False,
    )


@dataclass(frozen=True)
class PathVerifyResult:
    path: str
    status: str  # tagged | untagged | absent
    model_id: int | None = None
    tag_count: int = 0

    @property
    def ok(self) -> bool:
        return self.status == "tagged" and self.tag_count > 0


class ManyfoldClient:
    """argv-based ``kubectl exec`` into deploy/manyfold."""

    def __init__(
        self,
        *,
        namespace: str = DEFAULT_NAMESPACE,
        target: str = DEFAULT_TARGET,
        max_retries: int = DEFAULT_MAX_RETRIES,
        backoff_base: float = DEFAULT_BACKOFF_SECONDS,
        timeout: float = DEFAULT_TIMEOUT_SECONDS,
        kubectl_bin: str = "kubectl",
        log: LogFn | None = None,
        sleep_fn: SleepFn | None = None,
        run_fn: RunFn | None = None,
    ) -> None:
        if max_retries < 1 or max_retries > 9:
            raise ValueError("max_retries must be a single-digit count >= 1")
        if backoff_base <= 0:
            raise ValueError("backoff_base must be positive")
        self.namespace = namespace
        self.target = target
        self.max_retries = max_retries
        self.backoff_base = backoff_base
        self.timeout = timeout
        self.kubectl_bin = kubectl_bin
        self._log = log or default_log
        self._sleep = sleep_fn or __import__("time").sleep
        self._run = run_fn or _default_run

    def build_exec_argv(
        self,
        container_argv: Sequence[str],
        *,
        stdin_attached: bool,
    ) -> list[str]:
        argv = [self.kubectl_bin, "exec"]
        if stdin_attached:
            argv.append("-i")
        argv.extend(["-n", self.namespace, self.target, "--"])
        argv.extend(container_argv)
        return argv

    def exec_argv(
        self,
        container_argv: Sequence[str],
        *,
        stdin: bytes | None = None,
    ) -> subprocess.CompletedProcess[bytes]:
        """Run ``kubectl exec -- <container_argv>`` with bounded retry."""
        argv = self.build_exec_argv(container_argv, stdin_attached=stdin is not None)
        last_stderr = ""
        last_code: int | None = None
        for attempt in range(1, self.max_retries + 1):
            try:
                proc = self._run(
                    argv,
                    input=stdin,
                    timeout=self.timeout,
                    shell=False,
                )
            except subprocess.TimeoutExpired as e:
                last_stderr = f"timeout dialing kubectl after {self.timeout}s"
                last_code = -1
                self._log(
                    "kubectl_transient",
                    attempt=attempt,
                    max_retries=self.max_retries,
                    reason="timeout",
                    detail=redact_stderr(last_stderr),
                )
                if attempt >= self.max_retries:
                    self._log(
                        "kubectl_retries_exhausted",
                        attempts=attempt,
                        max_retries=self.max_retries,
                    )
                    raise KubectlRetriesExhausted(
                        "transient kubectl exec retries exhausted (timeout)",
                        returncode=-1,
                        classification="transient_exhausted",
                    ) from e
                delay = self.backoff_base * (2 ** (attempt - 1))
                self._sleep(delay)
                continue

            if proc.returncode == 0:
                return proc

            stderr = proc.stderr.decode("utf-8", errors="replace") if proc.stderr else ""
            last_stderr = stderr
            last_code = proc.returncode
            kind = classify_kubectl_failure(stderr, proc.returncode)
            if kind == "permanent":
                self._log(
                    "kubectl_permanent",
                    attempt=attempt,
                    returncode=proc.returncode,
                    detail=redact_stderr(stderr),
                )
                raise PermanentKubectlError(
                    f"kubectl exec permanent failure (exit {proc.returncode})",
                    returncode=proc.returncode,
                    classification="permanent",
                )
            self._log(
                "kubectl_transient",
                attempt=attempt,
                max_retries=self.max_retries,
                returncode=proc.returncode,
                detail=redact_stderr(stderr),
            )
            if attempt >= self.max_retries:
                self._log(
                    "kubectl_retries_exhausted",
                    attempts=attempt,
                    max_retries=self.max_retries,
                    returncode=proc.returncode,
                )
                raise KubectlRetriesExhausted(
                    f"transient kubectl exec retries exhausted (exit {proc.returncode})",
                    returncode=proc.returncode,
                    classification="transient_exhausted",
                )
            delay = self.backoff_base * (2 ** (attempt - 1))
            self._log(
                "kubectl_transient_backoff",
                attempt=attempt,
                backoff_s=delay,
            )
            self._sleep(delay)

        raise KubectlRetriesExhausted(
            "transient kubectl exec retries exhausted",
            returncode=last_code,
            classification="transient_exhausted",
        )

    def exec_rails_json(
        self,
        runner: str,
        paths: Sequence[str],
    ) -> dict[str, Any]:
        """``rails runner`` with a static script; paths only on stdin as JSON."""
        payload = json.dumps(list(paths), ensure_ascii=False).encode("utf-8")
        proc = self.exec_argv(
            ["bundle", "exec", "rails", "runner", runner],
            stdin=payload,
        )
        stdout = proc.stdout.decode("utf-8", errors="replace") if proc.stdout else ""
        line = stdout.strip().splitlines()[-1] if stdout.strip() else ""
        if not line:
            raise PermanentKubectlError(
                "rails runner produced empty stdout",
                returncode=proc.returncode,
                classification="permanent",
            )
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError as e:
            raise PermanentKubectlError(
                "rails runner stdout was not JSON",
                returncode=proc.returncode,
                classification="permanent",
            ) from e
        if not isinstance(parsed, dict):
            raise PermanentKubectlError(
                "rails runner JSON was not an object",
                returncode=proc.returncode,
                classification="permanent",
            )
        return parsed

    def exec_rails_payload(
        self,
        runner: str,
        payload: dict[str, Any],
    ) -> dict[str, Any]:
        """``rails runner`` with a static script; arbitrary JSON object on stdin."""
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        proc = self.exec_argv(
            ["bundle", "exec", "rails", "runner", runner],
            stdin=raw,
        )
        stdout = proc.stdout.decode("utf-8", errors="replace") if proc.stdout else ""
        line = stdout.strip().splitlines()[-1] if stdout.strip() else ""
        if not line:
            raise PermanentKubectlError(
                "rails runner produced empty stdout",
                returncode=proc.returncode,
                classification="permanent",
            )
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError as e:
            raise PermanentKubectlError(
                "rails runner stdout was not JSON",
                returncode=proc.returncode,
                classification="permanent",
            ) from e
        if not isinstance(parsed, dict):
            raise PermanentKubectlError(
                "rails runner JSON was not an object",
                returncode=proc.returncode,
                classification="permanent",
            )
        return parsed

    def enqueue_scan(self, paths: Sequence[str]) -> dict[str, Any]:
        """Phase A: ``create_model_from_path_later`` per path. Non-zero is a STOP."""
        return self.exec_rails_json(SCAN_RUNNER, paths)

    def apply_datapackages(self) -> subprocess.CompletedProcess[bytes]:
        """``rake manyfold:apply_datapackages`` — no dump names on the argv."""
        return self.exec_argv(["bundle", "exec", "rake", "manyfold:apply_datapackages"])

    def verify_tagged(self, paths: Sequence[str]) -> list[PathVerifyResult]:
        """Ask Manyfold which paths exist as models with a non-empty tag list.

        Does not look at on-disk ``datapackage.json``.
        """
        parsed = self.exec_rails_json(VERIFY_RUNNER, paths)
        rows = parsed.get("results")
        if not isinstance(rows, list):
            raise PermanentKubectlError(
                "verify runner missing results[]",
                classification="permanent",
            )
        out: list[PathVerifyResult] = []
        for row in rows:
            if not isinstance(row, dict):
                raise PermanentKubectlError(
                    "verify result row is not an object",
                    classification="permanent",
                )
            path = row.get("path")
            status = row.get("status")
            if not isinstance(path, str) or not isinstance(status, str):
                raise PermanentKubectlError(
                    "verify result missing path/status",
                    classification="permanent",
                )
            model_id = row.get("model_id")
            tag_count = row.get("tag_count", 0)
            out.append(
                PathVerifyResult(
                    path=path,
                    status=status,
                    model_id=model_id if isinstance(model_id, int) else None,
                    tag_count=int(tag_count) if isinstance(tag_count, int) else 0,
                )
            )
        return out

    def fetch_library_members_page(
        self,
        *,
        offset: int = 0,
        limit: int = 5000,
    ) -> dict[str, Any]:
        """Read-only mesh archive_entries page (INIT-021/SPEC-006)."""
        return self.exec_rails_payload(
            LIBRARY_MEMBERS_RUNNER,
            {"offset": int(offset), "limit": int(limit)},
        )

    def fetch_library_coverage(self) -> dict[str, Any]:
        """Coverage stats for cross-root recall summary."""
        return self.exec_rails_payload(LIBRARY_COVERAGE_RUNNER, {})
