"""시각 주입.

도메인 코드는 `date.today()` / `datetime.now()` 를 직접 호출하지 않는다.
`Clock` 을 주입받아 테스트·평가·데모가 CI 날짜와 무관하게 재현되도록 한다.
근거: harness.md §7.2, §14.3 / INV-02.
"""

from __future__ import annotations

from datetime import date, datetime
from typing import Protocol
from zoneinfo import ZoneInfo

SEOUL = ZoneInfo("Asia/Seoul")


class Clock(Protocol):
    """현재 시각의 출처. 도메인 서비스는 이 Protocol만 의존한다."""

    def now(self) -> datetime:
        """timezone이 붙은 현재 시각."""
        ...

    def today(self) -> date:
        """Asia/Seoul 기준 오늘 날짜."""
        ...


class SystemClock:
    """운영용. 서버 시각을 Asia/Seoul로 변환해 사용한다."""

    def __init__(self, tz: ZoneInfo = SEOUL) -> None:
        self._tz = tz

    def now(self) -> datetime:
        return datetime.now(tz=self._tz)

    def today(self) -> date:
        return self.now().date()


class FixedClock:
    """테스트·평가·데모용. 고정된 시각을 돌려준다.

    만기 경계(월말, 윤년, 경계 다음 날)를 재현하려면 이 clock을 주입한다.
    """

    def __init__(self, moment: datetime) -> None:
        if moment.tzinfo is None:
            moment = moment.replace(tzinfo=SEOUL)
        self._moment = moment

    def now(self) -> datetime:
        return self._moment

    def today(self) -> date:
        return self._moment.astimezone(SEOUL).date()
