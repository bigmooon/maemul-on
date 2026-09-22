# E2E 테스트

Playwright로 핵심 흐름을 검증한다: 로그인 대역 → import preview → 홈 만기 →
상세 상담 저장 → 챗봇 → 캘린더 확인. 외부 서비스는 fake adapter를 쓴다.

실제 네이버 쓰기 smoke는 명시적 테스트 계정으로 **수동 실행**한다. CI에 넣지 않는다.

**현재 비어 있다.** 대상 화면이 아직 없다 (TASK-0006).
Playwright는 브라우저 다운로드가 필요하므로 `make verify` 기본 경로에 넣지 않았다.
