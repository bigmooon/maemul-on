/**
 * 구현 전 화면을 표시하는 플레이스홀더.
 *
 * "곧 제공됩니다" 같은 빈 약속 대신 담당 TASK를 명시한다.
 * 이 컴포넌트는 제품 기능이 구현되면 삭제한다.
 */

interface PlaceholderPageProps {
  title: string;
  description: string;
  taskId: string;
}

export function PlaceholderPage({ title, description, taskId }: PlaceholderPageProps) {
  return (
    <section aria-labelledby="page-title">
      <h1 id="page-title" className="text-[length:var(--text-display)] font-bold">
        {title}
      </h1>

      <p className="mt-[var(--spacing-2)] value-wrap">{description}</p>

      <p className="mt-[var(--spacing-3)] rounded-md border border-amber-300 bg-amber-50 p-[var(--spacing-3)] text-[length:var(--text-small)]">
        아직 구현되지 않은 화면입니다. 담당 작업: <strong>{taskId}</strong>
      </p>
    </section>
  );
}
