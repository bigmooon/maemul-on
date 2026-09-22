/**
 * 앱 셸: 헤더 + 기본 메뉴 3개 + 본문.
 *
 * 기본 메뉴는 홈 / 내 매물 / 챗봇 3개로 고정한다 (requirements.md §4.2).
 * 고객·캘린더·Excel을 각각 독립 대시보드로 늘리지 않는다.
 */

import { NavLink, Outlet } from 'react-router-dom';
import { useAppShellStore } from '../stores/appShellStore';

const NAV_ITEMS = [
  { to: '/', label: '홈', end: true },
  { to: '/properties', label: '내 매물', end: false },
  { to: '/chat', label: '챗봇', end: false },
] as const;

export function AppShell() {
  const navOpen = useAppShellStore((s) => s.navOpen);
  const toggleNav = useAppShellStore((s) => s.toggleNav);
  const closeNav = useAppShellStore((s) => s.closeNav);

  return (
    <div className="min-h-screen">
      <header className="border-b border-neutral-200 bg-white">
        <div className="mx-auto flex max-w-[var(--content-max)] items-center justify-between gap-[var(--spacing-2)] px-[var(--spacing-3)] py-[var(--spacing-2)]">
          <span className="text-[length:var(--text-title)] font-bold">매물온</span>

          <button
            type="button"
            onClick={toggleNav}
            aria-expanded={navOpen}
            aria-controls="main-nav"
            className="min-h-[var(--control-min-height)] rounded-md border border-neutral-300 px-[var(--spacing-2)] md:hidden"
          >
            메뉴
          </button>
        </div>

        {/* 48rem 미만에서는 버튼으로 펼치고, 이상에서는 항상 보인다. */}
        <nav
          id="main-nav"
          aria-label="기본 메뉴"
          className={`${navOpen ? 'block' : 'hidden'} border-t border-neutral-200 md:block md:border-t-0`}
        >
          <ul className="mx-auto flex max-w-[var(--content-max)] flex-col md:flex-row">
            {NAV_ITEMS.map((item) => (
              <li key={item.to}>
                <NavLink
                  to={item.to}
                  end={item.end}
                  onClick={closeNav}
                  className={({ isActive }) =>
                    [
                      'flex min-h-[var(--control-min-height)] items-center px-[var(--spacing-3)] py-[var(--spacing-2)]',
                      // 색상만으로 상태를 전달하지 않도록 밑줄과 굵기를 함께 쓴다.
                      isActive
                        ? 'font-bold text-blue-700 underline underline-offset-4'
                        : 'text-neutral-700',
                    ].join(' ')
                  }
                >
                  {item.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </header>

      <main className="mx-auto max-w-[var(--content-max)] px-[var(--spacing-3)] py-[var(--spacing-4)]">
        <Outlet />
      </main>
    </div>
  );
}
