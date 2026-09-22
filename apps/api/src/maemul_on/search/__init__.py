"""Query DSL compiler와 상담 FTS 검색.

LLM이 만들 수 있는 것은 allowlist schema이지 SQL이 아니다 (INV-07).
후보 생성과 최종 fetch 양쪽 모두 owner filter를 적용한다 (INV-06).
"""
