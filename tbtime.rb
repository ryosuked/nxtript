require 'yaml'
require 'time'
require 'date'
require 'json'

class NextDepartureFinder
  TIME_ZONE = 'Asia/Tokyo'

  def initialize(yaml_path)
    @data = YAML.load_file(yaml_path)
    load_external_data
  end

  # 次の便、その次の便、および終便を取得
  def departure_info(now = Time.now)
    service_key = resolve_service_key(now)
    timetable = @data.dig("timetables", service_key) || []
    now_time = to_today_time(now)

    today_buses = timetable.map { |t| build_time(now, t["time"]) }
    
    # 終便判定（今日のサービスキーにおける最後の便）
    last_bus_today = today_buses.last
    last_status = if last_bus_today.nil?
      "None"
    elsif now_time > last_bus_today
      "Service ended for today"
    else
      last_bus_today.strftime("%H:%M")
    end

    # 次の便とさらにその次の便を探す
    found_buses = today_buses.select { |t| t > now_time }

    # 今日足りない分を翌日以降から補充
    search_date = now
    while found_buses.size < 2
      search_date += 86400
      next_key = resolve_service_key(search_date)
      next_timetable = @data.dig("timetables", next_key) || []
      break if next_timetable.empty? && search_date > now + 86400 * 7 # 1週間探してなければ中断

      next_timetable.each do |t|
        found_buses << build_time(search_date, t["time"])
        break if found_buses.size >= 2
      end
    end

    {
      next: found_buses[0] ? found_buses[0].strftime("%H:%M") : "なし",
      second_next: found_buses[1] ? found_buses[1].strftime("%H:%M") : "なし",
      last: last_status
    }
  end

  private

  def load_external_data
    holiday_path = ENV['TBTIME_HOLIDAYS_FILE'] || 'holidays.yml'
    calendar_path = ENV['TBTIME_CALENDAR_FILE'] || 'calendar.yml'

    raw_holidays = File.exist?(holiday_path) ? YAML.load_file(holiday_path) : []
    raw_calendar = File.exist?(calendar_path) ? YAML.load_file(calendar_path) : {}

    # 日付を文字列として扱うため正規化 (YAMLがDateオブジェクトで返すことがあるため)
    @holidays = Array(raw_holidays).map { |d| d.is_a?(Date) ? d.strftime("%Y-%m-%d") : d.to_s }
    @calendar = {}
    if raw_calendar.is_a?(Hash)
      raw_calendar.each do |k, v|
        key = k.is_a?(Date) ? k.strftime("%Y-%m-%d") : k.to_s
        @calendar[key] = v.to_s
      end
    end
  end

  # --- service 判定 ---

  def resolve_service_key(time)
    date_str = time.strftime("%Y-%m-%d")

    # 1. カレンダー上書きを最優先
    key = @calendar[date_str]
    
    unless key
      # 2. 祝日判定
      if holiday?(time)
        key = "sun_hol"
      else
        # 3. 曜日判定
        wday = time.wday # 0=Sun
        key = if wday == 0
          "sun_hol"
        elsif wday == 6
          "sat"
        else
          "wk"
        end
      end
    end

    # 特定のキーがあればそれを優先
    return key if @data.dig("timetables", key)

    # 土日祝が共通定義されている場合のフォールバック
    if (key == "sat" || key == "sun_hol") && @data.dig("timetables", "sat_sun_hol")
      return "sat_sun_hol"
    end

    key
  end

  def holiday?(time)
    date_str = time.strftime("%Y-%m-%d")
    @holidays.include?(date_str)
  end

  # --- 時刻変換 ---

  def build_time(base_date, hhmm)
    hour, min = hhmm.split(":").map(&:to_i)
    Time.new(base_date.year, base_date.month, base_date.day, hour, min, 0)
  end

  def to_today_time(time)
    Time.new(time.year, time.month, time.day, time.hour, time.min, time.sec)
  end

  # --- 翌日サイクル ---

  def next_service(time)
    next_day = time + 86400
    [resolve_service_key(next_day), next_day]
  end

  # --- 出力 ---

  def format_result(time)
    {
      time: time,
      formatted: time.strftime("%H:%M")
    }
  end
end

# -------------------------
# 実行ブロック
# -------------------------
if __FILE__ == $0
  use_json = ARGV.delete("--json")
  
  arg = ARGV[0] || "sample"
  yaml_path = arg.end_with?(".yaml") ? arg : "#{arg}.yaml"

  unless File.exist?(yaml_path)
    if use_json
      puts({ error: "File not found: #{yaml_path}" }.to_json)
    else
      puts "Error: File not found: #{yaml_path}"
      puts "Usage: ruby nxtript.rb [filename_prefix] [--json]"
    end
    exit 1
  end

  finder = NextDepartureFinder.new(yaml_path)
  result = finder.departure_info

  if use_json
    puts result.merge(file: yaml_path).to_json
  else
    puts "File: #{yaml_path}"
    puts "Next:        #{result[:next]}"
    puts "Second Next: #{result[:second_next]}"
    puts "Last Today:  #{result[:last]}"
  end
end
