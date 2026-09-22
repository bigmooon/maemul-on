"""Clock 주입 테스트.

만기 계산(INV-02)이 CI 날짜에 의존하지 않도록 FixedClock이 동작해야 한다.
"""

from datetime import date, datetime
from zoneinfo import ZoneInfo

import pytest

from maemul_on.clock import SEOUL, Clock, FixedClock, SystemClock

pytestmark = pytest.mark.unit


def test_system_clock_uses_seoul_timezone():
    clock = SystemClock()
    assert clock.now().tzinfo is SEOUL


def test_fixed_clock_returns_the_given_moment():
    moment = datetime(2026, 9, 16, 9, 0, tzinfo=SEOUL)
    clock = FixedClock(moment)

    assert clock.now() == moment
    assert clock.today() == date(2026, 9, 16)


def test_fixed_clock_assumes_seoul_for_naive_input():
    clock = FixedClock(datetime(2026, 9, 16, 9, 0))
    assert clock.now().tzinfo is SEOUL


def test_fixed_clock_converts_other_timezones_to_seoul_date():
    """UTC 기준으로는 전날이지만 Asia/Seoul에서는 다음 날인 경계.

    만기 목록의 '오늘'은 Asia/Seoul 기준이어야 한다 (requirements.md §4.3).
    """
    utc_moment = datetime(2026, 9, 15, 23, 30, tzinfo=ZoneInfo("UTC"))
    clock = FixedClock(utc_moment)

    assert clock.today() == date(2026, 9, 16)


def test_both_clocks_satisfy_the_protocol():
    """도메인 서비스는 Clock Protocol만 의존한다."""
    clocks: list[Clock] = [SystemClock(), FixedClock(datetime(2026, 9, 16, tzinfo=SEOUL))]
    for clock in clocks:
        assert isinstance(clock.today(), date)
