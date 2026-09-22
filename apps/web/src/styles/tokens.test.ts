/**
 * rem 토큰 회귀 테스트.
 *
 * 토큰 파일이 px로 바뀌거나 font-size가 62.5%로 내려가는 것을 막는다.
 * 근거: harness.md §13.6.
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { describe, expect, it } from 'vitest';

const tokensCss = readFileSync(
  join(dirname(fileURLToPath(import.meta.url)), 'tokens.css'),
  'utf-8',
);

function tokenValue(name: string): string {
  const match = tokensCss.match(new RegExp(`--${name}:\\s*([^;]+);`));
  if (!match?.[1]) throw new Error(`토큰 --${name} 을 찾을 수 없다`);
  return match[1].trim();
}

describe('rem 토큰', () => {
  it('루트 font-size가 100%다', () => {
    // 62.5%로 낮추면 사용자의 브라우저 글자 확대가 어긋난다.
    expect(tokensCss).toMatch(/font-size:\s*100%/);
    expect(tokensCss).not.toMatch(/font-size:\s*62\.5%/);
  });

  it('본문은 1.125rem이다', () => {
    expect(tokenValue('text-body')).toBe('1.125rem');
  });

  it('가장 작은 글자도 0.875rem 아래로 내려가지 않는다', () => {
    const smallest = ['text-small', 'text-tiny'].map((n) => parseFloat(tokenValue(n)));
    expect(Math.min(...smallest)).toBeGreaterThanOrEqual(0.875);
  });

  it('조작 요소의 최소 높이가 2.75rem 이상이다', () => {
    expect(parseFloat(tokenValue('control-min-height'))).toBeGreaterThanOrEqual(2.75);
    expect(parseFloat(tokenValue('control-min-height-primary'))).toBeGreaterThanOrEqual(3);
  });

  it('모든 크기·간격 토큰이 rem 단위다', () => {
    const sizeTokens = tokensCss.matchAll(
      /--(text|spacing|control|content|breakpoint)-[a-z-]+:\s*([^;]+);/g,
    );

    for (const [, group, value] of sizeTokens) {
      expect(value?.trim(), `--${group} 토큰이 rem이 아니다: ${value}`).toMatch(/rem$/);
    }
  });
});
