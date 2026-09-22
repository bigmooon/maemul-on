# 매물온 데이터 모델 1차 설계

- 작성일: 2026-09-22
- 상태: **검토 대기 설계안.** 아직 마이그레이션으로 구현되지 않았다.
- 대상 작업: `TASK-0002 Core schema and owner-scoped repositories`
- 우선순위: 이 문서는 기준 문서 4순위(설계)다. [requirements.md](../product/requirements.md)와 충돌하면 requirements.md가 이긴다.

## 0. 이 문서와 harness.md §6.1의 관계

[harness.md §6.1](harness.md)의 엔터티 표는 **요약**이다. 이 문서는 그 표를 컬럼·제약·인덱스 수준으로 확정한 **상세 기준**이다.
같은 내용을 두 곳에 쓰지 않기 위해, 컬럼과 제약이 바뀌면 이 문서만 고친다. §6.1은 엔터티 목록과 분리 이유(`listings` vs `contracts`)만 유지한다.

이 설계는 harness.md의 두 문장을 **바꾼다.** ADR 없이 구현하지 않는다.

| 기존 문서 | 바뀌는 내용 | 근거 |
|---|---|---|
| §6.1 `users`에 `naver_subject` 컬럼 | `user_identities` 테이블로 분리 | 사용자 결정 2026-09-22: 네이버 only이되 추후 확장 가능 |
| §13.3 "연락처는 기본 마스킹하고 사용자가 명시적으로 열 때만" | 기본 전체 표시 | 사용자 결정 2026-09-22: 본인 고객 번호를 매번 열어 보는 것은 나쁜 UI다 |

---

## 1. 이 설계가 따르는 확정 결정

2026-09-22 사용자 결정이다. 각각 ADR로 기록한 뒤 구현한다.

| ID | 결정 | 이유 |
|---|---|---|
| D1 | 로그인은 네이버 only. 단 `users`와 provider 신원을 분리해 확장 가능하게 둔다 | 추후 다른 provider 추가 시 `users` 스키마를 건드리지 않는다 |
| D2 | 자동로그인은 **서버 세션 + 회전 refresh token**. 네이버 토큰과 수명을 분리한다 | 앱 로그아웃과 네이버 연결 해제를 분리하라는 [requirements §4.1](../product/requirements.md), [§6.4](../product/requirements.md) 요구 |
| D3 | **전화번호만** 앱 레벨 암호화. 상담·특이사항 본문은 평문 컬럼 + FTS | 암호화한 컬럼은 FTS 인덱스를 만들 수 없다. F09 상담 근거 검색이 성립해야 한다 |
| D4 | 화면에서 연락처를 기본 마스킹하지 않는다 | 개인용 앱이고, 본인 고객 번호 열람은 정상 업무다 |
| D5 | 캘린더 등록 대상은 **계약 만기** 일정. `event_type`은 열거형으로 두어 확장 여지만 남긴다 | [harness.md §17 Q4](harness.md) 답 |
| D6 | LLM을 자체 호스팅(sLLM)할지는 **지금 정하지 않는다** | 모델 위치는 스키마를 바꾸지 않는다. ADR-0009에서 평가셋으로 비교한다 |

### D3을 보완하는 장치

상담 메모를 평문으로 두는 대신, 개인정보 보호는 저장 암호화가 아닌 **경로 차단**이 담당한다. 스키마는 이를 가능하게만 하고, 강제는 애플리케이션 계층에 있다.

1. LLM에 전달 가능한 컬럼 allowlist에 `contact_points.phone_encrypted`를 넣지 않는다.
2. 상담 본문을 근거로 인용해 모델에 넘길 때 전화번호 패턴을 마스킹한다. 사용자가 메모 본문에 번호를 직접 적을 수 있기 때문이다.
3. 로그·trace에 본문과 번호를 남기지 않는다. (이미 `observability/logging.py`에 차단 장치가 있다)

---

## 2. 공통 규약

