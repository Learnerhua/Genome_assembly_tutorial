#!/usr/bin/env bash
# =============================================================================
# hifiasm 组装脚本 - PacBio HiFi
# =============================================================================
# 数据：rawData/SRR13577847_subreads.fastq.gz（HiFi, 569 MB, 63,622 reads）
# 目的：演示 hifiasm 对 HiFi 数据的组装（HiFi 组装首选工具）
# =============================================================================
# 用法：bash run_hifi.sh            # 默认 48 线程
#       bash run_hifi.sh 16         # 自定义线程数
#
# hifiasm 特点：
#   1. phase-aware 字符串图算法（HiFi 组装首选）
#   2. 一步完成（无需预纠错，HiFi <1% 错误率直接组装）
#   3. 输出 .gfa 格式（需转 FASTA 供下游使用）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.hifi"
OUT_DIR="$SCRIPT_DIR/$SCHEME_NAME"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据路径
HIFI="${REPO_ROOT}/rawData/SRR13577847_subreads.fastq.gz"

# hifiasm 路径
HIFIASM="${DATA_ROOT}/Download/hifiasm/hifiasm"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$HIFIASM" ]] || { echo "[ERROR] hifiasm 未找到: $HIFIASM（见 5.1.16）"; exit 1; }
[[ -f "$HIFI" ]] || { echo "[ERROR] 缺失 HiFi: $HIFI"; exit 1; }

mkdir -p "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "hifiasm 组装启动 - PacBio HiFi"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  数据:"
    echo "    HiFi: $HIFI"
    echo "  输出前缀: $OUT_DIR/scer"
    echo "  日志: $LOG_DIR/hifiasm.log"
    echo "============================================================"
} | tee "$LOG_DIR/hifiasm_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 运行 hifiasm
# -o scer:   输出前缀（在 OUT_DIR 下生成 scer.bp.p_ctg.gfa 等）
# -t:        线程数
# --hg-size: 预估单倍体基因组大小（酵母 12.16 Mb）
# -f 0:      禁用初始 bloom filter（官方建议小基因组用 -f0，省 16GB 内存）
# -l 0:      禁用 haplotig 去冗余（官方建议纯合/单倍体基因组用 -l0）
#            ——酵母是单倍体，无 haplotig 冗余（实测 -l 1 与 -l 0 结果完全相同）
# -u:        post-join 步骤（默认开启，提高 N50）
# -----------------------------------------------------------------------------
echo ""
echo "[hifiasm] 启动 $(date '+%H:%M:%S')"
"$HIFIASM" \
    -o "$OUT_DIR/scer" \
    -t "$THREADS" \
    --hg-size 12m \
    -f 0 \
    -l 0 \
    "$HIFI" \
    > "$LOG_DIR/hifiasm.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] hifiasm 失败 (exit $EXIT_CODE)"; tail -30 "$LOG_DIR/hifiasm.log" >&2; exit 2; }
echo "[hifiasm] 完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报 + GFA 转 FASTA（hifiasm 输出 GFA 格式，转 FASTA 供统计/下游使用）
# -----------------------------------------------------------------------------
CTG_GFA="$OUT_DIR/scer.bp.p_ctg.gfa"   # primary contigs（主产物）
CTG_FA="$OUT_DIR/scer.bp.p_ctg.fasta"

if [[ -f "$CTG_GFA" ]]; then
    # GFA → FASTA：取 S 行（序列段），转成 >name\nseq
    awk '/^S/{print ">"$2; print $3}' "$CTG_GFA" > "$CTG_FA"
    echo "[hifiasm] GFA 已转 FASTA: $CTG_FA"
fi

{
    echo "============================================================"
    echo "hifiasm 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    echo "  scer.bp.p_ctg.gfa       primary contigs（GFA，主要产物）"
    echo "  scer.bp.p_ctg.fasta     primary contigs（转 FASTA，统计用）"
    echo "  scer.bp.p_utg.gfa       unitigs（中间产物）"
    echo "  scer.bp.r_utg.gfa       alternate contigs（备用单倍型）"
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py $CTG_FA"
    echo "============================================================"
} | tee -a "$LOG_DIR/hifiasm_startup.log"