#!/bin/bash
# Forward推論時のデータリーク防止スクリプト
# PreToolUse hook で Read ツール呼び出し前に実行される
# 禁止パスへのアクセスを exit 2 でブロックする
#
# 配置場所: skills-fine-tuning/scripts/
# Step 0 で作業フォルダの scripts/ にコピーされる

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# reference ファイルへのアクセスをブロック
if echo "$FILE_PATH" | grep -qE '(^|/)reference\.(json|md)'; then
  echo "Blocked: reference ファイルへのアクセスは forward 推論中は禁止です" >&2
  exit 2
fi

# runs/ 配下へのアクセスをブロック（ただしスキルフォルダは許可）
if echo "$FILE_PATH" | grep -qE '(^|/)runs/' && ! echo "$FILE_PATH" | grep -qE '(^|/)runs/[^/]+/skill/'; then
  echo "Blocked: runs/ へのアクセスは forward 推論中は禁止です（runs/exp_NN/skill/ を除く）" >&2
  exit 2
fi

# fine-tuning 設定ファイルへのアクセスをブロック
if echo "$FILE_PATH" | grep -qE '(^|/)(loss|backward|step|forward)\.md'; then
  echo "Blocked: fine-tuning 設定ファイルへのアクセスは forward 推論中は禁止です" >&2
  exit 2
fi

# score.md へのアクセスをブロック
if echo "$FILE_PATH" | grep -qE '(^|/)score\.md'; then
  echo "Blocked: score.md へのアクセスは forward 推論中は禁止です" >&2
  exit 2
fi

exit 0
