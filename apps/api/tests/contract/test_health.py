"""운영 엔드포인트 계약 테스트."""

import pytest
from fastapi.testclient import TestClient

from maemul_on import __version__
from maemul_on.main import create_app
from maemul_on.settings import AppEnv, Settings

pytestmark = pytest.mark.contract


@pytest.fixture
def client() -> TestClient:
    # 설정을 주입해 테스트가 환경 변수나 .env에 의존하지 않게 한다.
    return TestClient(create_app(Settings(app_env=AppEnv.LOCAL_FAKE)))


def test_health_returns_ok(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "version": __version__,
        "app_env": "local-fake",
    }


def test_readyz_returns_ok(client):
    assert client.get("/readyz").status_code == 200


def test_health_does_not_leak_configuration(client):
    """생존 확인 응답에 비밀·내부 구성이 들어가지 않는다."""
    body = client.get("/health").text.lower()

    for forbidden in ("secret", "token", "password", "database_url"):
        assert forbidden not in body


def test_openapi_schema_is_generated(client):
    """생성된 스키마는 packages/api-client의 입력이 된다 (TASK-0002)."""
    schema = client.get("/openapi.json").json()

    assert "/health" in schema["paths"]
    assert schema["info"]["version"] == __version__
