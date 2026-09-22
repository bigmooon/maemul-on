"""오류 분류.

재시도 가능 여부를 예외 메시지 문자열로 판단하지 않는다. typed error로 관리한다.
근거: harness.md §11.3, §13 / INV-08.

특히 외부 호출의 timeout은 `EXTERNAL_REJECTED`(확정 실패)가 아니라
`EXTERNAL_UNKNOWN`(결과 불명)이다. 자동 재전송하지 않고 사용자에게 확인을 요청한다.
"""

from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, Field


class ErrorCode(StrEnum):
    """API 응답과 로그에 쓰는 오류 분류."""

    VALIDATION_ERROR = "validation_error"
    """사용자가 수정할 수 있는 입력 오류."""

    CONFLICT_ERROR = "conflict_error"
    """동시 수정 또는 재업로드 충돌. 마지막 저장으로 조용히 덮지 않는다."""

    PERMISSION_ERROR = "permission_error"
    """접근 거부. 자원의 존재 여부를 과도하게 노출하지 않는다."""

    EXTERNAL_AUTH_ERROR = "external_auth_error"
    """네이버 재인증·권한 확인이 필요하다."""

    EXTERNAL_REJECTED = "external_rejected"
    """외부 서비스가 확정적으로 거절했다."""

    EXTERNAL_UNKNOWN = "external_unknown"
    """timeout 등 결과 불명. 실패로 단정하거나 자동 재전송하지 않는다."""

    INTERNAL_RETRYABLE = "internal_retryable"
    """안전하게 job 재시도가 가능한 내부 오류."""

    INTERNAL_TERMINAL = "internal_terminal"
    """수동 확인이 필요한 내부 오류."""


#: 자동 재시도가 안전한 오류. 여기 없는 것은 재시도하지 않는다.
RETRYABLE_CODES: frozenset[ErrorCode] = frozenset(
    {
        ErrorCode.INTERNAL_RETRYABLE,
    }
)


def is_retryable(code: ErrorCode) -> bool:
    """자동 재시도가 안전한가.

    EXTERNAL_UNKNOWN은 재시도하지 않는다. 결과가 불명이라 중복을 만들 수 있다.
    사용자에게 '반영 여부 확인 필요'로 안내한다.
    """
    return code in RETRYABLE_CODES


class ErrorResponse(BaseModel):
    """클라이언트가 그대로 표시할 수 있는 오류 응답.

    프런트엔드는 서버의 raw exception을 표시하지 않고 이 세 필드를 사용한다.
    `user_message`에 PII·내부 식별자·스택 트레이스를 넣지 않는다.
    """

    error_code: ErrorCode
    retryable: bool
    user_message: str = Field(description="사용자에게 그대로 보여줄 쉬운 문구")
    trace_id: str | None = Field(default=None, description="문의 시 참조할 코드")


class DomainError(Exception):
    """도메인 계층의 기본 예외. HTTP를 모른다."""

    def __init__(
        self,
        code: ErrorCode,
        user_message: str,
        *,
        trace_id: str | None = None,
    ) -> None:
        super().__init__(user_message)
        self.code = code
        self.user_message = user_message
        self.trace_id = trace_id

    def to_response(self) -> ErrorResponse:
        return ErrorResponse(
            error_code=self.code,
            retryable=is_retryable(self.code),
            user_message=self.user_message,
            trace_id=self.trace_id,
        )
