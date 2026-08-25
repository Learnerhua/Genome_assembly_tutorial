#!/usr/bin/env bash
# =============================================================================
# Illumina PE150 质控脚本（酿酒酵母 S288C, ERR1938683）
# =============================================================================
# 工具：fastp 1.0.1
# 输入：rawData/ERR1938683_{1,2}.fastq.gz（PE150, ~438 MB）
# 输出：rawData/clean/{ERR1938683_1.clean.fq.gz, ERR1938683_2.clean.fq.gz}
#       rawData/clean/quality_report.{json,html}
# 用法：cd rawData && bash run_fastp_qc.sh
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="48"
OUT_DIR="$SCRIPT_DIR/clean"
REPORT_NAME="quality_report"

# 输入 / 输出路径
R1_IN="$SCRIPT_DIR/ERR1938683_1.fastq.gz"
R2_IN="$SCRIPT_DIR/ERR1938683_2.fastq.gz"
R1_OUT="$OUT_DIR/ERR1938683_1.clean.fq.gz"
R2_OUT="$OUT_DIR/ERR1938683_2.clean.fq.gz"
JSON_OUT="$OUT_DIR/${REPORT_NAME}.json"
HTML_OUT="$OUT_DIR/${REPORT_NAME}.html"
LOG_OUT="$OUT_DIR/${REPORT_NAME}.log"

# fastp 路径
FASTP="${CONDA_ENVS}/old_base/bin/fastp"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$FASTP" ]] || { echo "[ERROR] fastp 不存在或不可执行: $FASTP"; exit 1; }
[[ -f "$R1_IN" ]] || { echo "[ERROR] 缺失 R1: $R1_IN"; exit 1; }
[[ -f "$R2_IN" ]] || { echo "[ERROR] 缺失 R2: $R2_IN"; exit 1; }

mkdir -p "$OUT_DIR"

echo "============================================================"
echo "fastp 质控启动"
echo "  线程数: $THREADS"
echo "  fastp 版本: $('$FASTP' --version 2>&1)"
echo "  输入:"
echo "    R1: $R1_IN"
echo "    R2: $R2_IN"
echo "  输出目录: $OUT_DIR"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# -----------------------------------------------------------------------------
# 运行 fastp
# --detect_adapter_for_pe: 自动检测并裁剪 Illumina PE adapter
# --correction: PE overlap 纠错（提高 K-mer 质量）
# -j / -h: 输出 JSON / HTML 报告
# --cut_front / --cut_tail: 切除 5'/3' 端低质量碱基（默认 Q<20）
# --cut_mean_quality 20: 滑动窗口均值 < 20 则裁剪
# --length_required 50: 过滤短于 50 bp 的 reads
# -w: 线程数
# -----------------------------------------------------------------------------
START=$(date +%s)
"$FASTP" \
    -i "$R1_IN" \
    -I "$R2_IN" \
    -o "$R1_OUT" \
    -O "$R2_OUT" \
    --detect_adapter_for_pe \
    --correction \
    --cut_front \
    --cut_tail \
    --cut_mean_quality 20 \
    --length_required 50 \
    -j "$JSON_OUT" \
    -h "$HTML_OUT" \
    -w "$THREADS" \
    > "$LOG_OUT" 2>&1
EXIT_CODE=$?
END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 标准 gzip 重压缩（关键步骤）
# -----------------------------------------------------------------------------
# SOAPdenovo2（2012 年）的 gzip 读取器与 fastp 输出的 gzip 流不兼容，
# 会导致只读取 ~0.3% 的 reads。必须用标准 gzip 重新压缩。
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "标准 gzip 重压缩（SOAPdenovo2 兼容性）..."
    zcat "$R1_OUT" > "${R1_OUT%.gz}.tmp" && gzip -f "${R1_OUT%.gz}.tmp" && mv "${R1_OUT%.gz}.tmp.gz" "$R1_OUT"
    zcat "$R2_OUT" > "${R2_OUT%.gz}.tmp" && gzip -f "${R2_OUT%.gz}.tmp" && mv "${R2_OUT%.gz}.tmp.gz" "$R2_OUT"
    gzip -t "$R1_OUT" && echo "  R1 重压缩后 gzip OK"
    gzip -t "$R2_OUT" && echo "  R2 重压缩后 gzip OK"
fi

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "============================================================"
    echo "fastp 质控完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物:"
    echo "  $R1_OUT (标准 gzip，兼容 SOAPdenovo2)"
    echo "  $R2_OUT (标准 gzip，兼容 SOAPdenovo2)"
    echo "  $JSON_OUT (机读报告)"
    echo "  $HTML_OUT (可视化报告)"
    echo "  $LOG_OUT (运行日志)"
    echo ""
    echo "后续使用：将 4 个 SPAdes 脚本 (run_illumina_*.sh) 中的 R1/R2 路径改为"
    echo "  $R1_OUT"
    echo "  $R2_OUT"
    echo "============================================================"
else
    echo "[ERROR] fastp 失败 - exit code $EXIT_CODE"
    echo "  查看: $LOG_OUT (tail)"
    tail -20 "$LOG_OUT" >&2
    exit $EXIT_CODE
fi