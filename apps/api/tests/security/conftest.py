"""보안 스위트의 두 사용자 fixture 자리.

현재 이 디렉터리에는 테스트가 없다. 의도한 상태다.

owner-scoped repository와 사용자 모델이 없으면 교차 접근을 검증할 수 없고,
통과용 빈 테스트(`assert True`)는 게이트가 통과한다는 잘못된 신호를 준다.
그래서 `make verify`는 test-security를 SKIPPED로 출력한다. 스킵은 통과가 아니다.

TASK-0002에서 아래를 구현하며 이 파일의 fixture를 채운다:

- user_a / user_b: 같은 아파트명과 같은 고객명을 가진 서로 다른 로그인 사용자
- A의 property id를 B가 URL에 넣어도 권한 정책에 맞게 거절되는지
- 검색 후보 생성과 최종 note fetch 양쪽 모두 owner filter가 걸리는지
- cache key에 owner scope가 포함되는지
- import 파일 경로를 owner/job scope 밖에서 지정할 수 없는지
- calendar request의 계약 owner와 session user가 일치하는지

근거: requirements.md F02 / INV-06, INV-11 / harness.md §12.1.
"""