| 항목 | 규칙 | 이유 |
|---|---|---|
| PK | `uuid`. 애플리케이션에서 UUIDv7 생성 | 순차성으로 인덱스 지역성을 얻으면서 id로 건수를 추측당하지 않는다 |
| 열거값 | Postgres native enum이 아니라 `text` + `CHECK` | 미확정 항목이 많다. 값 추가·삭제를 일반 마이그레이션으로 처리한다 |
| 금액 | `bigint`, **원 단위 정수** | 부동소수점 금지. 억/만 단위 변환은 표현 계층이 한다 |
| 계약 날짜 | `date` | [requirements §4.3](../product/requirements.md) "계약일은 날짜형으로 저장". Asia/Seoul 해석은 주입된 Clock이 한다 |
| 시각 | `timestamptz` | 저장은 UTC, 해석은 Clock |
| 삭제 | 기본은 `archived_at` / `deleted_at` soft delete | [harness.md §13.3](harness.md) "기본 동작은 보관" |
| 낙관적 잠금 | 사용자가 수정하는 테이블에 `version integer NOT NULL DEFAULT 1` | 상세 화면의 version conflict 검사 |
| 공통 컬럼 | `created_at`, `updated_at` timestamptz NOT NULL | — |
| 명명 | 테이블 복수형 snake_case, 제약은 `ck_`/`uq_`/`ix_`/`fk_` 접두 | — |

암호화 컬럼은 `*_encrypted bytea` + 같은 테이블의 `key_version smallint`를 함께 둔다. 키 교체 시 행 단위로 재암호화할 수 있어야 한다.

---

## 3. 소유권 경계를 DB가 강제한다

INV-06은 "애플리케이션이 owner 필터를 잘 넣는다"는 약속으로는 지켜지지 않는다. **자식 행이 다른 사용자의 부모 행을 가리키는 것 자체가 불가능해야 한다.**

방법은 복합 외래키다. 부모에 `UNIQUE (id, owner_user_id)`를 두고, 자식이 `(parent_id, owner_user_id)`로 참조한다.

```sql
CREATE TABLE properties (
    id            uuid PRIMARY KEY,
    owner_user_id uuid NOT NULL REFERENCES users (id),
    -- ...
    CONSTRAINT uq_properties_id_owner UNIQUE (id, owner_user_id)
);

CREATE TABLE listings (
    id            uuid PRIMARY KEY,
    owner_user_id uuid NOT NULL,
    property_id   uuid NOT NULL,
    -- ...
    CONSTRAINT fk_listings_property
        FOREIGN KEY (property_id, owner_user_id)
        REFERENCES properties (id, owner_user_id)
);
```

A 사용자의 listing이 B 사용자의 property를 가리키면 **INSERT가 DB에서 거부된다.** 코드 리뷰나 테스트를 통과하지 못해도 데이터는 오염되지 않는다.

이 때문에 모든 소유 테이블이 `owner_user_id`를 직접 갖는다. 정규화 관점에서는 중복이지만, 의도된 중복이다. 만기 조회 인덱스도 join 없이 `owner_user_id`로 시작할 수 있다.

Repository 규칙은 [harness.md §6.2](harness.md)를 그대로 따른다. `owner_user_id` 없는 public 조회 함수를 만들지 않는다.

---

## 4. 테이블

### 4.1 신원·세션·외부 토큰

앱 로그인(`user_sessions`)과 네이버 연동(`oauth_tokens`)을 **다른 테이블로 분리한다.** 이것이 "앱 로그아웃 ≠ 네이버 연결 해제" 요구를 구조로 만든다.

#### `users`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `status` | text NOT NULL | `active / suspended / withdrawn` |
| `display_name` | text NULL | 네이버 프로필의 표시 이름. **병합 키로 쓰지 않는다** |
| `created_at`, `updated_at`, `last_login_at` | timestamptz | |

이메일을 저장하지 않는다. [requirements §8.2](../product/requirements.md)가 이름·이메일만으로 계정 병합을 금지하는데, 병합 유혹을 만드는 컬럼을 두지 않는 편이 확실하다.

#### `user_identities`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid NOT NULL FK → users | |
| `provider` | text NOT NULL | `CHECK (provider IN ('naver'))`. 확장 시 값만 추가 |
| `provider_subject` | text NOT NULL | 네이버가 주는 고유 식별자 |
| `created_at` | timestamptz | |

