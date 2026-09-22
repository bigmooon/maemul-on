"""오류 분류 테스트.

핵심: timeout(EXTERNAL_UNKNOWN)을 재시도 가능으로 분류하지 않는다.
결과가 불명인 요청을 자동 재전송하면 캘린더에 중복 일정이 생긴다 (harness.md §7.5).
"""

import pytest

from maemul_on.errors import (
    DomainError,
    ErrorCode,
    ErrorResponse,
    is_retryable,
)

pytestmark = pytest.mark.unit


def test_only_internal_retryable_is_retryable():
    assert is_retryable(ErrorCode.INTERNAL_RETRYABLE) is True


@pytest.mark.parametrize(
    "code",
    [
        ErrorCode.VALIDATION_ERROR,
        ErrorCode.CONFLICT_ERROR,
        ErrorCode.PERMISSION_ERROR,
        ErrorCode.EXTERNAL_AUTH_ERROR,
        ErrorCode.EXTERNAL_REJECTED,
        ErrorCode.EXTERNAL_UNKNOWN,
        ErrorCode.INTERNAL_TERMINAL,
    ],
)
def test_other_codes_are_not_retryable(code):
    assert is_retryable(code) is False


def test_external_unknown_is_not_treated_as_failure_or_retry():
    """timeout은 '실패'도 '재시도 대상'도 아니다. 사용자 확인이 필요한 상태다."""
    assert ErrorCode.EXTERNAL_UNKNOWN is not ErrorCode.EXTERNAL_REJECTED
    assert is_retryable(ErrorCode.EXTERNAL_UNKNOWN) is False


def test_domain_error_builds_response_with_matching_retryable():
    error = DomainError(
        ErrorCode.EXTERNAL_UNKNOWN,
        "등록 결과를 확인하지 못했어요. 네이버 캘린더에서 확인해 주세요.",
        trace_id="t-123",
    )
    response = error.to_response()

    assert isinstance(response, ErrorResponse)
    assert response.error_code is ErrorCode.EXTERNAL_UNKNOWN
    assert response.retryable is False
    assert response.trace_id == "t-123"


def test_error_codes_are_stable_strings():
    """API 응답과 로그에 쓰이는 값이므로 문자열이 바뀌면 계약이 깨진다."""
    assert ErrorCode.VALIDATION_ERROR == "validation_error"
    assert ErrorCode.EXTERNAL_UNKNOWN == "external_unknown"
    assert ErrorCode.PERMISSION_ERROR == "permission_error"
