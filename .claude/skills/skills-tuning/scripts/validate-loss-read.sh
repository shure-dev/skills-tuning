#!/bin/bash
# Loss評価時のデータリーク防止スクリプト
# PreToolUse hook で Read ツール呼び出し前に実行される
# 禁止パスへのアクセスを exit 2 でブロックする
#
# 許可: output ファイル（runs/ 配下）、reference ファイル（data/ 配下）、eval_config
# 禁止: スキルフォルダ、improvement.md、scoreboard.md、judgment-log.md

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# スキルフォルダへのアクセスをブロック（学習対象を見せない）
if echo "$FILE_PATH" | grep -qE '(^|/)\.claude/skills/'; then
  echo "Blocked: loss-evaluator はスキルフォルダを読み込めません。アクセス先: $FILE_PATH" >&2
  exit 2
fi

# improvement.md へのアクセスをブロック
if echo "$FILE_PATH" | grep -qE '(^|/)improvement\.md'; then
  echo "Blocked: loss-evaluator は improvement.md を読み込めません" >&2
  exit 2
fi

# scoreboard.md へのアクセスをブロック
if echo "$FILE_PATH" | grep -qE '(^|/)scoreboard\.md'; then
  echo "Blocked: loss-evaluator は scoreboard.md を読み込めません" >&2
  exit 2
fi

# judgment-log.md へのアクセスをブロック（forward の推論ログは評価に使わない）
if echo "$FILE_PATH" | grep -qE '(^|/)judgment-log\.md'; then
  echo "Blocked: loss-evaluator は judgment-log.md を読み込めません" >&2
  exit 2
fi

# それ以外は許可（output.json, reference.json, eval_config.md 等）
exit 0