`UNIQUE (provider, provider_subject)` — 같은 네이버 계정이 두 `users`를 만들지 못한다.

#### `user_sessions` — 자동로그인

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid NOT NULL FK → users ON DELETE CASCADE | |
| `refresh_token_hash` | bytea NOT NULL UNIQUE | SHA-256. **원문은 저장하지 않는다** |
| `parent_session_id` | uuid NULL FK → user_sessions | 회전 사슬. 재사용 탐지용 |
| `issued_at`, `expires_at`, `last_used_at` | timestamptz | |
| `revoked_at` | timestamptz NULL | |
| `revoked_reason` | text NULL | `logout / rotated / reuse_detected / expired / user_withdrawn` |
| `client_family` | text NULL | `chrome/windows` 수준의 분류값만. **UA 원문·IP는 저장하지 않는다** |

동작: 자동로그인 쿠키(httpOnly, Secure, SameSite=Lax)에 refresh token을 담는다. 사용할 때마다 새 행을 만들고 이전 행을 `rotated`로 표시한다. 이미 회전된 토큰이 다시 들어오면 **탈취로 간주하고 해당 사슬 전체를 폐기한다.**

refresh 유효기간은 아직 확정하지 않았다(§7 참조). 잠정 30일을 fixture에만 쓴다.

#### `oauth_login_states`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `state_hash` | bytea PK | state 원문 대신 해시 |
| `created_at`, `expires_at`, `consumed_at` | timestamptz | `consumed_at`으로 1회용 강제 |
| `redirect_path` | text NULL | 내부 경로만. 절대 URL 금지 |

[harness.md §7.4](harness.md) "state는 서버가 생성·저장하고 callback에서 일치 여부를 검사한다".

#### `oauth_tokens`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid NOT NULL FK → users | |
| `provider` | text NOT NULL | |
| `access_token_encrypted` | bytea NOT NULL | |
| `refresh_token_encrypted` | bytea NULL | |
| `key_version` | smallint NOT NULL | |
| `access_expires_at` | timestamptz NULL | |
| `scopes` | text[] NOT NULL DEFAULT `'{}'` | 캘린더 권한 보유 여부를 여기서 판단한다 |
| `status` | text NOT NULL | `active / revoked / expired / needs_reauth` |
| `created_at`, `updated_at`, `last_refreshed_at` | timestamptz | |

`UNIQUE (user_id, provider)`. 복호화는 adapter 호출 직전에만 한다([harness.md §12.2](harness.md)).

### 4.2 매물 원장

#### `apartments`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL FK → users | |
| `canonical_name` | text NOT NULL | |
| `address_raw` | text NULL | 같은 이름 단지를 구분하는 유일한 근거 |
| `aliases` | jsonb NOT NULL DEFAULT `'[]'` | 사용자 지정 별칭 |
| `management_tier` | text NOT NULL DEFAULT `'general'` | `primary / secondary / general` |
| `created_at`, `updated_at`, `archived_at` | timestamptz | |

`UNIQUE (id, owner_user_id)` (복합 FK용).

**이름에 unique 제약을 걸지 않는다.** [harness.md §13.4](harness.md)가 "같은 이름의 다른 단지는 주소/식별 정보가 없으면 자동 병합하지 않는다"고 요구한다. 중복 후보는 애플리케이션이 사용자에게 제시하고 사용자가 확정한다. (INV-05와 같은 원칙)

`management_tier`는 **관리 뱃지이지 권한이 아니다.** 어떤 조회에서도 이 값으로 행을 숨기지 않는다. (INV-01, INV-13)

#### `properties`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL FK → users | |
| `apartment_id` | uuid NULL | **nullable.** 아파트가 아닌 매물을 허용한다 |
| `address_line` | text NULL | `apartment_id`가 없을 때의 위치 |
| `building` | text NULL | 동. 원문 그대로 |
| `unit` | text NULL | 호. 원문 그대로 |
| `unit_type_raw` | text NULL | `32평`, `84A` 등 원문 |
| `unit_type_normalized` | text NULL | 정규화 실패 시 NULL |
| `area_m2` | numeric(8,2) NULL | |
| `source_type` | text NOT NULL | `excel_import / manual` |
| `status` | text NOT NULL DEFAULT `'active'` | `active / archived` |
| `version` | integer NOT NULL DEFAULT 1 | |
| `created_at`, `updated_at`, `archived_at` | timestamptz | |

