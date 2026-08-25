#!/usr/bin/env bash
# =============================================================================
# NextDenovo 组装脚本 - ONT（Oxford Nanopore）
# =============================================================================
# 数据：rawData/PRJEB19900/ont_merged.fastq.gz（ONT, 192 MB, 79,160 reads）
# 目的：演示 NextDenovo 对 ONT 数据的快速组装（OLC-like + 多层纠错）
# =============================================================================
# 用法：bash run_ont.sh            # 默认 48 线程
#       bash run_ont.sh 16         # 自定义线程数
#
# NextDenovo 流程（配置文件驱动）：
#   1. 纠错阶段（correct）：minimap2 自比对 → 一致性纠错
#   2. 组装阶段（assemble）：nextgraph 构建字符串图 → 输出 consensus
# 输入：input.fofn（每行一个 reads 文件路径）
# 配置：run.cfg（[General] / [correct_option] / [assemble_option] 三段）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 配置文件（run.cfg）已按 48 线程校准：12 任务 × 4 线程/任务 ≈ 48
# 如果想自定义（调高/调低），只需改 run.cfg：
#   parallel_jobs         = 任务数
#   minimap2_options_raw  = -t 每任务线程数
#   parallel_jobs × minimap2_options_raw 的 -t 应 ≤ 机器核心数
THREADS="${1:-48}"
SCHEME_NAME="01.ont"
CFG_BASE="$SCRIPT_DIR/$SCHEME_NAME"
OUT_DIR="$CFG_BASE/out"
LOG_DIR="$SCRIPT_DIR/logs"
FOFN="$CFG_BASE/input.fofn"
CFG="$CFG_BASE/run.cfg"

# NextDenovo 路径
NEXTDENOVO="${DATA_ROOT}/Download/NextDenovo/nextDenovo"
# 关键：确保 genome_assembly conda 环境优先（nextDenovo 的 #!/usr/bin/env python
# 会按 PATH 找 python；若 /opt/conda 等系统 conda 在前面，会找不到 paralleltask）
export PATH="${CONDA_PREFIX}/bin:${DATA_ROOT}/Download/NextDenovo/bin:$PATH"
# 验证 python 解析正确
PY_BIN="$(command -v python)"
echo "  [check] python: $PY_BIN" | tee -a "$LOG_DIR/nextDenovo_startup.log" 2>/dev/null || true

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$NEXTDENOVO" ]] || { echo "[ERROR] nextDenovo 未找到: $NEXTDENOVO"; exit 1; }
[[ -f "$FOFN" ]] || { echo "[ERROR] 缺失 input.fofn: $FOFN"; exit 1; }
[[ -f "$CFG" ]] || { echo "[ERROR] 缺失配置文件: $CFG"; exit 1; }
[[ -s "$FOFN" ]] || { echo "[ERROR] input.fofn 为空"; exit 1; }

# 检查 paralleltask 是否在 nextDenovo 同一 Python 环境里
#（nextDenovo 安装在 conda 环境 genome_assembly，paralleltask 也必须在该环境）
python -c "import paralleltask" 2>/dev/null || {
    echo "[ERROR] paralleltask 未安装到当前 Python 环境"
    echo "        解决: conda activate genome_assembly && pip install paralleltask"
    exit 1
}

mkdir -p "$OUT_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "NextDenovo 组装启动 - ONT"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS (parallel_jobs)"
    echo "  数据:"
    echo "    fofn: $FOFN"
    echo "    配置: $CFG"
    echo "  输出目录: $OUT_DIR"
    echo "  日志: $LOG_DIR/nextDenovo.log"
    echo "============================================================"
} | tee "$LOG_DIR/nextDenovo_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 运行 NextDenovo（配置文件驱动）
# 注意：
#   - task = all（先 correct 再 assemble）
#   - workdir = out（输出目录在 01.ont 下，避免污染父目录）
#   - 默认会输出 final.fa（assemble 完成后的 consensus）
# -----------------------------------------------------------------------------
echo ""
echo "[NextDenovo] 启动 $(date '+%H:%M:%S')"
cd "$CFG_BASE"  # 在配置和 fofn 同目录下运行（nextDenovo 依赖相对路径）

"$NEXTDENOVO" run.cfg \
    > "$LOG_DIR/nextDenovo.log" 2>&1

EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] NextDenovo 失败 (exit $EXIT_CODE)"; tail -30 "$LOG_DIR/nextDenovo.log" >&2; exit 2; }
echo "[NextDenovo] 完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "NextDenovo 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    if [[ -f "$OUT_DIR/03.ctg_graph/nd.asm.fasta" ]]; then
        echo "  nd.asm.fasta        最终 consensus（主要产物）"
    elif [[ -f "$OUT_DIR/03.ctg_graph/assembly.fasta" ]]; then
        echo "  assembly.fasta      最终 consensus"
    else
        ls "$OUT_DIR/" 2>/dev/null | head -10
    fi
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py <输出 fasta>"
    echo "============================================================"
} | tee -a "$LOG_DIR/nextDenovo_startup.log"