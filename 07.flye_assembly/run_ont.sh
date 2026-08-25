#!/usr/bin/env bash
# =============================================================================
# Flye 组装脚本 - ONT（Oxford Nanopore）
# =============================================================================
# 数据：rawData/PRJEB19900/ont_merged.fastq.gz（ONT, 192 MB, 79,160 reads）
# 目的：演示 Flye 对 ONT 数据的组装（重复图算法 + 内置纠错）
# =============================================================================
# 用法：bash run_ont.sh            # 默认 48 线程
#       bash run_ont.sh 16         # 自定义线程数
#
# Flye 流程（自动多阶段）：
#   1. 纠错（repeat graph 构建前的 reads 纠错）
#   2. 组装（de Bruijn graph → 重复图）
#   3. 一致性校正（polish）
# 输入：--nano-raw（未纠错的原始 ONT reads，Flye 自带纠错）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.ont"
OUT_DIR="$SCRIPT_DIR/$SCHEME_NAME/out"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据路径
ONT="${REPO_ROOT}/rawData/PRJEB19900/ont_merged.fastq.gz"

# Flye 路径
FLYE="${DATA_ROOT}/Download/Flye/bin/flye"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$FLYE" ]] || { echo "[ERROR] flye 未找到: $FLYE"; exit 1; }
[[ -f "$ONT" ]] || { echo "[ERROR] 缺失 ONT: $ONT"; exit 1; }

mkdir -p "$OUT_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "Flye 组装启动 - ONT"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  数据:"
    echo "    ONT: $ONT"
    echo "  输出目录: $OUT_DIR"
    echo "  日志: $LOG_DIR/flye.log"
    echo "============================================================"
} | tee "$LOG_DIR/flye_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 运行 Flye
# --nano-raw: 未纠错的原始 ONT reads（Flye 内部先纠错再组装）
# --out-dir:  输出目录（必须不存在或为空，Flye 会拒绝覆盖）
# --threads:  线程数
# --genome-size: 预估基因组大小（帮助纠错参数选择）
# --iterations:  polish 轮数（默认 1；注意这不是纠错轮数，纠错由 Flye 内部完成）
# -----------------------------------------------------------------------------
echo ""
echo "[Flye] 启动 $(date '+%H:%M:%S')"
"$FLYE" \
    --nano-raw "$ONT" \
    --out-dir "$OUT_DIR" \
    --threads "$THREADS" \
    --genome-size 12.1m \
    > "$LOG_DIR/flye.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] Flye 失败 (exit $EXIT_CODE)"; tail -30 "$LOG_DIR/flye.log" >&2; exit 2; }
echo "[Flye] 完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "Flye 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    echo "  assembly.fasta         最终组装序列（主要产物）"
    echo "  assembly_graph.gfa      组装图（GFA 格式）"
    echo "  contigs_stats.txt       contig 统计"
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py $OUT_DIR/assembly.fasta"
    echo "============================================================"
} | tee -a "$LOG_DIR/flye_startup.log"