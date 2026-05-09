# Next Trip Time Assistant (`nxtript`)

時刻表データ（YAML）から、現在時刻に基づいた「次」「その次」の便、および「今日の終便（終バス）」の時刻を素早く検索するツールです。自然言語への変換や、macOS の `say` コマンドによる音声読み上げにも対応しています。

## 特徴

- **柔軟なスケジュール判定**: 曜日、祝日（`holidays.yml`）、特定日のカレンダー上書き（`calendar.yml`）に対応。
- **JSON 出力**: `--json` オプションにより、他のツールとの連携が容易。
- **自然言語変換**: JSON 出力を読みやすい日本語メッセージに変換。
- **音声読み上げ**: macOS 標準の `say` コマンドを使用した音声通知。

## 使い方

### 1. 次の便を検索する

```bash
# 基本実行 (デフォルトで sample.yaml を使用)
ruby nxtript.rb

# ファイルを指定して実行
ruby nxtript.rb sample.yaml

# JSON 形式で出力
ruby nxtript.rb --json
```

### 2. 日本語メッセージに変換して読み上げる

`nxtript_natural.rb` を使用して、結果を読みやすい形に変換したり、音声で通知したりできます。

```bash
# 日本語メッセージとして表示
ruby nxtript.rb --json | ruby nxtript_natural.rb

# メッセージを表示し、さらに音声で読み上げる (macOS のみ)
ruby nxtript.rb --json | ruby nxtript_natural.rb --say
```

## 設定ファイル

- `[prefix].yaml`: 各路線の時刻表データ。
- `holidays.yml`: 祝祭日のリスト。
- `calendar.yml`: 特定の日付のサービス（平日/土日祝など）を強制指定する設定。

## インストール

Ruby がインストールされている環境であれば、リポジトリをクローンするだけで利用可能です。

```bash
git clone [repository-url]
cd nxtript
```

## テスト

```bash
ruby test_nxtript.rb
```
