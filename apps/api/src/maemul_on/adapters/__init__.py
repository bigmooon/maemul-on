"""외부 호출 격리: 네이버 OAuth/Calendar, LLM.

도메인 서비스는 endpoint·header·iCalendar encoding을 모른다.
외부 스펙과 오류를 내부 도메인 오류(errors.ErrorCode)로 번역한다.
"""
