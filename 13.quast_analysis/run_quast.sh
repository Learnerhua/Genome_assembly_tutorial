#!/usr/bin/env bash
# =============================================================================
# QUAST 评估脚本 - 4 种运行模式
# =============================================================================
# 目的：用 QUAST 评估组装质量，覆盖 4 种场景：
#   1. 单个基因组无参考
#   2. 单个基因组有参考
#   3. 全部基因组组装结果比较，无参考
#   4. 全部基因组组装结果比较，有参考
#
# 用法：bash run_quast.sh <mode> [options]
#   mode:
#     1   单个 + 无参考（默认示例：nextdenovo）
#     2   单个 + 有参考（默认示例：nextdenovo）
#     3   全部 + 无参考
#     4   全部 + 有参考
#   -a ASSEMBLY  指定单个组装的路径（仅 mode 1/2 用）
#   -p PREFIX    指定单个组装的方法名（仅 mode 1/2 用，决定输出目录名）
#   -t THREADS   线程数（默认 48）
#   -h           帮助
#
# 示例：
#   bash run_quast.sh 1                                    # nextdenovo 无参考
#   bash run_quast.sh 2                                    # nextdenovo 有参考
#   bash run_quast.sh 3                                    # 全部无参考
#   bash run_quast.sh 4                                    # 全部有参考
#   bash run_quast.sh 1 -a /path/to/asm.fa -p mecat2      # mecat2 无参考
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# QUAST 5.3.0 + Python 3.14 + joblib 多线程后端不兼容（loky/multiprocessing 均崩，
# 即使 -t 1 也走 joblib 的 Parallel）。用 --memory-efficient 让 QUAST 完全绕过
# joblib（真串行），13 个组装对比约 1-3 分钟，可接受
THREADS="${THREADS:-1}"

# QUAST 路径（绝对路径，含 wrapper 屏蔽 SyntaxWarning）
QUAST="${DATA_ROOT}/Download/quast/quast.sh"

# 参考基因组（Ensembl R64-1-1，酵母 S288C 16 + 1 条线粒体）
REF="${PROJECT_ROOT}/rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"

# 全部 13 个组装（统一管理）
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

# 默认示例（mode 1/2）：nextdenovo
DEFAULT_ASM_PATH="${PROJECT_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta"
DEFAULT_PREFIX="nextdenovo"

# 模式名 → 输出子目录映射
declare -A MODE_DIR=(
    [1]="01.single_no_ref"
    [2]="02.single_with_ref"
    [3]="03.compare_no_ref"
    [4]="04.compare_with_ref"
)

# -----------------------------------------------------------------------------
# 帮助
# -----------------------------------------------------------------------------
usage() {
    sed -n '/^# 目的/,/^# =============================================================================$/p' "$0" \
        | sed 's/^# //' | sed '/^================================================================/d'
    exit 0
}

# -----------------------------------------------------------------------------
# 参数解析
# -----------------------------------------------------------------------------
MODE=""
ASM_PATH=""
PREFIX="$DEFAULT_PREFIX"

while [[ $# -ge 1 ]]; do
    case "$1" in
        1|2|3|4)
            MODE="$1"
            shift
            ;;
        -a)
            ASM_PATH="$2"
            shift 2
            ;;
        -p)
            PREFIX="$2"
            shift 2
            ;;
        -t)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "[ERROR] 未知参数: $1" >&2
            usage
            ;;
    esac
done

if [[ -z "$MODE" ]]; then
    echo "[ERROR] 缺少 mode 参数（1/2/3/4）" >&2
    usage
fi

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$QUAST" ]] || { echo "[ERROR] QUAST wrapper 不存在: $QUAST"; exit 1; }
[[ -f "$REF" ]] || echo "[WARN] 参考基因组不存在（无参考模式自动忽略）: $REF"

OUT_DIR="$SCRIPT_DIR/${MODE_DIR[$MODE]}"
mkdir -p "$OUT_DIR/logs"
LOG_FILE="$OUT_DIR/logs/quast_${PREFIX}_mode${MODE}.log"

# 模式 3/4（对比）：每次清空旧产物（QUAST 5.3.0 + Python 3.14 有 joblib pickling 缓存冲突）
# 模式 1/2（单个）：保留旧产物，可作历史记录
if [[ "$MODE" == "3" || "$MODE" == "4" ]]; then
    if [[ -d "$OUT_DIR/all_report" ]]; then
        echo "[WARN] 清空旧产物: $OUT_DIR/all_report (QUAST 缓存冲突风险)"
        rm -rf "$OUT_DIR/all_report"
    fi