제약:
- `UNIQUE (id, owner_user_id)`
- `FOREIGN KEY (apartment_id, owner_user_id) REFERENCES apartments (id, owner_user_id)`
- `CHECK (apartment_id IS NOT NULL OR address_line IS NOT NULL)` — 위치를 식별할 최소값

동·호·타입을 `text`로 두는 이유는 INV-12다. `101`과 `101동`, `가동`을 정수로 강제하면 원문이 사라진다.

#### `listings` — 내놓은 조건

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `property_id` | uuid NOT NULL | 복합 FK |
| `deal_type` | text NOT NULL | `sale / jeonse / monthly` |
| `sale_price_krw` | bigint NULL | |
| `deposit_krw` | bigint NULL | |
| `monthly_rent_krw` | bigint NULL | |
| `amount_raw` | text NULL | Excel 셀 원문. `3/50`, `2억5천` 등 |
| `parse_status` | text NOT NULL | `parsed / ambiguous / unparsed` |
| `status` | text NOT NULL DEFAULT `'active'` | `active / closed` |
| `version`, `created_at`, `updated_at` | | |

```sql
CONSTRAINT ck_listings_amount_required CHECK (
    parse_status <> 'parsed'
    OR (deal_type = 'sale'    AND sale_price_krw IS NOT NULL)
    OR (deal_type = 'jeonse'  AND deposit_krw    IS NOT NULL)
    OR (deal_type = 'monthly' AND deposit_krw    IS NOT NULL AND monthly_rent_krw IS NOT NULL)
)
```

금액을 무조건 NOT NULL로 하지 않는 이유는 INV-12다. 불확실한 Excel 값을 자동 확정하는 대신 `unparsed`로 저장하고 `amount_raw`를 보존한다. 확정된 행에만 금액을 강제한다.

#### `contracts` — 현재 임대차

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `property_id` | uuid NOT NULL | 복합 FK |
| `contract_type` | text NOT NULL | `jeonse / monthly / owner_occupied / unknown` |
| `deposit_krw`, `monthly_rent_krw` | bigint NULL | |
| `start_date` | date NULL | |
| `expiry_date` | date NULL | **nullable** |
| `expiry_certainty` | text NOT NULL | `confirmed / estimated / missing` |
| `status` | text NOT NULL DEFAULT `'active'` | `active / ended / superseded` |
| `source_type` | text NOT NULL | `excel_import / manual` |
| `version` | integer NOT NULL DEFAULT 1 | |
| `created_at`, `updated_at` | | |

```sql
CONSTRAINT ck_contracts_expiry_certainty CHECK (
    (expiry_certainty = 'missing'                  AND expiry_date IS NULL)
 OR (expiry_certainty IN ('confirmed','estimated') AND expiry_date IS NOT NULL)
)
```

**이 CHECK 하나가 INV-04의 절반을 담당한다.** 만기일이 없는데 `confirmed`인 행, 만기일이 있는데 `missing`인 행이 DB에 들어갈 수 없다. 나머지 절반(화면·답변에서 예상값을 확정처럼 쓰지 않기)은 표현 계층이 담당한다.

`listings`와 분리한 이유는 [harness.md:344](harness.md)에 있다. 매매 매물의 특이사항에 현재 전세금이 적힌 사례 때문이다.

#### `contract_revisions`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `contract_id` | uuid NOT NULL | 복합 FK |
| `revision_no` | integer NOT NULL | |
| `snapshot` | jsonb NOT NULL | **변경 직전** 값 전체 |
| `changed_fields` | text[] NOT NULL | 필드명만 |
| `changed_by` | uuid NOT NULL FK → users | |
| `changed_at` | timestamptz NOT NULL | |
| `reason` | text NULL | `renewal / correction / import_merge` |

