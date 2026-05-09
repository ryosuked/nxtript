require 'json'

def to_natural_language(json_str)
  begin
    data = JSON.parse(json_str)
  rescue JSON::ParserError => e
    return "エラー: JSONの形式が正しくありません (#{e.message})"
  end

  next_time = data["next"]
  second_next = data["second_next"]
  last_time = data["last"]

  if last_time == "Service ended for today"
    "終便は過ぎています。始発の到着時刻は #{next_time} です。その次の到着時刻は #{second_next} です。"
  elsif next_time == last_time
    "次の到着は終便です。時刻は #{next_time} です。始発の到着時刻は #{second_next} です。"
  else
    "次の到着時刻は #{next_time} です。その次の到着時刻は #{second_next} です。終便は #{last_time} です。"
  end
end

if __FILE__ == $0
  use_say = ARGV.delete("--say")

  input = STDIN.read.strip
  exit if input.empty?

  # 入力が複数のJSONオブジェクト（行ごと）の場合も考慮
  input.each_line do |line|
    next if line.strip.empty?
    message = to_natural_language(line)
    puts message
    
    if use_say
      # macOSのsayコマンドで読み上げ (日本語環境を想定)
      # シェルのエスケープを考慮して system を使用
      system("say", message)
    end
  end
end
