#!/usr/bin/env bash
# =============================================================================
# wtdbg2 组装脚本 - PacBio CLR
# =============================================================================
# 数据：rawData/PRJEB7245/pacbio_clr_merged.fastq.gz（PacBio CLR, 2.3 GB, 490,396 reads）
# 目的：演示 wtdbg2 对 CLR 数据的快速组装（DBG 算法，无需 OLC 纠错）
# =============================================================================
# 用法：bash run_clr.sh            # 默认 48 线程
#       bash run_clr.sh 16         # 自定义线程数
#
# wtdbg2 流程（两步）：
#   1. wtdbg2 组装原始 reads → 草稿 contigs（.ctg.lay.gz）
#   2. wtpoa-cns 基于 reads 比对做 consensus → 最终序列（.cns.fa）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_NAME="01.clr"
OUT_BASE="$SCRIPT_DIR/$SCHEME_NAME"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据路径
CLR="${REPO_ROOT}/rawData/PRJEB7245/pacbio_clr_merged.fastq.gz"

# wtdbg2 工具路径
WTDBG2="${DATA_ROOT}/Download/wtdbg2/wtdbg2"
WTPOA_CNS="${DATA_ROOT}/Download/wtdbg2/wtpoa-cns"

# 输出前缀
PREFIX="$OUT_BASE/scer"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$WTDBG2" ]] || { echo "[ERROR] wtdbg2 未找到: $WTDBG2"; exit 1; }
[[ -x "$WTPOA_CNS" ]] || { echo "[ERROR] wtpoa-cns 未找到: $WTPOA_CNS"; exit 1; }
[[ -f "$CLR" ]] || { echo "[ERROR] 缺失 CLR: $CLR"; exit 1; }

mkdir -p "$OUT_BASE" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "wtdbg2 组装启动 - PacBio CLR"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  数据:"
    echo "    CLR: $CLR"
    echo "  输出前缀: $PREFIX"
    echo "  日志: $LOG_DIR/wtdbg2.log"
    echo "============================================================"
} | tee "$LOG_DIR/wtdbg2_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# 步骤 1：wtdbg2 组装（DBG 直接组装原始 reads）
# -x rs:    PacBio 数据预设（rs = RS/CLR 长读长）
# -g 12.1m: 预估基因组大小（酵母参考 12.16 Mb）
# -L 1000:  只保留 >1 kb 的 reads（丢弃极短 reads）
# -l 2048:  最小比对长度（--min-length；默认较高，显式传 2048 让 contig 不被过早切断）
# -e 3:     最小 read depth（--min-read-depth；默认 3，过滤低覆盖不可靠 contig）
# -X 200:   覆盖度采样上限（默认 50；CLR 高错误率下设大一点保留更多 reads 帮助组装完整基因组）
# -t:       线程数
# -----------------------------------------------------------------------------
echo ""
echo "[step 1/2] wtdbg2 组装 $(date '+%H:%M:%S')"
"$WTDBG2" \
    -i "$CLR" \
    -o "$PREFIX" \
    -x rs \
    -g 12.1m \
    -L 1000 \
    -l 2048 \
    -e 3 \
    -X 200 \
    -t "$THREADS" \
    > "$LOG_DIR/wtdbg2.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] wtdbg2 失败 (exit $EXIT_CODE)"; tail -20 "$LOG_DIR/wtdbg2.log" >&2; exit 2; }
echo "  草稿 contigs: $(ls -lh ${PREFIX}.ctg.lay.gz 2>/dev/null | awk '{print $5}')"
echo "[step 1/2] wtdbg2 完成"

# -----------------------------------------------------------------------------
# 步骤 2：wtpoa-cns 一致性校正
# -t: 线程数
# -i: 草稿 contigs（*.ctg.lay.gz，由 wtdbg2 生成）
# -o: 输出 consensus FASTA（注意：实际接受 -o 不是 -fo！README 有误）
# -f: 强制覆盖已有输出
# 注意：第一步 consensus 不要加 -d 参数（-d 是第二步 polish consensus 才用的）
# -----------------------------------------------------------------------------
echo ""
echo "[step 2/2] wtpoa-cns 一致性校正 $(date '+%H:%M:%S')"
"$WTPOA_CNS" \
    -t "$THREADS" \
    -i "${PREFIX}.ctg.lay.gz" \
    -o "${PREFIX}.cns.fa" \
    -f \
    > "$LOG_DIR/wtpoa-cns.log" 2>&1
EXIT_CODE=$?
[[ $EXIT_CODE -eq 0 ]] || { echo "[ERROR] wtpoa-cns 失败 (exit $EXIT_CODE)"; tail -20 "$LOG_DIR/wtpoa-cns.log" >&2; exit 3; }
echo "  最终序列: $(ls -lh ${PREFIX}.cns.fa 2>/dev/null | awk '{print $5}')"
echo "[step 2/2] wtpoa-cns 完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "wtdbg2 组装完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物:"
    echo "  ${PREFIX}.ctg.lay.gz   草稿 contigs（中间产物）"
    echo "  ${PREFIX}.cns.fa      最终一致性序列（主要产物）"
    echo ""
    echo "后续：用 03.spades_assembly/assembly_stats.py 统计 N50 等指标"
    echo "  python3 ../03.spades_assembly/assembly_stats.py ${PREFIX}.cns.fa"
    echo "============================================================"
} | tee -a "$LOG_DIR/wtdbg2_startup.log"