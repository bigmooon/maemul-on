# 폐기된 요구·결정 기록

- 최종 갱신: 2026-09-21
- 목적: 과거 문서·메모·데모에 남아 있는 내용 중 [requirements.md](requirements.md)와 충돌하는 것을 명시적으로 무효화한다.
- 이 파일은 "무엇이 더 이상 유효하지 않은가"만 기록한다. 현재 유효한 요구는 requirements.md에만 쓴다.

## 기준 문서 우선순위

충돌 시 위가 이긴다. 원본: [harness.md §2](../architecture/harness.md), [requirements.md 머리말](requirements.md).

1. 사용자의 최신 명시적 결정
2. `docs/product/requirements.md` (v0.4)
3. 승인된 ADR (`docs/decisions/`)
4. `docs/architecture/harness.md` (v0.1)
5. 프로젝트 공유 메모
6. 기존 화면 데모
7. 구현 편의 또는 AI 도구의 제안

## 폐기 항목

| # | 폐기 항목 | 출처 | 대체 기준 |
|---|---|---|---|
| D-01 | 사무소 테넌트·사무소 생성/선택·직원 초대 | v0.2 이전 명세 | [requirements.md §1, §3.2](requirements.md) — 자료 경계는 로그인 사용자 단위. 사무소 테이블·사무소 ID를 필수 원장이나 검색 필터로 요구하지 않는다. |
| D-02 | 캘린더 연동 일괄 후순위 | 기존 명세 | [requirements.md §1, F10](requirements.md) — 네이버 캘린더 API 연동은 **필수**다. |
| D-03 | 고정 90일 만기 계산 | 기존 구현 관행 | [requirements.md §4.3](requirements.md) — 오늘부터 **달력 기준 3개월**, 양 끝 포함, 월말은 대상 월 말일로 보정. |
| D-04 | 매물 분류를 사무소별로 나누는 설계 | v0.2 이전 명세 | [requirements.md §3.1](requirements.md) — 분류는 사용자별 `중점 / 서브 / 일반` 관리 등급이며 권한 경계가 아니다. |
| D-05 | 제품명 `계약비서` / 패키지 `contract-secretary` | [harness.md §0, §5](../architecture/harness.md) | **매물온 / `maemul_on`** (2026-09-21 사용자 결정). Python 패키지 `maemul_on`, npm scope `@maemul-on/*`. |
| D-06 | `매물온_프로젝트_공유메모.md`의 내용 | 저장소에 파일 없음 | 우선순위 5위. requirements.md와 충돌하는 내용은 **무효**다. 메모만 근거로 요구를 되살리지 않는다. |
| D-07 | 화면 데모 `매물온_화면데모_v0.3.html`, `work/demo/property-management-demo.html` | [harness.md §13.1](../architecture/harness.md) | **시각 참고 자료일 뿐이다.** API·데이터 계약의 근거로 사용하지 않는다. 데모에 있는 기능을 구현된 것으로 설명하지 않는다. |

## 폐기하지 않은 것 (오해 방지)

축소 논의에서 임의로 빼지 않는다. 원본: [requirements.md §10](requirements.md).

- 네이버 로그인
- 최소 캘린더 등록
- 중점 / 서브 / 일반 분류
- 3개월 내 만기 업무
- 지속 저장
- 챗봇 (읽기 전용)

## 갱신 규칙

- 요구가 바뀌면 requirements.md를 먼저 고치고, 여기에 폐기 항목을 한 줄 추가한다.
- 구조 결정이 바뀌면 `docs/decisions/`에 ADR을 쓰고 여기에 참조를 남긴다.
- 폐기 항목을 되살리려면 사용자의 명시적 결정이 필요하다. AI 도구의 제안만으로 되살리지 않는다.
