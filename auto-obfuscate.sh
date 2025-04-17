#!/bin/bash
set -eo pipefail

# 配置文件路径
INPUT_FILE="origin.js"
OUTPUT_FILE="_worker.js"
LOG_FILE="obfuscation-log.txt"
MAX_SIZE=$((1024 * 1024))  # 1MB
MAX_ATTEMPTS=6

# 初始化日志文件
echo "🔧 混淆流程启动 [$(date +'%Y-%m-%d %H:%M:%S')]" > "$LOG_FILE"

# 清理旧文件
rm -f "$OUTPUT_FILE"

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
    echo -e "\n🔄 尝试 #${attempt}" | tee -a "$LOG_FILE"
    
    # 生成随机参数
    SEED=$RANDOM
    THRESHOLD=$(awk -v min=0.2 -v max=0.8 'BEGIN{srand(); printf "%.2f\n", min + rand()*(max-min)}')
    ENCODINGS=("none" "base64" "rc4")
    ENCODING=${ENCODINGS[$((RANDOM % ${#ENCODINGS[@]}))]}

    # 生成布尔参数
    gen_bool() {
        (( RANDOM % 2 )) && echo "true" || echo "false"
    }
    RENAME_GLOBALS=$(gen_bool)
    SIMPLIFY=$(gen_bool)
    TRANSFORM_KEYS=$(gen_bool)

    # 记录参数到日志
    cat <<EOF | tee -a "$LOG_FILE"
⚙️ 参数配置:
---------------------------------
| 随机种子           | $SEED
| 字符串数组阈值      | $THRESHOLD
| 编码方式           | $ENCODING
| 重命名全局变量      | $RENAME_GLOBALS
| 简化代码           | $SIMPLIFY
| 转换对象键         | $TRANSFORM_KEYS
---------------------------------
EOF

    # 执行混淆命令
    if ! javascript-obfuscator "$INPUT_FILE" \
        --output "$OUTPUT_FILE" \
        --compact true \
        --identifier-name-generator hexadecimal \
        --seed "$SEED" \
        --string-array true \
        --string-array-threshold "$THRESHOLD" \
        --string-array-encoding "$ENCODING" \
        --rename-globals "$RENAME_GLOBALS" \
        --simplify "$SIMPLIFY" \
        --transform-object-keys "$TRANSFORM_KEYS"; then
        echo "❌ 混淆命令执行失败" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 验证输出文件
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        echo "❌ 输出文件未生成" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 检查文件大小
    FILE_SIZE=$(wc -c < "$OUTPUT_FILE")
    echo "📦 文件大小: $((FILE_SIZE / 1024)) KB" | tee -a "$LOG_FILE"

    if [[ $FILE_SIZE -le $MAX_SIZE ]]; then
        echo "✅ 成功生成合规文件" | tee -a "$LOG_FILE"
        exit 0
    else
        echo "⚠️ 文件超过1MB，准备重试..." | tee -a "$LOG_FILE"
        rm -f "$OUTPUT_FILE"
    fi
done

echo "🛑 已达最大尝试次数 ($MAX_ATTEMPTS 次)" | tee -a "$LOG_FILE"
exit 1