`UNIQUE (contract_id, revision_no)`. 계약 갱신이 기존 행을 덮어쓰지 않게 한다([harness.md §6.3](harness.md), F07).

### 4.3 고객·관계자

#### `customers`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL FK → users | |
| `display_name` | text NOT NULL | |
| `merged_into_id` | uuid NULL | 사용자가 **명시적으로** 병합했을 때만 채운다 |
| `created_at`, `updated_at` | | |

`UNIQUE (id, owner_user_id)`. **이름에 unique 제약이 없다.** INV-05가 이름만으로 자동 병합을 금지한다. 동명이인이 각각 다른 행으로 존재하는 것이 정상이다.

#### `contact_points`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `customer_id` | uuid NOT NULL | 복합 FK |
| `phone_encrypted` | bytea NOT NULL | AES-GCM |
| `phone_fingerprint` | bytea NOT NULL | 정규화 번호의 HMAC-SHA256. **암호화 키와 다른 키를 쓴다** |
| `key_version` | smallint NOT NULL | |
| `label` | text NULL | `딸`, `아들`, `배우자`, `대리인` 등 **원문 보존** |
| `is_primary` | boolean NOT NULL DEFAULT false | |
| `source_ref` | jsonb NULL | Excel 출처. 일반 화면에 노출하지 않는다 |
| `created_at`, `updated_at` | | |

`UNIQUE (owner_user_id, customer_id, phone_fingerprint)` — 같은 사람에게 같은 번호가 중복 저장되지 않는다.

`phone_fingerprint`가 필요한 이유: 암호화한 값은 같은 번호라도 매번 다른 바이트가 되므로 중복 검사가 불가능하다. 결정적 HMAC을 따로 두면 **번호를 복호화하지 않고** 중복을 찾을 수 있다.

한 셀에 여러 번호가 있으면 각각 별도 행으로 저장한다([harness.md §6.1](harness.md)).

#### `contract_parties`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `contract_id` | uuid NOT NULL | 복합 FK |
| `customer_id` | uuid NOT NULL | 복합 FK |
| `role` | text NOT NULL | `lessor / lessee / owner_of_record / agent` |
| `relationship_note` | text NULL | `임차인의 딸` 같은 가족 관계 원문 |
| `created_at` | timestamptz | |

`UNIQUE (contract_id, customer_id, role)`.

상담과 연락 기록이 `contracts`가 아니라 **이 테이블**에 붙는다. 같은 고객이 여러 계약의 당사자일 때, 한 계약의 연락 결과가 다른 계약의 상태를 바꾸면 안 되기 때문이다(F06).

### 4.4 상담·연락 — TASK-0010

#### `consultation_notes`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `contract_party_id` | uuid NOT NULL | 복합 FK |
| `body` | text NOT NULL | **평문** (D3) |
| `search_tsv` | tsvector GENERATED ALWAYS AS ... STORED | FTS |
| `occurred_at` | timestamptz NOT NULL | 실제 상담 시각 |
| `created_by` | uuid NOT NULL FK → users | |
| `created_at`, `updated_at`, `deleted_at` | | soft delete |

#### `contact_events`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `contract_party_id` | uuid NOT NULL | 복합 FK |
| `outcome` | text NOT NULL | 잠정: `attempted / reached / consulted / follow_up_needed` |
| `occurred_at` | timestamptz NOT NULL | |
| `note_id` | uuid NULL | 복합 FK → consultation_notes |
| `created_at` | timestamptz | |

`연락 전`은 **이벤트가 없는 상태**로 표현한다. 별도 값을 만들지 않는다.
이 행이 생겨도 만기 목록에서 계약을 제거하지 않는다(INV-03). 만기 조회는 `contact_events`를 보지 않는다.

### 4.5 Excel 등록 — TASK-0004 / TASK-0005

`import_jobs`, `import_rows`, `source_annotations`, `property_notes`는 [harness.md §6.1](harness.md)과 [§7.1](harness.md)의 정의를 따른다. 이 문서에서는 다음만 확정한다.

