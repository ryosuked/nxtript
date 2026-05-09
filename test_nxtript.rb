require_relative 'nxtript'
require 'test/unit'

class TestNextDeparture < Test::Unit::TestCase
  def test_merged_sample
    finder = NextDepartureFinder.new("sample.yaml")

    # 2026-05-12 (Tue) 05:00 -> wk: next 05:12, second 05:25, last 23:59
    t_tue = Time.new(2026, 5, 12, 5, 0, 0)
    info = finder.departure_info(t_tue)
    assert_equal "05:12", info[:next]
    assert_equal "05:25", info[:second_next]
    assert_equal "23:59", info[:last]

    # 2026-05-16 (Sat) 05:00 -> sat_sun_hol: next 05:25, second 05:40, last 23:59
    t_sat = Time.new(2026, 5, 16, 5, 0, 0)
    info = finder.departure_info(t_sat)
    assert_equal "05:25", info[:next]
    assert_equal "05:40", info[:second_next]
    assert_equal "23:59", info[:last]
  end

  def test_separated_sample
    finder = NextDepartureFinder.new("sample_separated.yaml")

    # 2026-05-16 (Sat) 05:00 -> sat: next 05:20, second 05:35, last 05:35
    t_sat = Time.new(2026, 5, 16, 5, 0, 0)
    info = finder.departure_info(t_sat)
    assert_equal "05:20", info[:next]
    assert_equal "05:35", info[:second_next]
  end
  def test_next_day_rollover
    finder = NextDepartureFinder.new("sample.yaml")
    
    # 2026-05-12 (Tue) 23:59:01 -> Next is Wed (wk) 05:12. Last Today: Service ended for today
    t_tue_night = Time.new(2026, 5, 12, 23, 59, 1)
    info = finder.departure_info(t_tue_night)
    assert_equal "05:12", info[:next]
    assert_equal "05:25", info[:second_next]
    assert_equal "Service ended for today", info[:last]
  end

  def test_holiday_from_file
    finder = NextDepartureFinder.new("sample.yaml")

    # 2026-05-11 (Mon) is holiday -> sat_sun_hol: next 05:25
    t_holiday = Time.new(2026, 5, 11, 5, 0, 0)
    info = finder.departure_info(t_holiday)
    assert_equal "05:25", info[:next]
  end

  def test_calendar_override_from_file
    finder = NextDepartureFinder.new("sample.yaml")

    # 2026-12-30 (Wed) is "sat" -> sat_sun_hol: next 05:25
    t_override = Time.new(2026, 12, 30, 5, 0, 0)
    info = finder.departure_info(t_override)
    assert_equal "05:25", info[:next]
  end
end

