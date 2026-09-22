/**
 * 스토어 경계 회귀 테스트.
 *
 * Zustand에 서버 원장이나 PII가 들어가는 것을 막는다 (harness.md §13.5).
 * 상태가 늘어날 때 이 테스트가 먼저 깨지도록 허용 키를 명시한다.
 */

import { describe, expect, it } from 'vitest';
import { resetAppShellStore, useAppShellStore } from './appShellStore';

/** 이 스토어가 가질 수 있는 상태 키. 추가하려면 AGENTS.md의 경계표를 먼저 확인한다. */
const ALLOWED_STATE_KEYS = ['navOpen', 'hasUnsavedChanges'];

const FORBIDDEN_KEY_PATTERNS = [
  /propert/i, // 매물 목록 — 서버 원장이다
  /contract/i, // 계약
  /customer/i, // 고객
  /consultation/i, // 상담
  /phone|contact/i, // 연락처 (PII)
  /token/i, // OAuth token
  /filter|sort|query|search/i, // 목록 조건 — URL search params에 둔다
  /viewport|width|breakpoint/i, // 레이아웃 — CSS로 처리한다
];

describe('appShellStore', () => {
  it('UI 상태 키만 가진다', () => {
    const stateKeys = Object.entries(useAppShellStore.getState())
      .filter(([, value]) => typeof value !== 'function')
      .map(([key]) => key);

    expect(stateKeys.sort()).toEqual([...ALLOWED_STATE_KEYS].sort());
  });

  it('서버 원장·PII·목록 조건에 해당하는 키가 없다', () => {
    const allKeys = Object.keys(useAppShellStore.getState());

    for (const pattern of FORBIDDEN_KEY_PATTERNS) {
      const offending = allKeys.filter((k) => pattern.test(k));
      expect(offending, `${pattern} 에 해당하는 키: ${offending.join(', ')}`).toEqual([]);
    }
  });

  it('브라우저 저장소에 상태를 남기지 않는다', () => {
    // persist 미들웨어를 쓰지 않는 것이 의도다. PII가 브라우저에 남으면 안 된다.
    useAppShellStore.getState().markUnsaved();
    useAppShellStore.getState().openNav();

    expect(localStorage.length).toBe(0);
    expect(sessionStorage.length).toBe(0);
  });

  it('내비 토글이 동작한다', () => {
    const { toggleNav, closeNav } = useAppShellStore.getState();

    expect(useAppShellStore.getState().navOpen).toBe(false);
    toggleNav();
    expect(useAppShellStore.getState().navOpen).toBe(true);
    closeNav();
    expect(useAppShellStore.getState().navOpen).toBe(false);
  });

  it('미저장 변경 플래그를 세우고 지운다', () => {
    const { markUnsaved, clearUnsaved } = useAppShellStore.getState();

    markUnsaved();
    expect(useAppShellStore.getState().hasUnsavedChanges).toBe(true);
    clearUnsaved();
    expect(useAppShellStore.getState().hasUnsavedChanges).toBe(false);
  });

  it('resetAppShellStore가 초기 상태로 되돌린다', () => {
    useAppShellStore.getState().markUnsaved();
    useAppShellStore.getState().openNav();

    resetAppShellStore();

    expect(useAppShellStore.getState()).toMatchObject({
      navOpen: false,
      hasUnsavedChanges: false,
    });
  });
});