- `import_jobs`에 `UNIQUE (owner_user_id, file_hash, parser_version)` — INV-09(재시도·중복 클릭이 중복 원장을 만들지 않음)를 DB가 강제한다.
- `import_rows.source_json_encrypted`는 암호화한다. 검색 대상이 아니고 Excel 원본 전체를 담기 때문이다.
- `property_notes.body`는 평문이다. 특이사항이 F09 검색 대상이기 때문이다(D3와 동일 근거).

### 4.6 네이버 캘린더 — TASK-0009

#### `calendar_requests`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `owner_user_id` | uuid NOT NULL | |
| `contract_id` | uuid NOT NULL | 복합 FK. 계약 owner와 세션 user가 다르면 INSERT 불가 |
| `event_type` | text NOT NULL | 현재 `contract_expiry`만. D5 |
| `request_version` | integer NOT NULL | 계약 날짜가 바뀌면 증가 |
| `ical_uid` | uuid NOT NULL UNIQUE | **무작위 UUID.** 토큰·전화번호·고객명에서 생성하지 않는다 |
| `status` | text NOT NULL | `draft / sending / succeeded / failed / unknown / needs_review / stale` |
| `external_ref` | text NULL | 네이버가 돌려준 식별자 |
| `error_code` | text NULL | 오류 분류값만. 응답 본문 원문을 넣지 않는다 |
| `created_at`, `updated_at`, `sent_at` | | |

`UNIQUE (owner_user_id, contract_id, event_type, request_version)` — 중복 클릭과 동시 요청을 DB가 막는다([requirements §6.4](../product/requirements.md)).

`unknown`은 `failed`와 **다른 값이다.** timeout은 등록됐는지 모르는 상태이지 실패가 아니다. 자동 재전송하지 않는다(INV-08, ADR-0006).

이 테이블의 어떤 실패도 `contracts` / `consultation_notes` 저장 트랜잭션에 참여하지 않는다. 캘린더 전송은 항상 별도 트랜잭션이다(INV-08).

### 4.7 `audit_events`

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | uuid PK | |
| `actor_user_id` | uuid NOT NULL FK → users | |
| `action` | text NOT NULL | `contract.updated`, `phone.viewed` 등 |
| `entity_type`, `entity_id` | text / uuid | |
| `changed_fields` | text[] NULL | **필드명만.** 값은 넣지 않는다 |
| `trace_id` | text NULL | |
| `occurred_at` | timestamptz NOT NULL | |

원문·토큰·전화번호를 기록하지 않는다. `contract_revisions`가 값의 이력을 담당하고, 이 테이블은 행위의 이력만 담당한다.

---

## 5. 인덱스

만기 홈이 제품의 중심이므로 그 쿼리를 먼저 최적화한다.

```sql
-- 만기 목록: owner + 만기일 범위. status 필터를 부분 인덱스로 흡수한다.
CREATE INDEX ix_contracts_owner_expiry
    ON contracts (owner_user_id, expiry_date)
    WHERE status = 'active' AND expiry_date IS NOT NULL;

-- '만기일 확인 필요' 별도 진입점 (INV-04)
CREATE INDEX ix_contracts_owner_missing_expiry
    ON contracts (owner_user_id)
    WHERE status = 'active' AND expiry_date IS NULL;

-- 내 매물 목록
CREATE INDEX ix_properties_owner_apartment
    ON properties (owner_user_id, apartment_id)
    WHERE status = 'active';

-- 상담 FTS
CREATE INDEX ix_consultation_notes_tsv
    ON consultation_notes USING GIN (search_tsv);

-- 세션 정리
CREATE INDEX ix_user_sessions_user_active
    ON user_sessions (user_id)
    WHERE revoked_at IS NULL;
```

모든 조회 인덱스가 `owner_user_id`로 시작한다. owner 필터를 빠뜨린 쿼리는 인덱스를 못 타서 느려지므로, **성능 문제로도 드러난다.**

---

## 6. 마이그레이션 분할

