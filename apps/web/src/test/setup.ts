import '@testing-library/jest-dom/vitest';
import { afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import { resetAppShellStore } from '../stores/appShellStore';

// 테스트 간 전역 스토어가 새지 않게 한다.
afterEach(() => {
  cleanup();
  resetAppShellStore();
});
