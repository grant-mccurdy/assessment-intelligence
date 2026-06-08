"""Shared OpenAI helpers for public-safe reporting scripts."""

from __future__ import annotations

import json
import os
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


RESPONSES_URL = "https://api.openai.com/v1/responses"
DEFAULT_OPENAI_MODEL = "gpt-4.1"
ALLOWED_ENV_KEYS = {"OPENAI_API_KEY", "OPENAI_MODEL"}
SECRET_MARKERS = (
    "Bearer ",
    "OPENAI_API_KEY",
    "SUPABASE_ACCESS_TOKEN",
    "SUPABASE_API_KEY",
    "SUPABASE_DB_URL",
    "PROJECT1_SUPABASE_DB_URL",
    "PROJECT1_SUPABASE_PUBLISHABLE_KEY",
    "postgres://",
    "postgresql://",
    "sk-",
)
PRIVATE_PATH_PATTERN = re.compile(r"/home/[^\s`'\"]+")


@dataclass(frozen=True)
class OpenAIConfig:
    api_key: str
    model: str


def parse_env_file(path: Path | None) -> dict[str, str]:
    """Load only allowlisted OpenAI variables from a local env file."""
    if path is None or not path.exists():
        return {}

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("export "):
            line = line[len("export "):].strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key not in ALLOWED_ENV_KEYS:
            continue
        values[key] = value.strip().strip('"').strip("'")
    return values


def load_openai_config(
    env_file: Path | None = None,
    model: str | None = None,
    default_model: str = DEFAULT_OPENAI_MODEL,
) -> OpenAIConfig:
    env_values = parse_env_file(env_file)
    api_key = os.environ.get("OPENAI_API_KEY") or env_values.get("OPENAI_API_KEY")
    if not api_key:
        raise SystemExit("Missing OpenAI API key. Set it in the environment or pass --env-file.")

    selected_model = model or os.environ.get("OPENAI_MODEL") or env_values.get("OPENAI_MODEL") or default_model
    return OpenAIConfig(api_key=api_key, model=selected_model)


def assert_public_safe_text(text: str, context: str) -> None:
    for marker in SECRET_MARKERS:
        if marker in text:
            raise SystemExit(f"Refusing to use {context}: it appears to contain a secret marker.")
    if PRIVATE_PATH_PATTERN.search(text):
        raise SystemExit(f"Refusing to use {context}: it appears to contain a private local path.")


def extract_output_text(response_obj: dict[str, Any]) -> str:
    if isinstance(response_obj.get("output_text"), str):
        return response_obj["output_text"].strip()

    parts: list[str] = []
    for item in response_obj.get("output", []):
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            content_type = content.get("type")
            if content_type in {"output_text", "text"}:
                parts.append(content.get("text", ""))
    return "".join(parts).strip()


def call_openai_response(
    *,
    api_key: str,
    model: str,
    system_prompt: str,
    user_prompt: str,
    text_format: dict[str, Any] | None = None,
    max_output_tokens: int | None = None,
    timeout: int = 120,
) -> str:
    assert_public_safe_text(system_prompt, "system prompt")
    assert_public_safe_text(user_prompt, "user prompt")

    payload: dict[str, Any] = {
        "model": model,
        "store": False,
        "input": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    if text_format is not None:
        payload["text"] = {"format": text_format}
    if max_output_tokens is not None:
        payload["max_output_tokens"] = max_output_tokens

    req = urllib.request.Request(
        RESPONSES_URL,
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
    )
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            response_obj = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise RuntimeError(
            f"OpenAI API returned HTTP {exc.code}. Check the model, quota, and request schema."
        ) from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"OpenAI API request failed: {exc.reason}") from exc

    text = extract_output_text(response_obj)
    if not text:
        raise RuntimeError("OpenAI response did not include output text.")
    return text
