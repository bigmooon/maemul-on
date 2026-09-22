# 교차 보안 테스트

두 로그인 사용자 A/B가 같은 아파트명·고객명을 가질 때 API·검색·인용·파일·캘린더
어디에서도 교차 접근이 일어나지 않는지 배포 단위를 가로질러 검증한다 (INV-06, INV-11).

API 내부에서 끝나는 owner scope 테스트는 `apps/api/tests/security/`에 둔다.

**현재 비어 있다.** 사용자 모델과 owner-scoped repository가 아직 없다 (TASK-0002).
`make verify`는 이 게이트를 SKIPPED로 출력한다. 스킵은 통과가 아니다.
