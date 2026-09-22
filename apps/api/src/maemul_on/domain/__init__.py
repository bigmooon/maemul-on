"""순수 도메인 규칙: 만기, 금액, 상태 전이, 관리 등급.

시각은 clock.Clock을 주입받는다. date.today()를 직접 호출하지 않는다 (INV-02).
DB·HTTP·외부 API를 모른다.
"""
