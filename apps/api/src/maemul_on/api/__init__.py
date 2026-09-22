"""HTTP route와 요청/응답 schema.

route를 추가할 때: owner_user_id를 요청 body·query·path에 두지 않는다.
서버 세션에서만 주입한다 (INV-06). 공개·공유 route를 만들지 않는다 (INV-11).
"""
