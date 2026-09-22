import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { App } from '../App';

function renderApp(initialPath = '/') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <App />
    </MemoryRouter>,
  );
}

describe('AppShell', () => {
  it('기본 메뉴를 홈 / 내 매물 / 챗봇 3개만 보여준다', () => {
    renderApp();

    const nav = screen.getByRole('navigation', { name: '기본 메뉴' });
    const links = within(nav).getAllByRole('link');

    expect(links.map((l) => l.textContent)).toEqual(['홈', '내 매물', '챗봇']);
  });

  it('메뉴 버튼이 열림 상태를 aria-expanded로 알린다', async () => {
    const user = userEvent.setup();
    renderApp();

    const toggle = screen.getByRole('button', { name: '메뉴' });
    expect(toggle).toHaveAttribute('aria-expanded', 'false');

    await user.click(toggle);
    expect(toggle).toHaveAttribute('aria-expanded', 'true');
  });
});

describe('라우팅', () => {
  it.each([
    ['/', '홈'],
    ['/properties', '내 매물'],
    ['/chat', '챗봇'],
  ])('%s 경로에서 %s 화면을 연다', (path, title) => {
    renderApp(path);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(title);
  });

  it('알 수 없는 경로에서 안내를 보여준다', () => {
    renderApp('/없는-경로');
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('페이지를 찾을 수 없어요');
  });

  it('구현 전 화면은 담당 TASK를 표시한다', () => {
    renderApp('/');
    expect(screen.getByText('TASK-0006')).toBeInTheDocument();
  });
});
