/**
 * 라우팅 골격.
 *
 * 세 화면 모두 아직 플레이스홀더다. 제품 기능은 각 TASK에서 구현한다.
 * 목록의 분류·검색 조건은 구현 시 Zustand가 아니라 URL search params에 둔다.
 */

import { Route, Routes } from 'react-router-dom';
import { AppShell } from './components/AppShell';
import { PlaceholderPage } from './components/PlaceholderPage';

export function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route
          index
          element={
            <PlaceholderPage
              title="홈"
              description="오늘부터 달력 기준 3개월 내 만기인 매물을 가까운 순서로 보여줍니다. 중점·서브·일반 모든 관리 등급을 포함합니다."
              taskId="TASK-0006"
            />
          }
        />
        <Route
          path="properties"
          element={
            <PlaceholderPage
              title="내 매물"
              description="전체 / 중점 / 서브 / 일반로 나누어 보고, 매물명·동·호수와 거래 유형으로 찾습니다."
              taskId="TASK-0007"
            />
          }
        />
        <Route
          path="chat"
          element={
            <PlaceholderPage
              title="챗봇"
              description="내 자료에 대해 질문합니다. 읽기 전용이며 근거가 없으면 확인할 수 없다고 답합니다."
              taskId="TASK-0011"
            />
          }
        />
        <Route
          path="*"
          element={
            <PlaceholderPage
              title="페이지를 찾을 수 없어요"
              description="주소를 다시 확인해 주세요."
              taskId="—"
            />
          }
        />
      </Route>
    </Routes>
  );
}