fi

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "QUAST 评估启动 (mode $MODE)"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  参考基因组: $REF"
    echo "  输出目录: $OUT_DIR"
    echo "  日志: $LOG_FILE"
    echo "============================================================"
} | tee "$LOG_FILE"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 模式 1 / 2：单个组装（默认 nextdenovo，可通过 -a/-p 覆盖）
# -----------------------------------------------------------------------------
run_single() {
    local with_ref="$1"   # 1 = 无参考, 2 = 有参考
    local asm="$ASM_PATH"
    local prefix="$PREFIX"

    # mode 1/2 默认用 nextdenovo（ASM_PATH 为空时取默认）
    [[ -z "$asm" ]] && asm="$DEFAULT_ASM_PATH"

    if [[ ! -f "$asm" ]]; then
        echo "[ERROR] 组装文件不存在: $asm" >&2
        exit 2
    fi

    echo "[QUAST] mode $with_ref: 单个 + $([[ $with_ref == 1 ]] && echo 无 || echo 有)参考"
    echo "  组装: $asm"
    echo "  方法名: $prefix"

    # --memory-efficient: 绕过 joblib 多进程（Python 3.14 兼容，见脚本头部注释）
    local cmd=("$QUAST" "$asm" --memory-efficient -t "$THREADS" -o "$OUT_DIR/${prefix}_report")
    if [[ "$with_ref" == 2 ]]; then
        cmd+=(-r "$REF")
        echo "  参考: $REF"
    fi

    echo "  命令: ${cmd[*]}"
    "${cmd[@]}" 2>&1 | tee -a "$LOG_FILE"
    local code=$?
    [[ $code -eq 0 ]] || { echo "[ERROR] QUAST 失败 (exit $code)"; exit 3; }
    echo "  → 产物: $OUT_DIR/${prefix}_report/report.html"
}

# -----------------------------------------------------------------------------
# 模式 3 / 4：全部组装对比
# -----------------------------------------------------------------------------
run_compare() {
    local with_ref="$1"   # 3 = 无参考, 4 = 有参考
    echo "[QUAST] mode $with_ref: 全部 + $([[ $with_ref == 3 ]] && echo 无 || echo 有)参考"
    echo "  组装数: ${#ASSEMBLIES[@]}"

    # 收集所有 fasta 路径 + 自定义 label（用方法名而非文件名）
    local fasta_args=()
    local labels=""
    for spec in "${ASSEMBLIES[@]}"; do
        local method="${spec%%:*}"
        local path="${spec##*:}"
        if [[ -f "$path" ]]; then
            fasta_args+=("$path")
            # QUAST 默认用文件名做 label，太长不易读——用 -l 覆盖（逗号分隔单字符串）
            if [[ -z "$labels" ]]; then
                labels="$method"
            else
                labels="$labels,$method"
            fi
            echo "  - $method: $path"
        else
            echo "  [WARN] 缺失，跳过: $method ($path)"
        fi
    done

    local cmd=("$QUAST" "${fasta_args[@]}" --memory-efficient -t "$THREADS" -o "$OUT_DIR/all_report" -l "$labels")
    if [[ "$with_ref" == 4 ]]; then
        cmd+=(-r "$REF")
        echo "  参考: $REF"
    fi

    echo "  命令: ${cmd[*]}"
    "${cmd[@]}" 2>&1 | tee -a "$LOG_FILE"
    local code=$?
    [[ $code -eq 0 ]] || { echo "[ERROR] QUAST 失败 (exit $code)"; exit 3; }
    echo "  → 产物: $OUT_DIR/all_report/report.html"
}

# -----------------------------------------------------------------------------
# 主调度
# -----------------------------------------------------------------------------
case "$MODE" in
    1|2)
        run_single "$MODE"
        ;;
    3|4)
        run_compare "$MODE"
        ;;
esac

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "QUAST 评估完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物: $OUT_DIR/<方法名>_report/report.html"
    echo "      （<方法名> = 单组装: -p 指定的方法名；多组装对比: all）"
    echo "      浏览器打开看：N50/总长/contigs/GC/参考覆盖率等"
    echo "============================================================"
} | tee -a "$LOG_FILE"