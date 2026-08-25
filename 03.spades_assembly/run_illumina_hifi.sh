#!/usr/bin/env bash
# =============================================================================
# SPAdes 组装脚本 - 方案 2：Illumina + PacBio HiFi（推荐）
# =============================================================================
# 数据：
#   - rawData/ERR1938683_{1,2}.fastq.gz（Illumina MiSeq PE150）
#   - rawData/SRR13577847_subreads.fastq.gz（PacBio HiFi/CCS, ~569 MB）
# 目的：短读长纠错 + HiFi 长读长跨重复 → 现代最佳实践
# =============================================================================
# 用法：bash run_illumina_hifi.sh            # 默认 48 线程
#       bash run_illumina_hifi.sh 16         # 自定义线程数
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="02.illumina_hifi"
OUT_DIR="$SCRIPT_DIR/$SCHEME_NAME"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据路径
R1="${REPO_ROOT}/rawData/clean/ERR1938683_1.clean.fq.gz"
R2="${REPO_ROOT}/rawData/clean/ERR1938683_2.clean.fq.gz"
HIFI="${REPO_ROOT}/rawData/SRR13577847_subreads.fastq.gz"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
command -v spades.py >/dev/null || { echo "[ERROR] spades.py 不在 PATH"; exit 1; }
[[ -f "$R1" ]] || { echo "[ERROR] 缺失 R1: $R1"; exit 1; }
[[ -f "$R2" ]] || { echo "[ERROR] 缺失 R2: $R2"; exit 1; }
[[ -f "$HIFI" ]] || { echo "[ERROR] 缺失 HiFi: $HIFI"; exit 1; }

mkdir -p "$OUT_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "SPAdes 组装启动 - 方案 2: Illumina + PacBio HiFi"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  数据:"
    echo "    R1: $R1 (fastp 质控后)"
    echo "    R2: $R2 (fastp 质控后)"
    echo "    HiFi: $HIFI"
    echo "  输出目录: $OUT_DIR"
    echo "  日志目录: $LOG_DIR/illumina_hifi_spades.log"
    echo "============================================================"
} | tee "$LOG_DIR/illumina_hifi_startup.log"

# -----------------------------------------------------------------------------
# 运行 SPAdes（--pacbio 同时支持 HiFi 和 CLR；SPAdes 内部根据 read 长度自动选择策略）
# --careful: 多次迭代纠错
# -k 55,127: 双 K-mer（55=长读长常用，127=三代长读长最佳）
# -m 256: 内存上限 256 GB（酵母 14 Mb 足够，含三代数据）
# -t: 线程数
# -----------------------------------------------------------------------------
START=$(date +%s)
spades.py \
    -1 "$R1" \
    -2 "$R2" \
    --pacbio "$HIFI" \
    --careful \
    -t "$THREADS" \
    -k 55,127 \
    -m 256 \
    -o "$OUT_DIR" \
    > "$LOG_DIR/illumina_hifi_spades.log" 2>&1
EXIT_CODE=$?
END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
if [[ $EXIT_CODE -eq 0 ]]; then
    {
        echo "============================================================"
        echo "组装完成 - 方案 2"
        echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
        echo "  最终 contigs:  $OUT_DIR/contigs.fasta"
        echo "  最终 scaffolds: $OUT_DIR/scaffolds.fasta"
        echo "  详细日志: $LOG_DIR/illumina_hifi_spades.log"
        echo "============================================================"
    } | tee -a "$LOG_DIR/illumina_hifi_startup.log"
else
    {
        echo "============================================================"
        echo "[ERROR] SPAdes 失败 - exit code $EXIT_CODE"
        echo "  耗时: ${ELAPSED}s"
        echo "  查看: $LOG_DIR/illumina_hifi_spades.log (tail)"
        echo "============================================================"
    } | tee -a "$LOG_DIR/illumina_hifi_startup.log"
    tail -20 "$LOG_DIR/illumina_hifi_spades.log" >&2
    exit $EXIT_CODE
fi