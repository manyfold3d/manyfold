"""Intake Job bake lint — INIT-021/SPEC-010.

Asserts env is baked at apply time (no kubectl set env), LIBRARY_ROOT is the
batch directory (never /library, /models, or /mnt/backups/3D-Prints), and
defaults are APPLY=0, MERGE_HITL=hitl_all, WORKERS=1.
"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.bake_intake_job import (  # noqa: E402
    BakeError,
    SET_ENV_RE,
    assert_library_root,
    bake_intake_job,
    lint_paths,
)

RUNBOOK = Path(
    "/home/bnelson/k8/home_k3/sdd/initiatives/"
    "INIT-021-intake-unorganize-dedup-admit/design/"
    "INIT-021-ops-runbook-intake-admit.md"
)


def _job() -> dict:
    return {
        "apiVersion": "batch/v1",
        "kind": "Job",
        "metadata": {"name": "tmpl", "namespace": "manyfold"},
        "spec": {
            "template": {
                "spec": {
                    "containers": [
                        {
                            "name": "curate",
                            "env": [
                                {"name": "MODE", "value": "organize"},
                                {"name": "LIBRARY_ROOT", "value": "/library"},
                                {"name": "APPLY", "value": "1"},
                            ],
                            "volumeMounts": [
                                {
                                    "name": "unorg",
                                    "mountPath": "/intake",
                                    "subPath": "intake/placeholder",
                                }
                            ],
                        }
                    ],
                    "volumes": [{"name": "unorg"}],
                }
            }
        },
    }


class LibraryRootFenceTests(unittest.TestCase):
    def test_cluster_intake_mount_is_allowed(self) -> None:
        self.assertEqual(assert_library_root("/intake"), "/intake")

    def test_google_batch_host_path_is_allowed(self) -> None:
        root = "/mnt/backups/3D-Prints-Unorg/intake/2026-08-drive-mega"
        self.assertEqual(assert_library_root(root), root)

    def test_library_pvc_paths_are_refused(self) -> None:
        for bad in ("/library", "/models", "/mnt/backups/3D-Prints"):
            with self.subTest(bad=bad):
                with self.assertRaises(BakeError):
                    assert_library_root(bad)

    def test_library_prefix_without_unorg_is_refused(self) -> None:
        with self.assertRaises(BakeError):
            assert_library_root("/mnt/backups/3D-Prints/Anime")


class BakeEnvTests(unittest.TestCase):
    def test_bakes_fail_secure_defaults(self) -> None:
        job = bake_intake_job(_job(), name="spark-curate-intake-unorg-games")
        env = {e["name"]: e["value"] for e in job["spec"]["template"]["spec"]["containers"][0]["env"]}
        self.assertEqual(env["MODE"], "unorganize")
        self.assertEqual(env["APPLY"], "0")
        self.assertEqual(env["MERGE_HITL"], "hitl_all")
        self.assertEqual(env["LIBRARY_ROOT"], "/intake")
        self.assertEqual(env["WORKERS"], "1")
        self.assertNotIn(env["LIBRARY_ROOT"], {"/library", "/models", "/mnt/backups/3D-Prints"})
        mount = job["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]
        self.assertEqual(mount["subPath"], "intake/2026-08-drive-mega")

    def test_new_job_name_per_env_change(self) -> None:
        a = bake_intake_job(_job(), name="spark-curate-intake-unorg")
        b = bake_intake_job(_job(), name="spark-curate-intake-admit", mode="admit")
        self.assertNotEqual(a["metadata"]["name"], b["metadata"]["name"])
        env_b = {e["name"]: e["value"] for e in b["spec"]["template"]["spec"]["containers"][0]["env"]}
        self.assertEqual(env_b["MODE"], "admit")

    def test_refuse_library_root_on_bake(self) -> None:
        with self.assertRaises(BakeError):
            bake_intake_job(_job(), name="x", library_root="/library")

    def test_invalid_merge_hitl_fails_loud(self) -> None:
        with self.assertRaises(BakeError):
            bake_intake_job(_job(), name="x", merge_hitl="silent_off")


class NoSetEnvLintTests(unittest.TestCase):
    def test_set_env_regex_matches_patch_form(self) -> None:
        self.assertIsNotNone(SET_ENV_RE.search("kubectl set env job/foo MODE=admit"))
        self.assertIsNone(SET_ENV_RE.search("bake env at kubectl apply time"))

    def test_tools_and_runbook_have_no_set_env(self) -> None:
        paths = [
            TOOLS / "bake_intake_job.py",
            TOOLS / "manyfold-intake-admit-job.sh",
            TOOLS / "manyfold-intake-move-admitted.sh",
        ]
        self.assertEqual(len(lint_paths(paths)), 3)
        self.assertTrue(RUNBOOK.is_file(), "runbook missing — ac-2 requires linting it")
        lint_paths([RUNBOOK])

    def test_baked_json_does_not_mention_set_env(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "job.json"
            path.write_text(json.dumps(_job()), encoding="utf-8")
            job = json.loads(path.read_text(encoding="utf-8"))
            bake_intake_job(job, name="spark-curate-intake-unorg", slice_name="Games")
            text = json.dumps(job)
            self.assertNotRegex(text, r"kubectl\s+set\s+env")
            env = {e["name"]: e["value"] for e in job["spec"]["template"]["spec"]["containers"][0]["env"]}
            self.assertEqual(env["SLICE"], "Games")
            self.assertEqual(env["LIBRARY_ROOT"], "/intake")


if __name__ == "__main__":
    unittest.main()
