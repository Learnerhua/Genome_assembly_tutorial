#!/usr/bin/env bash
# =============================================================================
# BUSCO 可视化脚本 - 生成 BUSCO 评估图
# =============================================================================
# 目的：用 BUSCO 自带的 generate_plot 功能给评估结果画图
# 工具：BUSCO 6.1.0 的 --plot 子命令（无需额外工具）
# 产出：busco_figure.png（横向条形图，展示各组装的 C/F/M/S/D）
# =============================================================================
# 用法：bash run_busco_plot.sh [BUSCO 运行根目录]
#   默认：从 run_busco.sh 输出的 run_saccharomycetaceae_odb12.2/busco_nextdenovo/
#         也就是 ./busco_nextdenovo/
#   注意：BIOINFORMATICS --plot 会扫描【当前目录】的 short_summary.*.json
#         所以必须 cd 到 busco_xxx 输出目录再跑
# =============================================================================

set -uo pipefail

# 确保 BUSCO 工具链在 PATH 中（与 run_busco_inner.sh 同样的设置）
export PATH="${BUSCO_BIN}:$PATH"
BUSCO_PYTHONPATH="${BUSCO_ENV}/lib/python3.12/site-packages"
export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}${BUSCO_PYTHONPATH}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# BUSCO 评估输出目录（包含 short_summary.*.json 的目录）
# 参数1：可自定义；默认是 run_busco.sh 的标准输出路径
# 注意：BIOINFORMATICS --plot 会扫描该目录的 short_summary JSON
# （嵌套子目录里的不会被扫描——必须是最直接子目录）
BUSCO_OUTPUT_DIR="${1:-$SCRIPT_DIR/run_saccharomycetaceae_odb12.2/busco_nextdenovo}"

# =============================================================================
# 前置检查
# =============================================================================
[[ -x "$(which busco 2>/dev/null)" ]] || {
    export PATH="${BUSCO_BIN}:$PATH"
    [[ -x "$(which busco 2>/dev/null)" ]] || {
        echo "[ERROR] busco 不在 PATH，请检查 conda 环境"
        exit 1
    }
}

[[ -d "$BUSCO_OUTPUT_DIR" ]] || {
    echo "[ERROR] BUSCO 输出目录不存在: $BUSCO_OUTPUT_DIR"
    echo "请先运行：bash run_busco.sh 生成评估结果"
    exit 1
}

# 检查是否有 short_summary JSON（plot 必读）
JSON_COUNT=$(find "$BUSCO_OUTPUT_DIR" -maxdepth 1 -name 'short_summary*.json' 2>/dev/null | wc -l)
if [[ $JSON_COUNT -eq 0 ]]; then
    echo "[ERROR] $BUSCO_OUTPUT_DIR 下找不到 short_summary*.json"
    echo "BUSCO 评估可能未完成或目录结构不对"
    exit 1
fi

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "BUSCO 可视化启动"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  BUSCO: $(busco --version 2>&1 | head -1 || echo 'busco --version 报错')"
echo "  输出目录: $BUSCO_OUTPUT_DIR"
echo "  找到 $JSON_COUNT 个 short_summary JSON"
echo "============================================================"

# =============================================================================
# 生成 BUSCO 图
# =============================================================================
# busco --plot <dir> 会扫描 <dir> 下的所有 short_summary.*.json 文件
# 生成 busco_figure.png（多组装时为多页 PDF/PNG）
# -----------------------------------------------------------------------------
# 关键参数：
#   --plot DIR             必填，扫描该目录的 short_summary JSON
#   --plot_percentages     可选，画百分比而非计数（默认是计数）
# -----------------------------------------------------------------------------

cd "$BUSCO_OUTPUT_DIR"

# 确保日志目录存在（tee 写入需要）
mkdir -p "$BUSCO_OUTPUT_DIR/logs"
LOG_FILE="$BUSCO_OUTPUT_DIR/logs/busco_plot.log"

echo
echo "[CMD] cd $BUSCO_OUTPUT_DIR && busco --plot ."
echo

START=$(date +%s)
# 关键：必须传 "." 而不是再次传完整路径——
# BUSCO 把 --plot 的参数当作输出目录（results_dir），
# 若传相对路径会叠加在 cd 后的位置，导致目录不存在报错
busco --plot . 2>&1 | tee "$LOG_FILE"
CODE=${PIPESTATUS[0]}
END=$(date +%s)
ELAPSED=$((END - START))

echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "BUSCO 可视化完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s"
    echo
    echo "产物: $BUSCO_OUTPUT_DIR/busco_figure.png"
    echo "      （横向条形图：X 轴=% BUSCOs，Y 轴=各组装）"
    echo "      颜色含义：浅蓝=Single-copy，深蓝=Duplicated，黄=Fragmented，红=Missing"
    echo "============================================================"
else
    echo "BUSCO 可视化失败 (exit $CODE)"
    echo "日志: $BUSCO_OUTPUT_DIR/busco_plot.log"
    exit $CODE
fi