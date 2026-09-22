# AGENTS.md — evals

루트 [`AGENTS.md`](../AGENTS.md)를 먼저 읽었다고 전제한다. 여기에는 **평가 고유 규칙만** 둔다.
근거: [harness.md §9](../docs/architecture/harness.md), [requirements.md §9.2](../docs/product/requirements.md).

## 절대 금지

**실제 고객의 이름·전화번호·상담 원문을 이 디렉터리에 넣지 않는다.**
실제 패턴을 반영한 합성/비식별 fixture만 쓴다. 실제 데이터 검증이 필요하면 접근이 제한된 별도 환경에서 한다.

## 디렉터리

| 경로 | 내용 |
|---|---|
| `datasets/` | `<name>.v<N>.jsonl` 고정 평가셋 |
| `fixtures/workbooks/` | 비식별 Excel 샘플 |
| `fixtures/naver/` | 네이버 응답 녹화본 (비밀 제거) |
| `fixtures/users/` | 두 사용자(A/B) 격리 검증용 |
| `fixtures/clocks/` | 고정 시각 (예: `2026-09-16 Asia/Seoul`) |
| `graders/` | exact_plan, result_set, retrieval, citation, refusal, pii_leak |
| `reports/` | 실행 리포트. 커밋 정책은 ADR로 정한다 |

## 게이트 두 종류를 섞지 않는다

### 즉시 100%여야 하는 결정적 게이트

- 사용자 간 접근 차단 fixture
- 날짜 경계와 월말 계산
- idempotency와 DB unique constraint
- schema 밖 QueryPlan 거절
- 로그·응답의 token/전화번호 금지 fixture
- 캘린더 timeout을 success/failed로 오분류하지 않기

### baseline 측정 후 확정할 모델 게이트

header 매핑 정확도, QueryPlan field accuracy, 검색 Recall@K, 인용 정확도와 올바른 거절, p95 지연과 요청당 비용.

**첫 baseline report에서 값과 실패 사례를 확인한 뒤 ADR로 임계값을 정한다.**
설계 단계에서 근거 없는 90%, 95%를 제품 성과처럼 약속하지 않는다.

## 리포트 metadata (필수)

```yaml
run_id: 2026-09-21T120000Z-query-router-v1
git_sha: ...
dataset: structured_queries.v1
dataset_hash: ...
prompt_id: query_router:v1
model_id: ...
model_params: {...}
schema_version: query-plan:v1
metrics: {...}
latency: {p50_ms: ..., p95_ms: ...}
estimated_cost_krw: ...
failures: [...]
```

**평균 점수만 저장하지 않는다.** case별 예측, 근거 id, 오류 유형을 함께 남겨야 실패 분석 → 변경 → 재평가가 가능하다.

## 함께 봐야 할 실패

1차 지표만 보고하지 않는다. 각 경로의 실패 유형을 반드시 함께 본다.

| 경로 | 1차 지표 | 함께 볼 실패 |
|---|---|---|
| Excel | 필드별 정확도, 자동 처리율 | 누락 미탐지, 잘못된 자동 확정, 셀 메모 누락, 중복 저장 |
| 정형 질문 | QueryPlan accuracy, 결과 집합 P/R | 권한 위반, 경계일 오류, 과도한 확대 검색 |
| 상담 검색 | Recall@K, MRR | 잘못된 note, **다른 사용자 note**, 무근거 부재 단정 |
| 답변 | 인용 정확도, groundedness | 협의→확정 왜곡, 예상→확정 왜곡 |
| 캘린더 | 성공률, 중복률, unknown 복구율 | timeout 후 중복, PII 전송, 계약 저장 롤백 |

## 실행 비용

PR마다 전체 유료 LLM eval을 실행하지 않는다.

- deterministic/recorded eval — 매 PR
- 영향받은 작은 live eval — prompt/model 변경 PR
- 전체 holdout eval — release candidate

## 해석 규칙

- 좋은 모델 점수를 **반복 사용이나 제품 수요의 증거로 쓰지 않는다.**
- 합성 테스트와 실제 사용자 테스트를 구분해 기록한다.
- 측정 전에 개선을 주장하지 않는다.

## 명령

```bash
python evals/run.py --dataset <name>   # 현재는 데이터셋이 없어 안내 후 종료 1
```
