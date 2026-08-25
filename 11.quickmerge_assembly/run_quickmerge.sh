#!/usr/bin/env bash
# =============================================================================
# quickmerge 组装合并脚本 v2 - 最佳组合（NextDenovo × NECAT）
# =============================================================================
# 目的：演示 quickmerge 合并两个 ONT 组装（全项目 N50 最高 + 大小最准的两个）
#
# 输入（按"大小准的当 query + 连续性好的当 reference"原则选择）：
#   A: 06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta
#      （NextDenovo: N50 803K, 总长 12.12 Mb, 大小准确度 99.6% ← 全项目最准）
#   B: 09.necat_assembly/01.ont/work/6-bridge_contigs/bridged_contigs.fasta
#      （NECAT: N50 841K ← 全项目最高, 总长 12.09 Mb, 99.4%）
#
# 注意：实际项目应先用 QUAST/BUSCO 等专业工具评估各组装质量，
#       再决定选用哪些组装结果拿来合并；本实例仅演示工具用法。
# =============================================================================
# 用法：bash run_quickmerge.sh            # 默认 48 线程
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.merge"
OUT_DIR="$SCRIPT_DIR/$SCHEME_NAME"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入组装 A、B（A=NextDenovo, B=NECAT）
ASM_A="${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta"
ASM_B="${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/bridged_contigs.fasta"

# 两个方向的 query N50（-l 参数建议值：该方向 query 组装的 N50）
N50_A=803374    # NextDenovo 的 N50
N50_B=840809    # NECAT 的 N50

# 工具（conda genome_assembly 环境）
export PATH="${CONDA_PREFIX}/bin:$PATH"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
command -v quickmerge >/dev/null || { echo "[ERROR] quickmerge 不在 PATH（见 5.1.17）"; exit 1; }
command -v merge_wrapper.py >/dev/null || { echo "[ERROR] merge_wrapper.py 不在 PATH"; exit 1; }
[[ -f "$ASM_A" ]] || { echo "[ERROR] 缺失组装 A: $ASM_A"; exit 1; }
[[ -f "$ASM_B" ]] || { echo "[ERROR] 缺失组装 B: $ASM_B"; exit 1; }

mkdir -p "$OUT_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "quickmerge 组装合并启动 v2（NextDenovo × NECAT 双向）"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  组装 A: NextDenovo（N50 $N50_A, 99.6%）"
    echo "  组装 B: NECAT（N50 $N50_B, 99.4%）"
    echo "  输出目录: $OUT_DIR"
    echo "============================================================"
} | tee "$LOG_DIR/quickmerge_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 运行 merge_wrapper.py（自动 nucmer → delta-filter → quickmerge）
# -----------------------------------------------------------------------------
run_direction() {
    local label="$1" query="$2" ref="$3" q_n50="$4"
    echo ""
    echo "[quickmerge] 方向 $label：query=$(basename "$query"), reference=$(basename "$ref") $(date '+%H:%M:%S')"
    cd "$OUT_DIR"
    merge_wrapper.py \
        -pre "$label" \
        -hco 5.0 \
        -c 1.5 \
        -l "$q_n50" \
        -ml 5000 \
        "$query" "$ref" \
        > "$LOG_DIR/quickmerge_${label}.log" 2>&1
    local code=$?
    [[ $code -eq 0 ]] || { echo "[ERROR] 方向 $label 失败 (exit $code)"; tail -30 "$LOG_DIR/quickmerge_${label}.log" >&2; exit 2; }
    echo "[quickmerge] 方向 $label 完成"
}

run_direction "merge_ND" "$ASM_A" "$ASM_B" "$N50_A"   # query=NextDenovo, ref=NECAT
run_direction "merge_NC" "$ASM_B" "$ASM_A" "$N50_B"   # query=NECAT, ref=NextDenovo

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报 + 双向统计对比
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "quickmerge 组装合并完成 v2（双向）"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    echo "  merged_merge_ND.fasta  方向1 合并（query=NextDenovo）"
    echo "  merged_merge_NC.fasta  方向2 合并（query=NECAT）"
    echo ""
    echo "双向对比（取 N50 更高且总长更接近参考者）:"
    echo "============================================================"
} | tee -a "$LOG_DIR/quickmerge_startup.log"

STATS_PY="${REPO_ROOT}/03.spades_assembly/assembly_stats.py"

python3 "$STATS_PY" \
    --label "merge_ND (query=NextDenovo)" "$OUT_DIR/merged_merge_ND.fasta" 2>/dev/null \
    | tee -a "$LOG_DIR/quickmerge_startup.log"
python3 "$STATS_PY" \
    --label "merge_NC (query=NECAT)" "$OUT_DIR/merged_merge_NC.fasta" 2>/dev/null \
    | tee -a "$LOG_DIR/quickmerge_startup.log"