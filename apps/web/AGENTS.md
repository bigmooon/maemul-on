# AGENTS.md — apps/web

루트 [`AGENTS.md`](../../AGENTS.md)를 먼저 읽었다고 전제한다. 여기에는 **웹 고유 규칙만** 둔다.
근거: [harness.md §13.5, §13.6](../../docs/architecture/harness.md), [requirements.md §4](../../docs/product/requirements.md).

## 스택

React 19 + TypeScript + Vite + Zustand + Tailwind CSS v4 + React Router.
SSR 프레임워크는 쓰지 않는다. 로그인 후 사용하는 개인 업무 SPA다.

## 상태 소유 경계

상태를 어디에 둘지 헷갈리면 이 표가 결정한다. **잘못된 위치에 두는 것이 이 앱에서 가장 흔한 버그다.**

| 상태 종류 | 소유 위치 | 예시 |
|---|---|---|
| 서버 원장 | API + query cache | 매물, 계약, 관계자, 상담, import job |
| URL 상태 | React Router search params | 중점/서브 필터, 거래 유형, 만기 조건, 검색어, 정렬 |
| Zustand | 브라우저 세션의 작업 UI | import 검토 진행, 직접 등록 draft, 섹션 열림, 미저장 변경 경고 |
| component local | 개별 입력/표시 | dropdown 열림, 임시 focus |

### Zustand 금지사항

- **서버에서 받은 매물·계약 배열을 Zustand에 복제하지 않는다.** 원장의 사본을 클라이언트가 들고 있으면 갱신 누락이 생긴다.
- **연락처·상담 원문·OAuth token을 Zustand `persist`나 `localStorage`에 저장하지 않는다.**
- **뷰포트 폭을 Zustand에 저장해 화면을 분기하지 않는다.** 레이아웃은 CSS breakpoint로 처리한다.
- 목록으로 돌아갈 때 유지해야 하는 검색 조건은 Zustand가 아니라 **URL**에 둔다. (requirements.md §4.5)
- optimistic update는 뱃지 변경처럼 되돌리기 쉬운 작업에만 쓴다. **계약 갱신·캘린더 등록은 서버 성공 전 완료로 표시하지 않는다.**

## rem 기반 반응형

기준은 `html { font-size: 100% }`다. **`62.5%`로 낮춰 1rem을 10px처럼 쓰지 않는다.** 사용자의 브라우저 글자 확대를 방해한다.

토큰은 `src/styles/tokens.css`의 `@theme`에 한 곳으로 모은다. 컴포넌트에서 px를 직접 쓰지 않는다.

- 본문 기본 `1.125rem`. 작은 보조 정보도 `0.875rem` 아래로 내리지 않는다.
- 주요 버튼·입력의 최소 높이 `2.75rem`. 모바일 핵심 버튼은 가능하면 `3rem`.
- `48rem` 미만 1열, `48~64rem` 상황에 따라 2열, `64rem` 이상에서 상세 form 2열 허용.
- 금액·연락처·날짜처럼 긴 값은 말줄임만 하지 말고 wrap하거나 행을 나눈다.
- table은 모바일에서 가로 스크롤에만 의존하지 않고 card/list view로 전환한다.

## 접근성

초기 실사용자는 40대 이상 공인중개사다. 큰 글씨·버튼, 적은 선택지, 쉬운 용어가 요구사항이다.

- **hover 없이 모든 조작이 가능해야 한다.** focus ring, label, error text, `aria-live` 상태를 제공한다.
- 뱃지 색상만으로 의미를 전달하지 않는다. 텍스트를 함께 쓴다.
- 20rem(320px) 너비에서 가로 스크롤 없이 동작한다.

## 화면 규칙

- 기본 메뉴는 **홈 / 내 매물 / 챗봇 3개**다. 고객·캘린더·Excel을 각각 독립 대시보드로 늘리지 않는다.
- 홈에 챗봇 입력창·복잡한 통계·원본 셀 근거·전체 캘린더를 붙이지 않는다.
- 연락처는 기본 마스킹하고 사용자가 명시적으로 열 때만 전체 값을 보여준다.
- 일반 사용 화면에 Excel sheet/cell 좌표를 전면 노출하지 않는다. import 검토 경로에서만 쓴다.
- 모든 화면에 loading / empty / error / success 상태가 있어야 한다.

## 오류 표시

서버 응답의 `error_code`, `retryable`, `user_message`를 사용한다. **서버의 raw exception을 화면에 표시하지 않는다.**

## 명령

```bash
pnpm --filter web dev        # 개발 서버
pnpm --filter web build      # 프로덕션 빌드
pnpm --filter web test       # Vitest
pnpm --filter web typecheck  # tsc --noEmit
pnpm --filter web lint       # ESLint
```
