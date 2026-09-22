"""비동기 작업 큐와 worker.

Redis 없이 PostgreSQL job table을 쓴다 (TASK-0002에서 구현).
재시도 가능 여부는 errors.ErrorCode로 판단한다.
"""
