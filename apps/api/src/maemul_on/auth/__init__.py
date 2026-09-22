"""네이버 OAuth, 세션, 현재 사용자 확인.

state는 서버가 생성·저장하고 callback에서 일치를 검사한다.
token과 authorization code를 URL 분석 로그·오류 추적·LLM 입력에 남기지 않는다.
매물온 로그아웃과 네이버 계정 로그아웃을 구분한다.
"""