| 버전 | 내용 | 작업 |
|---|---|---|
| `0001_identity` | users, user_identities, user_sessions, oauth_login_states, oauth_tokens | TASK-0002 |
| `0002_property_ledger` | apartments, properties, listings, contracts, contract_revisions, customers, contact_points, contract_parties, audit_events | TASK-0002 |
| `0003_import` | import_jobs, import_rows, source_annotations, property_notes | TASK-0004 |
| `0004_consultation` | consultation_notes, contact_events | TASK-0010 |
| `0005_calendar` | calendar_requests | TASK-0009 |

TASK-0002의 완료 조건은 `0001`, `0002`가 적용되고 `test-db`·`test-security`·`check-migrations` 스킵 3개가 해제되는 것이다.

---

## 7. 아직 정하지 않은 것

값을 채워야 구현이 되는 항목이다. **fixture에만 잠정값을 쓰고, 확정 요구처럼 문서화하지 않는다.**

| 항목 | 잠정값 | 확정 조건 |
|---|---|---|
| refresh token 유효기간 | 30일 | 사용자 결정 |
| `contact_events.outcome` 값 집합 | `attempted / reached / consulted / follow_up_needed` | 실제 업무 관찰 ([harness.md §17 Q3](harness.md)) |
| 한국어 FTS 설정 | `to_tsvector('simple', ...)` | Postgres 기본 설정에는 한국어 형태소 분석기가 없다. `pg_bigm` / `pgroonga` 도입 여부는 TASK-0012 스파이크에서 실제 상담 문장으로 비교한다 |
| 캘린더 일정의 시간 지정 여부 | 미정 | [§17 Q5](harness.md). 검증 전 임의 시간을 부여하지 않는다 |
| 각 테이블 보관 기간 | 미정 | [harness.md §12.3](harness.md) 삭제 매트릭스, ADR-0010 |
| 암호화 키 보관 위치 | `.env` 단일 키 + `key_version` | 배포 환경 확정 시 재검토 |

---

## 8. 불변식 대응

이 설계가 각 불변식을 **어디서** 지키는지다. 스키마로 막을 수 없는 것은 그렇다고 적는다.

| INV | 이 설계의 담당 |
|---|---|
| INV-01 | `management_tier`를 조회 조건에서 제외. 스키마상 숨김 장치가 없다 |
| INV-02 | 스키마 밖. `expiry_date`는 `date`로만 두고 계산은 도메인 함수(TASK-0003) |
| INV-03 | `contact_events`가 `contracts.status`를 바꾸지 않는다. 만기 인덱스가 `contact_events`를 참조하지 않는다 |
| INV-04 | `ck_contracts_expiry_certainty` |
| INV-05 | `customers.display_name`에 unique 제약 없음, `merged_into_id`는 명시적 병합 전용 |
| INV-06 | **복합 외래키 (§3)** + owner-scoped repository |
| INV-07 | 스키마 밖. Query DSL 컴파일러(TASK-0011) |
| INV-08 | `calendar_requests`가 별도 트랜잭션. `unknown` 상태 분리 |
| INV-09 | `uq_import_jobs_owner_filehash_parser` |
| INV-10 | 스키마 밖. 답변 생성 계층 |
| INV-11 | 공개 URL을 만들 컬럼이 없다. 모든 조회가 `owner_user_id`를 요구한다 |
| INV-12 | `amount_raw`, `unit_type_raw`, `parse_status`, `source_annotations` |
| INV-13 | `management_tier`가 어떤 FK·권한 조건에도 쓰이지 않는다 |
| INV-14 | `source_type`만 다르고 같은 테이블·같은 CHECK를 쓴다 |

---

## 9. 다음 단계

1. 이 문서 검토·확정
2. ADR 4건 작성 — ADR-0001(원장), ADR-0002(owner 경계·복합 FK), **ADR-0011(신원·세션 구조, 신규)**, **ADR-0012(저장 암호화 범위와 마스킹 폐기, 신규)**
3. [harness.md §6.1, §13.3](harness.md) 갱신 + [deprecated.md](../product/deprecated.md)에 마스킹 규칙 폐기 기록
4. [feature-list.json](../../feature-list.json)의 `adrs_planned`에 ADR-0011·0012 추가
5. `docs/tasks/TASK-0002.md` 작성
6. docker-compose PostgreSQL + Alembic 초기화 → 마이그레이션 `0001`, `0002`
