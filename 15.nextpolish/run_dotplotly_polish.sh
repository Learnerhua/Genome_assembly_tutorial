#!/usr/bin/env bash
# =============================================================================
# dotPlotly 共线性分析脚本（NextPolish 抛光后的组装）
# =============================================================================
# 目的：将 NextPolish 抛光后的基因组与酵母参考做共线性 dot plot，
#       评估抛光是否改变了基因组结构（应保持与参考的共线性）
#
# 工具链：
#   1. minimap2：组装 vs 参考 → PAF 文件
#   2. dotPlotly/pafCoordsDotPlotly.R：PAF → 共线性 dot plot
#
# 输入：
#   - 抛光后 FASTA：15.nextpolish/genome.nextpolish.fasta（19 contigs）
#   - 参考基因组：rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz（17 条：16 核 + 1 线粒体）
#
# 输出：
#   - 15.nextpolish/dotplotly_result/nextpolish.paf
#   - 15.nextpolish/dotplotly_result/nextpolish.html
#   - 15.nextpolish/dotplotly_result/nextpolish.png
# =============================================================================
# 用法：bash run_dotplotly_polish.sh
# =============================================================================

set -uo pipefail

# 用 BASH_SOURCE 拿脚本绝对路径（兼容 bash run_dotplotly_polish.sh 调用方式）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
THREADS="${1:-48}"

# 输出目录（产物直接放在 dotplotly_result/，与 logs/ 同级）
OUT_DIR="$SCRIPT_DIR"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$OUT_DIR" "$LOG_DIR"

# 工具路径
MINIMAP2="${DATA_ROOT}/Download/minimap2/minimap2"
DOTPLOTLY_DIR="${DATA_ROOT}/Download/dotPlotly"
RSCRIPT="${CONDA_ENVS}/old_base/bin/Rscript"

# 挂载后的 scaffold FASTA（Hi-C 挂载产物）
SCAFFOLD_ASM="$SCRIPT_DIR/genome.nextpolish.fasta"

# 参考基因组
REF="$PROJECT_ROOT/rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"

# 输出前缀
PREFIX="nextpolish"

# =============================================================================
# 前置检查
# =============================================================================
[[ -f "$SCAFFOLD_ASM" ]] || { echo "[ERROR] 抛光后 FASTA 不存在: $SCAFFOLD_ASM（先跑 6.18 NextPolish）"; exit 1; }
[[ -f "$REF" ]] || { echo "[ERROR] 参考基因组不存在: $REF"; exit 1; }
[[ -x "$MINIMAP2" ]] || { echo "[ERROR] minimap2 未找到: $MINIMAP2"; exit 1; }
[[ -f "$DOTPLOTLY_DIR/pafCoordsDotPlotly.R" ]] || { echo "[ERROR] dotPlotly 脚本未找到: $DOTPLOTLY_DIR"; exit 1; }

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "dotPlotly 共线性分析（Hi-C 挂载后 scaffold）"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Query (scaffold): $SCAFFOLD_ASM"
echo "  Ref:             $REF"
echo "  线程:            $THREADS"
echo "  输出:            $OUT_DIR"
echo "============================================================"

cd "$OUT_DIR"
START=$(date +%s)

# =============================================================================
# Step 1: minimap2 比对
# =============================================================================
# 关键参数：
#   -x asm5    同物种组装的比对预设（≈ 95-99% 相似度，yeast 这种近缘适用）
#   -t 48      线程数
echo ""
echo ">>> [1/2] minimap2 比对（scaffold vs ref）..."
"$MINIMAP2" -x asm5 -t "$THREADS" \
    "$REF" "$SCAFFOLD_ASM" \
    > "$OUT_DIR/${PREFIX}.paf" \
    2> "$LOG_DIR/minimap2.log"
[[ $? -eq 0 ]] || { echo "[ERROR] minimap2 失败"; exit 2; }
echo "  ✓ ${PREFIX}.paf: $(wc -l < "$OUT_DIR/${PREFIX}.paf") 行"

# =============================================================================
# Step 2: dotPlotly 可视化
# =============================================================================
# 关键参数：
#   -i  PAF 输入
#   -o  输出前缀
#   -s  按相似度上色
#   -t  显示 query 标题
#   -m 10000  最小比对段长度（bp），过滤短噪声
#   -q 10000  最小 query 总比对长（bp）
#   -k 16  保留 16 条核染色体（过滤线粒体）
#   -l  显示 scaffold 分隔线
echo ""
echo ">>> [2/2] dotPlotly 可视化..."
"$RSCRIPT" "$DOTPLOTLY_DIR/pafCoordsDotPlotly.R" \
    -i "$OUT_DIR/${PREFIX}.paf" \
    -o "$OUT_DIR/${PREFIX}" \
    -s -t -m 10000 -q 10000 -k 16 -l \
    > "$LOG_DIR/dotplotly.log" 2>&1
[[ $? -eq 0 ]] || { echo "[ERROR] dotPlotly 失败"; tail -20 "$LOG_DIR/dotplotly.log" >&2; exit 3; }

END=$(date +%s)
ELAPSED=$((END - START))

echo ""
echo "============================================================"
echo "dotPlotly 完成"
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  耗时: ${ELAPSED}s"
echo
echo "  产物:"
echo "    $OUT_DIR/${PREFIX}.paf    minimap2 比对"
echo "    $OUT_DIR/${PREFIX}.html   交互式 dot plot（浏览器）"
echo "    $OUT_DIR/${PREFIX}.png    静态 dot plot（300 dpi）"
echo "============================================================"