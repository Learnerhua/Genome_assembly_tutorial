#!/usr/bin/env bash
# =============================================================================
# MECAT2 组装脚本 - PacBio CLR
# =============================================================================
# 数据：rawData/PRJEB7245/pacbio_clr_merged.fastq.gz（CLR, 2.3 GB, 490,396 reads）
# 目的：运行 MECAT2 三阶段流程（correct → trim → assemble）
# =============================================================================
# 用法：bash run_clr.sh            # 默认 48 线程
#       bash run_clr.sh 16         # 自定义线程数
#
# MECAT2 流程（配置文件驱动，3 阶段）：
#   1. correct:  纠错（k-mer overlap → 一致性）
#   2. trim:     修剪低质量区域 + 短 contig
#   3. assemble: 最终组装（overlap → 字符串图 → contig）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.clr"
CFG_BASE="$SCRIPT_DIR/$SCHEME_NAME"
CFG="$CFG_BASE/run.cfg"
OUT_DIR="$SCRIPT_DIR/logs"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
command -v mecat.pl >/dev/null || { echo "[ERROR] mecat.pl 不在 PATH（见 5.1.14）"; exit 1; }
[[ -f "$CFG" ]] || { echo "[ERROR] 缺失配置文件: $CFG"; exit 1; }

mkdir -p "$OUT_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "MECAT2 组装启动 - PacBio CLR"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  配置: $CFG"
    echo "  日志: $OUT_DIR/mecat2.log"
    echo "============================================================"
} | tee "$OUT_DIR/mecat2_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 替换配置中的线程数（用户传参优先）
# -----------------------------------------------------------------------------
TMP_CFG=$(mktemp)
sed "s/^THREADS=.*/THREADS=$THREADS/" "$CFG" > "$TMP_CFG"

# -----------------------------------------------------------------------------
# 运行 MECAT2 三阶段（顺序：correct → trim → assemble）
# 注意：MECAT2 配置文件里 PROJECT= 决定了每阶段输出目录
# -----------------------------------------------------------------------------
echo "[MECAT2] 启动 $(date '+%H:%M:%S')"

cd "$CFG_BASE"
mecat.pl correct "$TMP_CFG" \
    > "$OUT_DIR/mecat2_correct.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] correct 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/mecat2_correct.log" >&2; exit 2; }

mecat.pl trim "$TMP_CFG" \
    > "$OUT_DIR/mecat2_trim.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] trim 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/mecat2_trim.log" >&2; exit 3; }

mecat.pl assemble "$TMP_CFG" \
    > "$OUT_DIR/mecat2_assemble.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] assemble 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/mecat2_assemble.log" >&2; exit 4; }

rm -f "$TMP_CFG"
echo "[MECAT2] 三阶段全部完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "MECAT2 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（\$PROJECT/ 中查找，详见各阶段日志）:"
    echo "  work/1-cns/cns.fasta     纠错 reads（correct 产物）"
    echo "  work/3-trim/trim.fasta   修剪后 reads（trim 产物）"
    echo "  work/6-ctg_graph/ctg.fasta  最终组装 contigs（assemble 产物）"
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py work/6-ctg_graph/ctg.fasta"
    echo "============================================================"
} | tee -a "$OUT_DIR/mecat2_startup.log"