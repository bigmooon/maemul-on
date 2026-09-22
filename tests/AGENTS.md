# AGENTS.md — tests

루트 [`AGENTS.md`](../AGENTS.md)를 먼저 읽었다고 전제한다. 여기에는 **교차 검증 고유 규칙만** 둔다.
근거: [harness.md §10, §12.1](../docs/architecture/harness.md).

## 이 디렉터리와 앱 내부 테스트의 차이

| 위치 | 대상 |
|---|---|
| `apps/api/tests/` | API 내부의 unit / repository / contract / security |
| `apps/web/src/**/*.test.tsx` | 웹 컴포넌트·스토어 |
| **`tests/`** (여기) | **앱 경계를 가로지르는 검증** — web↔api 계약, 두 사용자 격리, 브라우저 E2E |

앱 하나로 검증이 끝나면 앱 내부에 둔다. 여기는 여러 배포 단위가 함께 있어야 성립하는 것만 둔다.

## 테스트 층과 외부 의존성

| 층 | 주요 대상 | 외부 의존성 |
|---|---|---|
| Unit | 날짜, 금액, 상태 전이, QueryPlan compiler, iCalendar builder | 없음 |
| Repository | owner filter, transaction, revision, FTS | 테스트 PostgreSQL |
| Contract | OpenAPI, adapter request/response, 생성된 TS 타입 | fake server |
| Security | IDOR, 교차 검색·인용·파일·캘린더 | 두 사용자 fixture |
| Eval | LLM parsing, retrieval, answer grounding | 고정 model 또는 녹화 응답 |
| E2E | 로그인 대역, import preview, 홈, 상담, 챗봇, 캘린더 확인 | local stack + fake external |
| Live smoke | 실제 네이버 test account, 배포 health | **수동/제한 실행** |

실제 네이버 쓰기 smoke는 명시적 테스트 계정으로 **수동 실행**한다. 자동 CI에 넣지 않는다.

## 자동화할 보안 계약 (`security/`)

- 두 사용자 A/B가 **같은 아파트명과 고객명**을 가져도 교차 조회되지 않는다.
- A의 property id를 B가 URL에 넣어도 권한 정책에 맞게 거절된다.
- 검색 후보 생성과 최종 note fetch **양쪽 모두** owner filter가 적용된다.
- cache key에 owner scope가 포함된다.
- import 파일 경로를 owner/job scope 밖에서 지정할 수 없다.
- calendar request의 계약 owner와 session user가 일치한다.
- 응답·로그에 token·전화번호가 없다.

## 금지사항

- **테스트를 삭제하거나 `skip`을 추가해 게이트를 통과시키지 않는다.** 이것은 완료로 인정하지 않는다.
- **통과용 빈 테스트(`assert True`)를 만들지 않는다.** 아직 검증할 수 없으면 테스트를 만들지 말고 `progress.md`와 TASK에 미구현으로 기록한다.
- 날짜에 의존하는 테스트에서 실제 `today()`를 쓰지 않는다. `FixedClock`을 주입한다.
- 실패하는 테스트를 "환경 문제"로 단정하고 넘어가지 않는다. 원인을 기록한다.

## PR 검증 순서

```text
Lint·Type → Unit → DB·Contract → Security → E2E smoke → 영향받은 Eval
```

## 현재 상태

`contract/`, `security/`, `e2e/`는 **아직 비어 있다.** 각 디렉터리의 `README.md`에 담당 TASK가 적혀 있다.
`make verify`에서 해당 게이트는 `SKIPPED`로 출력된다. **스킵은 통과가 아니다.**
