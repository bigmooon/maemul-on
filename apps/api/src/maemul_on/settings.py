"""애플리케이션 설정.

환경 모드는 adapter와 endpoint만 바꾼다.
**환경 이름으로 보안 규칙을 끄지 않는다** (harness.md §14.2).
owner scope 검증, PII 로그 금지, 사용자 확인은 모든 환경에서 동일하게 적용된다.
"""

from __future__ import annotations

from enum import StrEnum
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class AppEnv(StrEnum):
    """실행 환경.

    LOCAL_FAKE:    네이버·LLM을 fake/recorded adapter로 실행. 기본값.
    LOCAL_LIVE_AI: LLM만 실제 호출. 평가·개발용.
    STAGING:       테스트 네이버 계정과 비식별 데이터.
    PRODUCTION:    승인된 앱, 실제 사용자 데이터. 별도 secret과 DB.
    """

    LOCAL_FAKE = "local-fake"
    LOCAL_LIVE_AI = "local-live-ai"
    STAGING = "staging"
    PRODUCTION = "production"


class Settings(BaseSettings):
    """환경 변수로 주입되는 설정. 비밀 값의 기본값을 코드에 두지 않는다."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: AppEnv = AppEnv.LOCAL_FAKE
    app_name: str = "매물온"

    # 시각은 Asia/Seoul로 고정한다. 만기 계산의 기준이다 (INV-02).
    timezone: str = "Asia/Seoul"

    @property
    def uses_fake_external(self) -> bool:
        """외부 호출을 fake adapter로 대체하는 환경인가.

        이것은 **adapter 선택**이지 보안 규칙 완화가 아니다.
        """
        return self.app_env is AppEnv.LOCAL_FAKE


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """프로세스 수명 동안 한 번만 읽는다."""
    return Settings()
