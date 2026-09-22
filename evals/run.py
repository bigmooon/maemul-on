"""평가 실행기 (골격).

아직 데이터셋과 grader가 없다. 실행하면 그 사실을 명확히 보고하고 종료 코드 1을 반환한다.
"빈 데이터셋으로 통과"를 만들지 않기 위함이다.

TASK-0012에서 note_retrieval baseline과 함께 실제 실행기를 구현한다.
규칙은 evals/AGENTS.md를 따른다.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Windows 콘솔의 기본 코드페이지(cp949)에서 한글 출력이 깨진다.
for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(encoding="utf-8")

EVALS_DIR = Path(__file__).parent
DATASETS_DIR = EVALS_DIR / "datasets"


def main() -> int:
    parser = argparse.ArgumentParser(description="매물온 평가 실행기")
    parser.add_argument("--dataset", help="datasets/ 안의 데이터셋 이름 (예: structured_queries.v1)")
    parser.add_argument("--list", action="store_true", help="사용 가능한 데이터셋 목록")
    args = parser.parse_args()

    datasets = sorted(DATASETS_DIR.glob("*.jsonl"))

    if args.list or not args.dataset:
        if not datasets:
            print("사용 가능한 데이터셋이 없습니다.")
            print()
            print("평가셋은 아직 만들지 않았습니다. 담당 작업: TASK-0012")
            print("추가할 때 규칙: evals/AGENTS.md")
            print("  - 실제 고객의 이름·전화번호·상담 원문을 넣지 않는다")
            print("  - 리포트에 run_id, git_sha, dataset_hash, prompt_id, model_id를 남긴다")
            print("  - 평균 점수만 저장하지 않고 case별 예측과 실패 유형을 남긴다")
            return 1
        print("사용 가능한 데이터셋:")
        for d in datasets:
            print(f"  - {d.stem}")
        return 0

    target = DATASETS_DIR / f"{args.dataset}.jsonl"
    if not target.exists():
        print(f"데이터셋을 찾을 수 없습니다: {target}", file=sys.stderr)
        return 1

    print(f"실행기가 아직 구현되지 않았습니다: {target.name} (TASK-0012)", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
