#!/bin/bash

INPUT="origin.js"
OUTPUT="_worker.js"
MAXSIZE=$((1024 * 1024)) # 最大文件大小：1MB

echo "⚙️ 启动自动多级混淆流程..."

# 从强到弱的混淆策略列表
declare -a configs=(
  "--compact true --identifier-names-generator hexadecimal --rename-globals true --string-array true --string-array-encoding base64 --string-array-threshold 0.6 --simplify true --transform-object-keys true"
  "--compact true --identifier-names-generator hexadecimal --string-array true --string-array-threshold 0.5 --simplify true"
  "--compact true --identifier-names-generator hexadecimal --string-array true --string-array-threshold 0.3"
)

# 遍历混淆策略，直到通过体积限制
for ((i=0; i<${#configs[@]}; i++)); do
  echo "🔁 尝试混淆策略 $((i+1))..."
  javascript-obfuscator "$INPUT" --output "$OUTPUT" ${configs[$i]}

  FILESIZE=$(stat -c%s "$OUTPUT")
  echo "📦 混淆后文件大小：$((FILESIZE / 1024)) KB"

  if [ "$FILESIZE" -le "$MAXSIZE" ]; then
    echo "✅ 成功！策略 $((i+1)) 满足 1MB 限制"
    exit 0
  fi
done

# 所有策略都失败，构建中止
echo "❌ 所有混淆策略都超出 1MB 限制，构建失败"
exit 1
