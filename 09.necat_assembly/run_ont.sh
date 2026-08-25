#!/usr/bin/env bash
# =============================================================================
# NECAT 组装脚本 - ONT（Oxford Nanopore）
# =============================================================================
# 数据：rawData/PRJEB19900/ont_merged.fastq.gz（ONT, 192 MB, 79,160 reads）
# 目的：演示 NECAT 对 ONT 数据的组装（自适应纠错 + bridging）
# =============================================================================
# 用法：bash run_ont.sh            # 默认 48 线程
#       bash run_ont.sh 16         # 自定义线程数
#
# NECAT 流程（配置文件驱动，4 阶段）：
#   1. PREP:  reads 预处理（覆盖度采样）
#   2. CNS:   纠错（错误率模型 + overlap）
#   3. ASM:   组装（overlap → 字符串图 → contig）
#   4. BRIDGE: contig 桥接（基于 paired-end 风格）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.ont"
CFG_BASE="$SCRIPT_DIR/$SCHEME_NAME"
CFG="$CFG_BASE/run.cfg"
READ_LIST="$CFG_BASE/ont_read_list.txt"
OUT_DIR="$SCRIPT_DIR/logs"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
command -v necat.pl >/dev/null || { echo "[ERROR] necat.pl 不在 PATH（见 5.1.15）"; exit 1; }
[[ -f "$CFG" ]] || { echo "[ERROR] 缺失配置文件: $CFG"; exit 1; }
[[ -f "$READ_LIST" ]] || { echo "[ERROR] 缺失 reads 文件列表: $READ_LIST"; exit 1; }

mkdir -p "$OUT_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "NECAT 组装启动 - ONT"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  配置: $CFG"
    echo "  reads 文件列表: $READ_LIST"
    echo "  日志: $OUT_DIR/necat.log"
    echo "============================================================"
} | tee "$OUT_DIR/necat_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 替换配置中的线程数（用户传参优先）
# 注意：NECAT 有 THREADS + GRID_NODE 两个并行参数
# -----------------------------------------------------------------------------
TMP_CFG=$(mktemp)
sed "s/^THREADS=.*/THREADS=$THREADS/" "$CFG" > "$TMP_CFG"

# -----------------------------------------------------------------------------
# 运行 NECAT 四阶段（顺序：correct → assemble → bridge）
# 注意：NECAT 配置文件里 PROJECT= 决定了每阶段输出目录
# -----------------------------------------------------------------------------
echo "[NECAT] 启动 $(date '+%H:%M:%S')"

cd "$CFG_BASE"
necat.pl correct "$TMP_CFG" \
    > "$OUT_DIR/necat_correct.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] correct 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/necat_correct.log" >&2; exit 2; }

necat.pl assemble "$TMP_CFG" \
    > "$OUT_DIR/necat_assemble.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] assemble 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/necat_assemble.log" >&2; exit 3; }

necat.pl bridge "$TMP_CFG" \
    > "$OUT_DIR/necat_bridge.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] bridge 阶段失败 (exit $EXIT_CODE)"; tail -30 "$OUT_DIR/necat_bridge.log" >&2; exit 4; }

rm -f "$TMP_CFG"
echo "[NECAT] 三阶段全部完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "NECAT 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（\$PROJECT/ 中查找，详见各阶段日志）:"
    echo "  work/1-cns/cns.fasta     纠错 reads（correct 产物）"
    echo "  work/4-asm/ctg.fasta     组装 contigs（assemble 产物）"
    echo "  work/5-bridge/ctg.fasta  桥接后 contigs（bridge 产物）"
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py work/5-bridge/ctg.fasta"
    echo "============================================================"
} | tee -a "$OUT_DIR/necat_startup.log"