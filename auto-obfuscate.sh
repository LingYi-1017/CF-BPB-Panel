#!/bin/bash

INPUT="origin.js"
OUTPUT="_worker.js"
MAXSIZE=$((1024 * 1024)) # 最大 1MB
MAX_TRIES=6

echo "⚙️ 启动【强制混淆 + 随机降级】流程..."

for ((i=1; i<=MAX_TRIES; i++)); do
  echo "🔁 第 $i 次尝试混淆..."

  # 随机参数生成
  SEED=$((RANDOM))
  THRESHOLD=$(awk -v min=0.2 -v max=0.8 'BEGIN{srand(); printf "%.2f\n", min + rand() * (max - min)}')
  ENCODINGS=("none" "base64" "rc4")
  ENCODING=${ENCODINGS[$RANDOM % ${#ENCODINGS[@]}]}
  RENAME_GLOBALS=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")
  SIMPLIFY=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")
  TRANSFORM_KEYS=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")

  echo "🎲 混淆参数:"
  echo "    seed = $SEED"
  echo "    threshold = $THRESHOLD"
  echo "    encoding = $ENCODING"
  echo "    rename_globals = $RENAME_GLOBALS"
  echo "    simplify = $SIMPLIFY"
  echo "    transform_object_keys = $TRANSFORM_KEYS"

  # 执行混淆
  javascript-obfuscator "$INPUT" \
    --output "$OUTPUT" \
    --seed "$SEED" \
    --compact true \
    --identifier-names-generator hexadecimal \
    --string-array true \
    --string-array-threshold "$THRESHOLD" \
    --string-array-encoding "$ENCODING" \
    --rename-globals "$RENAME_GLOBALS" \
    --simplify "$SIMPLIFY" \
    --transform-object-keys "$TRANSFORM_KEYS"

  FILESIZE=$(stat -c%s "$OUTPUT")
  echo "📦 当前体积：$((FILESIZE / 1024)) KB"

  if [ "$FILESIZE" -le "$MAXSIZE" ]; then
    echo "✅ 成功！体积符合限制 🎉"
    exit 0
  else
    echo "⚠️ 超过 1MB，继续尝试降级..."
  fi
done

echo "❗ 所有尝试均超过 1MB，保留最后一个版本（已混淆）"
exit 0
