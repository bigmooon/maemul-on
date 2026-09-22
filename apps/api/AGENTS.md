# AGENTS.md — apps/api

루트 [`AGENTS.md`](../../AGENTS.md)를 먼저 읽었다고 전제한다. 여기에는 **API 고유 규칙만** 둔다.
근거: [harness.md §6.2, §8.2, §11.2, §11.3, §14.3](../../docs/architecture/harness.md).

## 스택

FastAPI + Python 3.12 + Pydantic. 의존성과 런타임은 **uv**가 관리한다(시스템 python을 쓰지 않는다).
DB 계층(SQLAlchemy·Alembic·PostgreSQL)은 **아직 없다.** `TASK-0002`에서 추가한다.

## 소유권 규칙 (INV-06)

모든 조회·저장은 **현재 인증 세션에서 얻은** `owner_user_id`를 인자로 요구한다.

```python
# 허용
get_contract(session_user_id, contract_id)

# 금지
get_contract(contract_id)                       # 소유자 없음
get_contract(request.body.user_id, contract_id) # 클라이언트가 보낸 ID
```

- repository의 public method에 `owner_user_id` 없는 조회 함수를 **만들지 않는다.**
- 검색은 후보 생성과 최종 fetch **양쪽 모두** owner filter를 적용한다.
- cache key에 owner scope를 포함한다.
- import 파일 경로를 owner/job scope 밖에서 직접 지정할 수 없게 한다.
- calendar request는 연결 계약의 owner와 session user가 일치해야 한다.
- 관리자 기능이 필요해지면 일반 경로와 **분리된 명시적 인터페이스**를 만든다.

## 날짜 (INV-02)

`date.today()` / `datetime.now()`를 여러 파일에서 직접 호출하지 않는다. `clock.Clock`을 주입받는다.

- 만기 범위는 도메인 함수 한 곳에서 계산한다. API·홈·챗봇·평가가 **같은 함수**를 쓴다.
- 달력 기준 3개월, 양 끝 포함. 월말은 대상 월 말일로 보정(`2026-01-31 + 3개월 = 2026-04-30`).
- `expiry_certainty = confirmed | estimated | missing`을 날짜와 **별도로** 저장한다.
- 테스트는 `FixedClock`을 주입해 CI 날짜와 무관하게 재현한다.

## 오류 (typed error)

재시도 가능 여부를 **예외 메시지 문자열로 판단하지 않는다.** `errors.py`의 typed error를 쓴다.

| code | 의미 |
|---|---|
| `validation_error` | 사용자 수정 가능 |
| `conflict_error` | 동시 수정 또는 재업로드 충돌 |
| `permission_error` | 접근 거부. 존재 여부를 과도하게 노출하지 않는다 |
| `external_auth_error` | 네이버 재인증/권한 확인 필요 |
| `external_rejected` | 확정된 외부 오류 |
| `external_unknown` | timeout 등 **결과 불명**. 자동 재전송 금지 |
| `internal_retryable` | 안전한 내부 job 재시도 가능 |
| `internal_terminal` | 수동 확인 필요 |

응답은 `error_code` / `retryable` / `user_message`를 포함한다. **timeout을 `failed`로 분류하지 않는다** (INV-08 관련).

## 로그 (PII 금지)

| 허용 | 금지 |
|---|---|
| trace_id, 내부 surrogate id/hash | 네이버 access/refresh token |
| endpoint, status, error_code | authorization code, cookie |
| row 수, issue 수, result 수 | Excel 원본, 전체 행 내용 |
| prompt/model/schema version | prompt에 삽입된 상담 원문 |
| latency, token count, 추정 비용 | 전화번호, 고객명, 상담 원문 |
| entity id, changed field **이름** | 변경 전후 PII 전체 값 |

`observability/logging.py`의 금지 필드 상수를 수정할 때는 이 표도 함께 고친다.

## 챗봇·검색 (INV-07)

- LLM이 생성할 수 있는 것은 **allowlist Query DSL**이지 SQL이 아니다.
- `owner_user_id`는 DSL schema에 **존재하지 않는다.** 서버 세션에서만 주입한다.
- schema 밖 필드는 거절한다. filter/sort는 allowlist enum, limit 상한은 서버가 강제한다.
- 날짜 preset은 서버 도메인 함수가 실제 날짜로 바꾼다.
- 파싱 실패 시 **전체 검색으로 넓히지 않는다.** 모호하면 `needs_clarification`으로 돌린다.
- 근거가 없으면 "관련 기록에서 확인할 수 없어요"라고 답한다. 검색 실패를 매물 부재로 단정하지 않는다 (INV-10).

## 외부 adapter

도메인 서비스는 endpoint·header·iCalendar encoding을 모른다. 네이버 전용 세부사항은 `adapters/` 안에만 둔다.
**환경 이름으로 보안 규칙을 끄지 않는다.** `APP_ENV`에 따라 달라지는 것은 adapter와 endpoint뿐이다.

## 패키지 책임

| 경로 | 책임 |
|---|---|
| `api/` | HTTP route, 요청/응답 schema |
| `auth/` | 네이버 OAuth, 세션, 현재 사용자 확인 |
| `domain/` | 만기·금액·상태 전이 등 순수 도메인 규칙 |
| `imports/` | Excel 파싱, mapping, preview, commit |
| `search/` | Query DSL compiler, FTS 상담 검색 |
| `chat/` | 질문 라우팅, 근거 조합 |
| `calendar/` | 캘린더 요청 상태 기계 |
| `jobs/` | 비동기 작업 큐와 worker |
| `adapters/` | 네이버·LLM 외부 호출 격리 |
| `observability/` | 구조화 로그, trace context |

## 테스트 층

| 경로 | 대상 | 외부 의존성 |
|---|---|---|
| `tests/unit/` | 날짜, 금액, 상태 전이, QueryPlan compiler, iCalendar builder | 없음 |
| `tests/repository/` | owner filter, transaction, revision, FTS | 테스트 PostgreSQL (TASK-0002) |
| `tests/contract/` | OpenAPI, adapter request/response | fake server |
| `tests/security/` | IDOR, 교차 검색·인용·파일·캘린더 | 두 사용자 fixture |

## 명령

```bash
uv run pytest -m unit         # 단위
uv run pytest -m contract     # 계약
uv run pytest -m security     # 보안
uv run ruff check .           # lint
uv run mypy src               # 타입
uv run uvicorn maemul_on.main:app --reload --app-dir src
```
