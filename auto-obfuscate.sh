#!/bin/bash

INPUT="origin.js"
OUTPUT="_worker.js"
LOGFILE="obfuscation-log.txt"
MAXSIZE=$((1024 * 1024))  # 1MB = 1024*1024 bytes
MAX_TRIES=6

echo "🚀 启动 [强制注册 + 随机响应] 流程..." | tee "$LOGFILE"

for ((i=1; i<=MAX_TRIES; i++)); do
    echo "\n🔄 第 $i 次尝试注册..." | tee -a "$LOGFILE"

    # 生成随机参数
    SEED=$RANDOM
    THRESHOLD=$(awk -v min=0.2 -v max=0.8 'BEGIN{srand(); printf "%.2f\n", min + rand() * (max - min)}')
    
    ENCODINGS=("none" "base64" "rc4")
    ENCODING=${ENCODINGS[$RANDOM % ${#ENCODINGS[@]}]}

    # 生成布尔参数
    generate_bool() {
        [ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false"
    }
    RENAME_GLOBALS=$(generate_bool)
    SIMPLIFY=$(generate_bool)
    TRANSFORM_KEY=$(generate_bool)

    # 记录完整参数
    echo "⚙️ 混淆参数：" | tee -a "$LOGFILE"
    cat <<EOF | tee -a "$LOGFILE"
| 参数                      | 值          |
|---------------------------|-------------|
| Seed                      | $SEED       |
| String Array Threshold    | $THRESHOLD  |
| String Array Encoding     | $ENCODING   |
| Rename Globals            | $RENAME_GLOBALS |
| Simplify Code             | $SIMPLIFY   |
| Transform Object Keys     | $TRANSFORM_KEY |
EOF

    # 执行混淆
    javascript-obfuscator "$INPUT" \
        --output "$OUTPUT" \
        --compact true \
        --identifier-name-generator hexadecimal \
        --seed "$SEED" \
        --string-array true \
        --string-array-threshold "$THRESHOLD" \
        --string-array-encoding "$ENCODING" \
        --rename-globals "$RENAME_GLOBALS" \
        --simplify "$SIMPLIFY" \
        --transform-object-keys "$TRANSFORM_KEY"

    # 检查文件大小
    FILESIZE=$(wc -c < "$OUTPUT")
    echo "📊 文件大小: $((FILESIZE / 1024)) KB" | tee -a "$LOGFILE"

    if [ "$FILESIZE" -le "$MAXSIZE" ]; then
        echo "✅ 第 $i 次注册成功 (符合大小要求)" | tee -a "$LOGFILE"
        exit 0
    else
        echo "⚠️ 文件超过 1MB，准备第 $((i+1)) 次尝试..." | tee -a "$LOGFILE"
        rm -f "$OUTPUT"  # 删除过大的文件
    fi
done

echo "❌ 所有 $MAX_TRIES 次尝试均失败" | tee -a "$LOGFILE"
exit 1
