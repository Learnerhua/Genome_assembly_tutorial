#!/usr/bin/env bash
# =============================================================================
# dotPlotly 共线性分析脚本
# =============================================================================
# 目的：对全部 13 个组装结果与酵母参考基因组（S288C, Ensembl R64-1-1）
#       做共线性 dot plot 可视化。
#
# 工具链：
#   1. minimap2：组装 vs 参考 → PAF 文件
#   2. dotPlotly/pafCoordsDotPlotly.R：PAF → 共线性 dot plot (交互式 + 静态)
#
# 输入：
#   - 参考基因组：rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
#   - 全部 13 个组装 FASTA（详见下方 ASSEMBLIES 数组）
#
# 输出（每组：
#   - {prefix}.paf        minimap2 比对结果
#   - {prefix}.html       交互式 dot plot（plotly）
#   - {prefix}.png        静态 dot plot
#   - {prefix}.pdf        静态 dot plot
#   命名：{方法}_{query}.{ext}，体现方法 + query 名称
# =============================================================================
# 用法：bash run_dotplotly.sh            # 默认 48 线程
# 依赖：conda 环境 old_base（已含 optparse / ggplot2 / plotly）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
OUT_DIR="$SCRIPT_DIR/01.paf"
LOG_DIR="$SCRIPT_DIR/logs"

# 工具路径
MINIMAP2="${DATA_ROOT}/Download/minimap2/minimap2"
DOTPLOTLY_DIR="${DATA_ROOT}/Download/dotPlotly"
RSCRIPT="${CONDA_ENVS}/old_base/bin/Rscript"

# 参考基因组（解压后的 path）
# 路径相对于 SCRIPT_DIR 的父目录（即项目根），方便从任意目录调用
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REF="${PROJECT_ROOT}/rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"

# 全部 13 个组装（覆盖所有数据类型）
# 命名 = 方法名（输出文件会包含方法名以区分）
ASSEMBLIES=(
    "soapdenovo2:${PROJECT_ROOT}/02.soapdenovo2_assembly/out/scer.scafSeq"
    "spades_illumina:${PROJECT_ROOT}/03.spades_assembly/01.illumina_only/scaffolds.fasta"
    "spades_hifi:${PROJECT_ROOT}/03.spades_assembly/02.illumina_hifi/scaffolds.fasta"
    "spades_clr:${PROJECT_ROOT}/03.spades_assembly/03.illumina_clr/scaffolds.fasta"
    "spades_ont:${PROJECT_ROOT}/03.spades_assembly/04.illumina_ont/scaffolds.fasta"
    "canu_purge:${PROJECT_ROOT}/04.canu_assembly/01.hifi/purged/purged.fa"
    "wtdbg2:${PROJECT_ROOT}/05.wtdbg2_assembly/01.clr/scer.cns.fa"
    "nextdenovo:${PROJECT_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta"
    "flye:${PROJECT_ROOT}/07.flye_assembly/01.ont/out/10-consensus/consensus.fasta"
    "mecat2:${PROJECT_ROOT}/08.mecat2_assembly/01.clr/work/4-fsa/contigs.fasta"
    "necat:${PROJECT_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/bridged_contigs.fasta"
    "hifiasm:${PROJECT_ROOT}/10.hifiasm_assembly/01.hifi/scer.bp.p_ctg.fasta"
    "quickmerge:${PROJECT_ROOT}/11.quickmerge_assembly/01.merge/merged_merge_ND.fasta"
)

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$MINIMAP2" ]] || { echo "[ERROR] minimap2 未找到: $MINIMAP2（见 6.1.10）"; exit 1; }
[[ -x "$RSCRIPT" ]] || { echo "[ERROR] Rscript 未找到: $RSCRIPT"; exit 1; }
[[ -f "$REF" ]] || { echo "[ERROR] 缺失参考基因组: $REF"; exit 1; }
[[ -f "$DOTPLOTLY_DIR/pafCoordsDotPlotly.R" ]] || { echo "[ERROR] dotPlotly 脚本未找到: $DOTPLOTLY_DIR"; exit 1; }

# 检查 R 包
"$RSCRIPT" -e 'suppressPackageStartupMessages({library(optparse); library(ggplot2); library(plotly)}); cat("R packages OK\n")' \
    > /dev/null 2>&1 || {
    echo "[ERROR] R 包缺失：请检查 old_base 环境（应已含 optparse/ggplot2/plotly）";
    echo "  Rscript -e 'install.packages(\"optparse\")'"
    exit 1
}

