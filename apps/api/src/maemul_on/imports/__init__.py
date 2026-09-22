"""Excel 등록 파이프라인: 검증 → 파싱 → 매핑 → 정규화 → 확인 → 커밋.

원문 값과 셀 메모를 보존하고 불확실한 값을 자동 확정하지 않는다 (INV-12).
preview와 commit을 분리하고 commit은 idempotency key를 요구한다 (INV-09).
"""
