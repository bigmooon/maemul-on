# TASK-xxxx 제목

<!--
사용법
1. 이 파일을 docs/tasks/TASK-xxxx-짧은-설명.md 로 복사한다.
2. 모든 칸을 채운 뒤 구현을 시작한다. 빈 칸을 남긴 채 코딩하지 않는다.
3. 완료 후 '증거'와 '남은 문제'를 실제 실행 결과로 채우고,
   feature-list.json의 status와 progress.md를 갱신한다.
-->

- 상태: `not_started | in_progress | blocked | done`
- 담당 기능: `Fxx`, `Uxx`
- 작성일 / 갱신일:

## 사용자 결과

<!-- 사용자가 무엇을 할 수 있게 되는가? 기술이 아니라 업무로 쓴다.
     나쁜 예: "expiry_window 함수를 만든다"
     좋은 예: "홈에서 3개월 내 만기 매물을 가까운 순서로 확인할 수 있다" -->

## 범위 / 제외 범위

- 포함:
- 제외:

<!-- 제외를 비워두지 않는다. 범위가 번지는 것이 가장 흔한 실패다. -->

## 관련 요구사항·불변식

<!-- docs/product/requirements.md의 절 번호와 INV ID를 적는다.
     연결할 요구사항이 없다면 ADR을 먼저 쓴다. -->

- 요구사항:
- 불변식:
- ADR:

## 변경 가능한 경로

<!-- 여기 없는 경로는 이 작업에서 건드리지 않는다. -->

- `apps/api/...`
- `apps/web/...`

## API·데이터 계약

<!-- 요청 / 응답 / 오류 / 권한.
     owner_user_id는 요청 body나 query에 넣지 않는다. 서버 세션에서만 주입한다. -->

- 요청:
- 응답:
- 오류 (`error_code`, `retryable`, `user_message`):
- 권한:

## 수용 예시

<!-- 최소 3개: 정상 1, 경계 1, 실패 1. 실제 값으로 쓴다. -->

- Given / When / Then:
- Given / When / Then:
- Given / When / Then:

## 검증 명령

<!-- 실제로 실행할 명령만 적는다. -->

- `make test-unit`
- `make verify`

## 증거

<!-- 실행한 테스트 결과, 리포트, 스크린샷의 경로.
     "동작 확인함" 같은 서술은 증거가 아니다. 실행 결과와 diff가 증거다. -->

## 남은 문제

<!-- 통과하지 못한 것, 스킵한 것, 미확정 사항.
     비어 있으면 '없음'이라고 명시한다. 빈 칸으로 두지 않는다. -->

## 완료 점검

- [ ] 요구사항 ID 또는 ADR과 연결됨
- [ ] 입력/응답/오류 schema가 있음
- [ ] 소유권 필터가 서버에 있음
- [ ] 정상·경계·실패 테스트가 있음
- [ ] 로그에 PII가 없음을 확인함
- [ ] UI의 loading / empty / error / success 상태가 있음
- [ ] 관련 평가셋 또는 fixture가 추가됨
- [ ] OpenAPI client 재생성 및 diff 검토
- [ ] `make verify` 통과
- [ ] 측정하지 않은 개선 수치를 쓰지 않음
- [ ] `feature-list.json`과 `progress.md` 갱신
