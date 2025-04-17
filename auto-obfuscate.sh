#!/bin/bash

INPUT="origin.js"
OUTPUT="_worker.js"
LOGFILE="obfuscation-log.txt"
MAXSIZE=$((1024 * 1024)) # 最大 1MB
MAX_TRIES=6

echo "⚙️ 启动【强制混淆 + 随机降级】流程..." | tee "$LOGFILE"

for ((i=1; i<=MAX_TRIES; i++)); do
  echo "🔁 第 $i 次尝试混淆..." | tee -a "$LOGFILE"

  # 随机参数生成
  SEED=$((RANDOM))
  THRESHOLD=$(awk -v min=0.2 -v max=0.8 'BEGIN{srand(); printf "%.2f\n", min + rand() * (max - min)}')
  ENCODINGS=("none" "base64" "rc4")
  ENCODING=${ENCODINGS[$RANDOM % ${#ENCODINGS[@]}]}
  RENAME_GLOBALS=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")
  SIMPLIFY=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")
  TRANSFORM_KEYS=$([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false")

  echo "🎲 混淆参数:" | tee -a "$LOGFILE"
  echo "    seed = $SEED" | tee -a "$LOGFILE"
  echo "    string-array-threshold = $THRESHOLD" | tee -a "$LOGFILE"
  echo "    string-array-encoding = $ENCODING" | tee -a "$LOGFILE"
  echo "    rename-globals = $RENAME_GLOBALS" | tee -a "$LOGFILE"
  echo "    simplify = $SIMPLIFY" | tee -a "$LOGFILE"
  echo "    transform-object-keys = $TRANSFORM_KEYS" | tee -a "$LOGFILE"

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
  echo "📦 当前混淆体积：$((FILESIZE / 1024)) KB" | tee -a "$LOGFILE"

  if [ "$FILESIZE" -le "$MAXSIZE" ]; then
    echo "✅ 第 $i 次混淆成功 🎉（已写入日志）" | tee -a "$LOGFILE"
    exit 0
  else
    echo "⚠️ 超过 1MB，准备下一次降级尝试..." | tee -a "$LOGFILE"
  fi
done

echo "❌ 所有 $MAX_TRIES 次尝试均失败，但保留了最后混淆版本（已写入日志）" | tee -a "$LOGFILE"
exit 0
