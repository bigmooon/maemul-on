"""네이버 캘린더 등록 요청의 상태 기계.

draft → sending → succeeded | failed | unknown.
timeout은 failed가 아니라 unknown이다. 자동 재전송하지 않는다.
캘린더 실패가 계약·상담 저장을 롤백하지 않는다 (INV-08).
"""
