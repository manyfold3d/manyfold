from __future__ import annotations

import base64
import json
import re
import time
import urllib.error
import urllib.request
from typing import Any

from .config import SparkConfig


class HttpError(RuntimeError):
    pass


def _post_json(url: str, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        raise HttpError(f"HTTP {e.code} {url}: {err[:500]}") from e
    except urllib.error.URLError as e:
        raise HttpError(f"URL error {url}: {e}") from e


def _post_multipart_file(
    url: str,
    field_name: str,
    filename: str,
    file_bytes: bytes,
    content_type: str,
    timeout: float,
) -> dict[str, Any]:
    boundary = "----SparkCurateBoundary7MA4YWxkTrZu0gW"
    lines = [
        f"--{boundary}".encode(),
        f'Content-Disposition: form-data; name="{field_name}"; filename="{filename}"'.encode(),
        f"Content-Type: {content_type}".encode(),
        b"",
        file_bytes,
        f"--{boundary}--".encode(),
        b"",
    ]
    body = b"\r\n".join(lines)
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        raise HttpError(f"HTTP {e.code} {url}: {err[:500]}") from e
    except urllib.error.URLError as e:
        raise HttpError(f"URL error {url}: {e}") from e


def chat_completions(
    base_url: str,
    model: str,
    messages: list[dict[str, Any]],
    *,
    temperature: float,
    max_tokens: int,
    timeout: float,
) -> str:
    url = base_url.rstrip("/") + "/chat/completions"
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    out = _post_json(url, payload, timeout)
    try:
        msg = out["choices"][0]["message"]
    except (KeyError, IndexError, TypeError) as e:
        raise HttpError(f"Unexpected chat response: {str(out)[:400]}") from e
    content = msg.get("content")
    if content is None:
        # Some thinking models put text in reasoning first if max_tokens too low
        content = msg.get("reasoning") or msg.get("reasoning_content") or ""
    if isinstance(content, list):
        # multimodal content parts
        parts = []
        for p in content:
            if isinstance(p, dict) and p.get("type") == "text":
                parts.append(p.get("text") or "")
            elif isinstance(p, str):
                parts.append(p)
        content = "\n".join(parts)
    return str(content or "").strip()


def gemma_vision(
    cfg: SparkConfig,
    prompt: str,
    image_jpeg: bytes | list[bytes],
) -> str:
    """Vision chat with one or more JPEG images."""
    images = image_jpeg if isinstance(image_jpeg, list) else [image_jpeg]
    content: list[dict[str, Any]] = [{"type": "text", "text": prompt}]
    for jpeg in images:
        b64 = base64.b64encode(jpeg).decode("ascii")
        content.append(
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}
        )
    messages = [{"role": "user", "content": content}]
    return chat_completions(
        cfg.gemma_url,
        cfg.gemma_model,
        messages,
        temperature=cfg.temperature,
        max_tokens=cfg.max_tokens_vision,
        timeout=cfg.vision_timeout,
    )


def curator_json(cfg: SparkConfig, system: str, user: str) -> str:
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]
    return chat_completions(
        cfg.curator_url,
        cfg.curator_model,
        messages,
        temperature=0.0,
        max_tokens=cfg.max_tokens_curator,
        timeout=cfg.curator_timeout,
    )


def curator_chat(
    base_url: str,
    model: str,
    system: str,
    user: str,
    *,
    max_tokens: int,
    timeout: float,
    retries: int = 2,
    backoff: float = 1.5,
    sleep: Any = None,
) -> str:
    """Curator call with bounded retry-with-backoff (INIT-021/SPEC-005).

    Deterministic sampling (temperature 0) so reruns are stable and diffable.
    The endpoint and model are resolved by the caller — this function never
    supplies a default for either.
    """
    if not base_url or not model:
        raise HttpError("curator base_url and model are required")
    napper = sleep if sleep is not None else time.sleep
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]
    attempts = max(1, int(retries) + 1)
    last: HttpError | None = None
    for attempt in range(attempts):
        try:
            return chat_completions(
                base_url,
                model,
                messages,
                temperature=0.0,
                max_tokens=max_tokens,
                timeout=timeout,
            )
        except HttpError as e:
            last = e
            if attempt + 1 >= attempts:
                break
            napper(float(backoff) * (2**attempt))
    raise last if last is not None else HttpError("curator call failed")


def nudenet_detect_bytes(cfg: SparkConfig, image_bytes: bytes, filename: str = "preview.jpg") -> dict[str, Any]:
    url = cfg.nudenet_url.rstrip("/") + "/v1/detect"
    return _post_multipart_file(
        url,
        "file",
        filename,
        image_bytes,
        "image/jpeg",
        cfg.nudenet_timeout,
    )


def nudenet_detect_path(cfg: SparkConfig, path: str) -> dict[str, Any]:
    url = cfg.nudenet_url.rstrip("/") + "/v1/detect/path"
    return _post_json(url, {"path": path}, cfg.nudenet_timeout)


def extract_json_object(text: str) -> dict[str, Any]:
    """Best-effort pull of a JSON object from model output."""
    text = text.strip()
    if not text:
        raise ValueError("empty model output")
    # Strip markdown fences
    fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", text, re.I)
    if fence:
        text = fence.group(1).strip()
    try:
        obj = json.loads(text)
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError:
        pass
    # Find first {...}
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        obj = json.loads(text[start : end + 1])
        if isinstance(obj, dict):
            return obj
    raise ValueError(f"could not parse JSON from: {text[:300]}")
