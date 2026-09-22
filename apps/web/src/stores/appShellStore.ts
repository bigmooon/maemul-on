/**
 * 앱 셸의 UI 상태.
 *
 * 이 스토어에 넣어도 되는 것 (harness.md §13.5):
 * - 브라우저 세션 동안의 작업 UI 상태: 내비 열림, 섹션 열림, 미저장 변경 경고
 *
 * 넣으면 안 되는 것:
 * - 서버 원장(매물·계약·관계자·상담·import job) — 사본을 들고 있으면 갱신이 누락된다
 * - 연락처·상담 원문·OAuth token — persist/localStorage 금지
 * - 목록 필터·검색어·정렬 — 상세에서 돌아올 때 유지해야 하므로 URL search params에 둔다
 * - 뷰포트 폭 — 레이아웃은 CSS breakpoint로 처리한다
 *
 * persist 미들웨어를 쓰지 않는 것은 의도다. PII가 브라우저에 남지 않게 한다.
 */

import { create } from 'zustand';

interface AppShellState {
  /** 모바일 내비 열림 여부. */
  navOpen: boolean;
  /** 저장하지 않은 입력이 있는가. 화면 이탈 경고에 쓴다. */
  hasUnsavedChanges: boolean;

  openNav: () => void;
  closeNav: () => void;
  toggleNav: () => void;
  markUnsaved: () => void;
  clearUnsaved: () => void;
}

export const useAppShellStore = create<AppShellState>((set) => ({
  navOpen: false,
  hasUnsavedChanges: false,

  openNav: () => set({ navOpen: true }),
  closeNav: () => set({ navOpen: false }),
  toggleNav: () => set((s) => ({ navOpen: !s.navOpen })),
  markUnsaved: () => set({ hasUnsavedChanges: true }),
  clearUnsaved: () => set({ hasUnsavedChanges: false }),
}));

/** 테스트에서 스토어를 초기 상태로 되돌린다. */
export function resetAppShellStore(): void {
  useAppShellStore.setState({ navOpen: false, hasUnsavedChanges: false });
}
