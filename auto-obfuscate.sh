#!/bin/bash
set -eo pipefail

# 配置文件
INPUT_FILE="origin.js"
OUTPUT_FILE="_worker.js"
LOG_FILE="obfuscation-log.txt"
MAX_SIZE=1048576  # 1MB = 1024*1024
MAX_ATTEMPTS=6

# 初始化日志
echo "🛠️ 混淆流程启动 [$(date +'%Y-%m-%d %H:%M:%S')]" > "$LOG_FILE"
echo "原始文件大小: $(wc -c < "$INPUT_FILE") 字节" >> "$LOG_FILE"

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
    echo -e "\n🔄 第 ${attempt} 次尝试" | tee -a "$LOG_FILE"
    
    # 生成随机参数
    SEED=$RANDOM
    THRESHOLD=$(awk -v min=0.2 -v max=0.8 'BEGIN{srand(); printf "%.2f\n", min + rand()*(max-min)}')
    ENCODING=("none" "base64" "rc4")[$((RANDOM % 3))]

    # 生成布尔参数
    gen_bool() { (( RANDOM % 2 )) && echo "true" || echo "false"; }
    RENAME_GLOBALS=$(gen_bool)
    SIMPLIFY=$(gen_bool)
    TRANSFORM_KEYS=$(gen_bool)

    # 记录参数
    cat <<EOF | tee -a "$LOG_FILE"
⚙️ 参数配置:
---------------------------------
| 随机种子          | $SEED
| 字符串阈值        | $THRESHOLD
| 编码方式          | $ENCODING
| 重命名全局变量     | $RENAME_GLOBALS
| 简化代码          | $SIMPLIFY
| 转换对象键        | $TRANSFORM_KEYS
---------------------------------
EOF

    # 执行混淆命令
    javascript-obfuscator "$INPUT_FILE" \
        --output "$OUTPUT_FILE" \
        --compact true \
        --identifier-names-generator hexadecimal \
        --seed "$SEED" \
        --string-array true \
        --string-array-threshold "$THRESHOLD" \
        --string-array-encoding "$ENCODING" \
        --rename-globals "$RENAME_GLOBALS" \
        --simplify "$SIMPLIFY" \
        --transform-object-keys "$TRANSFORM_KEYS" || {
            echo "❌ 混淆命令执行失败" | tee -a "$LOG_FILE"
            exit 1
        }

    # 验证输出文件
    FILESIZE=$(wc -c < "$OUTPUT_FILE")
    echo "📦 生成文件大小: $((FILESIZE / 1024)) KB" | tee -a "$LOG_FILE"

    if [ "$FILESIZE" -le "$MAX_SIZE" ]; then
        echo "✅ 符合大小要求" | tee -a "$LOG_FILE"
        exit 0
    else
        echo "⚠️ 文件过大，准备重试..." | tee -a "$LOG_FILE"
        rm -f "$OUTPUT_FILE"
    fi
done

echo "🛑 已达最大尝试次数 ${MAX_ATTEMPTS} 次" | tee -a "$LOG_FILE"
exit 1