mkdir -p "$OUT_DIR" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "dotPlotly 共线性分析启动"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  参考基因组: $REF"
    echo "  候选组装数: ${#ASSEMBLIES[@]}"
    echo "  输出目录: $OUT_DIR"
    echo "============================================================"
} | tee "$LOG_DIR/dotplotly_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 对每个组装分别跑 minimap2 → dotPlotly
# -----------------------------------------------------------------------------
run_one() {
    local method="$1"
    local query="$2"
    local prefix="${method}_$(basename "$query" .fasta | tr -c 'A-Za-z0-9' '_')"

    echo ""
    echo "[$method] minimap2 比对 $(date '+%H:%M:%S')"

    # 1. minimap2: 组装 vs 参考，输出 PAF（Pairwise mApping Format）
    # 参数说明：
    #   -x asm5      比对预设：本场景是组装 vs 同物种参考（asm5 ≈ 95-99% 相似度，
    #                 对应 yeast 这类近缘基因组比对，避免 snappy 过度敏感）
    #                 其他常用预设：map-pb（PacBio HiFi）、map-ont（ONT）、asm20（高差异基因组）
    #   -t N         线程数（本场景：48 核）
    #   "$REF"       参考基因组（gzip 自动识别）
    #   "$query"     query 组装
    # PAF 格式：每行一个比对，含 query/ref 名称、起始/终止、链方向、相似度等字段
    "$MINIMAP2" -x asm5 -t "$THREADS" \
        "$REF" "$query" \
        > "$OUT_DIR/${prefix}.paf" \
        2> "$LOG_DIR/minimap2_${method}.log"
    [[ $? -eq 0 ]] || { echo "[ERROR] minimap2 $method 失败"; exit 2; }
    echo "  ${prefix}.paf: $(wc -l < "$OUT_DIR/${prefix}.paf") 行"

    # 2. dotPlotly: PAF → 共线性可视化（HTML 交互式 + PNG/PDF 静态）
    # 参数说明：
    #   -i  PAF 文件名（由 minimap2 生成）
    #   -o  输出前缀（产物为 <prefix>.html / .png / .pdf）
    #   -s  按相似度上色（color scale：不同颜色代表不同% identity，便于直观看出
    #       保守与差异区域）
    #   -t  只算 on-target 比对的 identity（% identity on aligned target only）
    #       即 query 与对应参考区段正向比对时的相似度
    #   -m  最小比对段长度（bp），过滤单段短比对。本场景 10000（脚本默认值），过滤
    #       短噪声比对、保留真实大片段。注意：dotPlotly README 文档示例写的 500 与
    #       代码默认 10000 不一致，以代码默认为准
    #   -q  最小 query 比对总长（bp），过滤短的 query 比对累积。本场景 10 Kb 表示
    #       只保留总长 ≥ 10 Kb 的 query（仅过滤碎片比对，保留几乎所有 contig）
    #   -k  保留的前 N 个参考染色体。本场景 16 = 保留酵母全部 16 条染色体（chr I-XVI）
#       注：Ensembl R64-1-1 还有 1 条线粒体，本场景过滤掉，只关注核染色体
    #   -l  显示水平分隔线（separating scaffolds on plot），按染色体边界画线
    echo "[$method] dotPlotly 可视化 $(date '+%H:%M:%S')"
    cd "$OUT_DIR"
    "$RSCRIPT" "$DOTPLOTLY_DIR/pafCoordsDotPlotly.R" \
        -i "${prefix}.paf" \
        -o "${prefix}" \
        -s -t -m 10000 -q 10000 -k 16 -l \
        > "$LOG_DIR/dotplotly_${method}.log" 2>&1
    [[ $? -eq 0 ]] || { echo "[ERROR] dotPlotly $method 失败"; tail -20 "$LOG_DIR/dotplotly_${method}.log" >&2; exit 3; }
    echo "  产物: ${prefix}.html / ${prefix}.png / ${prefix}.pdf"
}

for spec in "${ASSEMBLIES[@]}"; do
    method="${spec%%:*}"
    query="${spec##*:}"
    [[ -f "$query" ]] || { echo "[ERROR] 缺失 query: $query"; exit 4; }
    run_one "$method" "$query"
done

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "dotPlotly 共线性分析完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    echo "  PAF 文件（minimap2 比对结果）:"
    for spec in "${ASSEMBLIES[@]}"; do
        method="${spec%%:*}"
        query="${spec##*:}"
        prefix="${method}_$(basename "$query" .fasta | tr -c 'A-Za-z0-9' '_')"
        echo "    ${prefix}.paf"
    done
    echo ""
    echo "  共线性图（HTML/PNG/PDF，每个方法三份）:"
    for spec in "${ASSEMBLIES[@]}"; do
        method="${spec%%:*}"
        query="${spec##*:}"
        prefix="${method}_$(basename "$query" .fasta | tr -c 'A-Za-z0-9' '_')"
        echo "    ${prefix}.html / ${prefix}.png / ${prefix}.pdf"
    done
    echo ""
    echo "打开交互式: xdg-open $OUT_DIR/*.html"
    echo "============================================================"
} | tee -a "$LOG_DIR/dotplotly_startup.log"