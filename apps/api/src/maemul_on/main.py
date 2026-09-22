"""FastAPI 애플리케이션 조립.

현재는 골격이다. 제품 route는 아직 없다.
route를 추가할 때 apps/api/AGENTS.md의 소유권 규칙을 먼저 읽는다.
"""

from __future__ import annotations

from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel

from maemul_on import __version__
from maemul_on.observability.logging import configure_logging
from maemul_on.settings import Settings, get_settings


class HealthResponse(BaseModel):
    """프로세스가 살아 있는지에 대한 응답.

    PII나 내부 구성 정보를 담지 않는다. 배포 상태 확인용이다.
    """

    status: Literal["ok"]
    version: str
    app_env: str


def create_app(settings: Settings | None = None) -> FastAPI:
    """애플리케이션을 만든다.

    설정을 인자로 받아 테스트가 환경 변수에 의존하지 않게 한다.
    """
    resolved = settings or get_settings()
    configure_logging()

    app = FastAPI(
        title=f"{resolved.app_name} API",
        version=__version__,
        # 공개·공유 URL을 만들지 않는다 (INV-11). 문서 노출 범위는
        # 배포 환경이 정해질 때 ADR로 결정한다.
    )

    @app.get("/health", response_model=HealthResponse, tags=["ops"])
    async def health() -> HealthResponse:
        """프로세스 생존 확인. 의존 서비스를 호출하지 않는다."""
        return HealthResponse(
            status="ok",
            version=__version__,
            app_env=resolved.app_env.value,
        )

    @app.get("/readyz", response_model=HealthResponse, tags=["ops"])
    async def readyz() -> HealthResponse:
        """트래픽을 받을 준비가 됐는지 확인.

        현재는 health와 같다. DB·job queue가 생기면(TASK-0002)
        여기서 실제 의존성을 점검하도록 바꾼다.
        """
        return HealthResponse(
            status="ok",
            version=__version__,
            app_env=resolved.app_env.value,
        )

    return app


app = create_app()
