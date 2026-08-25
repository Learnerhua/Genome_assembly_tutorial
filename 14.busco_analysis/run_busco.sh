#!/usr/bin/env bash
# =============================================================================
# BUSCO 评估脚本 - nextdenovo 组装的基因完整性
# =============================================================================
# 目的：用 BUSCO 评估 yeast nextdenovo 组装的基因完整性
# 工具：BUSCO 6.1.0（独立 conda 环境）
# 数据：saccharomycetaceae_odb12.2 [3105]（酵母谱系，3105 个直系同源基因）
# =============================================================================
# 用法：bash run_busco.sh
# 数据集位于 ./busco_downloads/lineages/saccharomycetaceae_odb12.2/
# （已下载；离线模式直接评估）
# =============================================================================

set -uo pipefail

# 确保 BUSCO 依赖工具在 PATH 中（hmmsearch/blastp/prodigal/augustus 等）
# conda env 的 bin 在 PATH 中才能被 BUSCO 的 subprocess 找到
export PATH="${BUSCO_BIN}:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# busco 环境（conda-forge + bioconda 安装的独立环境）
BUSCO_PYTHON="${BUSCO_BIN}/python"

# 输入组装（nextdenovo ONT 拼接结果）
ASM="$PROJECT_ROOT/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta"

# BUSCO 谱系数据集（酵母科）
LINEAGE="saccharomycetaceae_odb12.2"

# BUSCO 下载目录（指向 14.busco_analysis/busco_downloads）
DOWNLOAD_DIR="$SCRIPT_DIR/busco_downloads"
OUTPUT_DIR="$SCRIPT_DIR/run_${LINEAGE}"
THREADS="${THREADS:-48}"

# 数据集路径（离线模式直接读）
LINEAGE_PATH="$DOWNLOAD_DIR/lineages/$LINEAGE"

# =============================================================================
# 前置检查
# =============================================================================
[[ -x "$BUSCO_PYTHON" ]] || { echo "[ERROR] BUSCO Python 未找到: $BUSCO_PYTHON"; exit 1; }
[[ -f "$ASM" ]] || { echo "[ERROR] nextdenovo 组装文件不存在: $ASM"; exit 1; }
[[ -d "$LINEAGE_PATH" ]] || { echo "[ERROR] 谱系数据集未找到: $LINEAGE_PATH"; exit 1; }
[[ -f "$LINEAGE_PATH/dataset.cfg" ]] || { echo "[ERROR] dataset.cfg 缺失: $LINEAGE_PATH/dataset.cfg"; exit 1; }
mkdir -p "$OUTPUT_DIR"

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "BUSCO 评估启动（离线模式）"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  BUSCO: $("$BUSCO_PYTHON" -c "import busco; print(busco.__version__ if hasattr(busco, '__version__') else 'OK')" 2>&1 | head -1)"
echo "  谱系: $LINEAGE"
echo "  线程数: $THREADS"
echo "  组装: $ASM"
echo "  输出目录: $OUTPUT_DIR"
echo "  下载目录: $DOWNLOAD_DIR"
echo "============================================================"

# =============================================================================
# BUSCO 调用（通过 Python API 绕开 bin/busco wrapper 的 bug）
# =============================================================================
# 注：bioconda 装的 BUSCO 6.1.0，bin/busco wrapper 错误地导入旧 API
# 直接调用 run_BUSCO.main() 是稳定的用法
# =============================================================================

cd "$SCRIPT_DIR"
START=$(date +%s)

# 直接调用 bin/busco 命令（用正确 PATH 让 wrapper 找到所有依赖）
# 不再需要内部 Python 包装脚本——wrapper 通过 PATH 自动定位 hmmsearch/blastp 等
"$SCRIPT_DIR/run_busco_inner.sh" \
    "$ASM" "$LINEAGE" "busco_nextdenovo" "$THREADS" "$OUTPUT_DIR" "$DOWNLOAD_DIR" \
    2>&1 | tee "$OUTPUT_DIR/busco.log"
CODE=${PIPESTATUS[0]}
END=$(date +%s)
ELAPSED=$((END - START))
echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "BUSCO 评估完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo
    echo "产物: $OUTPUT_DIR/busco_nextdenovo/"
    echo "      short_summary*.txt   ← 关键摘要（Complete/Duplicated/Fragmented/Missing）"
    echo "      full_table.tsv       ← 每个 BUSCO 基因的详细结果"
    echo "      hmmer_output/        ← HMMER 比对原始输出"
    echo "      busco_sequences/     ← 找到的 BUSCO 基因序列"
    echo "      prodigal_output/     ← 基因预测输出"
    echo "============================================================"
else
    echo "BUSCO 评估失败 (exit $CODE)"
    echo "日志: $OUTPUT_DIR/busco.log"
    exit $CODE
fi