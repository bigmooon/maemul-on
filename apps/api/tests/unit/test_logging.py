"""로그 PII 차단 테스트.

전화번호·상담 원문·토큰이 로그로 새지 않는지 확인한다 (harness.md §11.2).
금지 필드를 조용히 지우지 않고 예외를 내는 것이 의도다.
"""

import logging

import pytest

from maemul_on.observability.logging import (
    FORBIDDEN_LOG_FIELDS,
    ForbiddenLogFieldError,
    JsonFormatter,
    log_event,
    trace_id_var,
)

pytestmark = pytest.mark.unit


def test_allowed_context_is_logged(caplog):
    logger = logging.getLogger("test.allowed")
    with caplog.at_level(logging.INFO):
        log_event(logger, "import finished", job_id="j-1", row_count=123, latency_ms=42)

    assert "import finished" in caplog.text


@pytest.mark.parametrize("field", ["access_token", "phone", "consultation_body", "prompt"])
def test_forbidden_fields_raise(field):
    logger = logging.getLogger("test.forbidden")
    with pytest.raises(ForbiddenLogFieldError):
        log_event(logger, "should not log", **{field: "x"})


def test_forbidden_list_covers_tokens_and_pii():
    """목록이 축소되면 이 테스트가 먼저 깨진다."""
    for required in ("access_token", "refresh_token", "client_secret", "phone", "customer_name"):
        assert required in FORBIDDEN_LOG_FIELDS


def test_formatter_includes_trace_id():
    formatter = JsonFormatter()
    token = trace_id_var.set("t-abc")
    try:
        record = logging.LogRecord("n", logging.INFO, __file__, 1, "msg", None, None)
        assert '"trace_id": "t-abc"' in formatter.format(record)
    finally:
        trace_id_var.reset(token)


def test_formatter_rejects_forbidden_context():
    formatter = JsonFormatter()
    record = logging.LogRecord("n", logging.INFO, __file__, 1, "msg", None, None)
    record.context = {"phone": "숨겨야 하는 값"}

    with pytest.raises(ForbiddenLogFieldError):
        formatter.format(record)
