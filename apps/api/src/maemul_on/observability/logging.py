"""구조화 로그와 trace context.

원문을 보지 않고도 운영 상태를 알 수 있어야 한다.
근거: harness.md §11.1, §11.2 / requirements.md §8.7.
"""

from __future__ import annotations

import json
import logging
import sys
from contextvars import ContextVar
from typing import Any

#: 요청 단위 추적 ID. HTTP 요청 → DB audit → job → LLM 호출 → 사용자 오류 코드를 잇는다.
trace_id_var: ContextVar[str | None] = ContextVar("trace_id", default=None)

#: 로그에 절대 넣지 않는 필드 이름.
#: apps/api/AGENTS.md의 로그 허용·금지 표와 함께 갱신한다.
FORBIDDEN_LOG_FIELDS: frozenset[str] = frozenset(
    {
        "access_token",
        "refresh_token",
        "authorization_code",
        "auth_code",
        "client_secret",
        "cookie",
        "phone",
        "phone_number",
        "contact_phone",
        "customer_name",
        "display_name",
        "consultation_body",
        "note_body",
        "raw_row",
        "source_json",
        "prompt",
    }
)

#: 로그에 넣어도 되는 것: trace_id, 내부 surrogate id, endpoint, status, error_code,
#: row/issue/result 수, prompt/model/schema version, latency, token count, 추정 비용,
#: entity id, 변경된 field '이름'.


class ForbiddenLogFieldError(ValueError):
    """금지된 필드를 로그에 넣으려 했다."""


def _reject_forbidden(payload: dict[str, Any]) -> None:
    """금지 필드를 조용히 지우지 않고 오류를 낸다.

    조용히 지우면 호출부가 PII를 넘기고 있다는 사실을 모른 채 지나간다.
    개발·테스트 단계에서 드러나게 한다.
    """
    found = FORBIDDEN_LOG_FIELDS.intersection(payload)
    if found:
        raise ForbiddenLogFieldError(
            f"로그에 넣을 수 없는 필드: {sorted(found)}. "
            "PII·토큰 대신 id·건수·유형을 기록한다 (apps/api/AGENTS.md)."
        )


class JsonFormatter(logging.Formatter):
    """한 줄 JSON 로그."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        trace_id = trace_id_var.get()
        if trace_id:
            payload["trace_id"] = trace_id

        extra = getattr(record, "context", None)
        if isinstance(extra, dict):
            _reject_forbidden(extra)
            payload.update(extra)

        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: int = logging.INFO) -> None:
    """루트 로거를 JSON 포맷으로 설정한다. 여러 번 호출해도 안전하다."""
    root = logging.getLogger()
    root.setLevel(level)

    for existing in root.handlers:
        if isinstance(existing.formatter, JsonFormatter):
            return

    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(JsonFormatter())
    root.handlers = [handler]


def log_event(logger: logging.Logger, message: str, **context: Any) -> None:
    """구조화 컨텍스트와 함께 기록한다. 금지 필드가 있으면 예외를 낸다."""
    _reject_forbidden(context)
    logger.info(message, extra={"context": context})
