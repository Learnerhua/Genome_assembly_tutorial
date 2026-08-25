#!/usr/bin/env bash
# =============================================================================
# purge_dups 去冗余脚本（Canu HiFi 组装产物）
# =============================================================================
# 输入：
#   - Canu 组装 contigs：04.canu_assembly/01.hifi/canu_run/scer.contigs.fasta
#   - HiFi reads：rawData/SRR13577847_subreads.fastq.gz
# 输出：去冗余后的 contigs（01.hifi/purged/）
# =============================================================================
# 用法：bash run_purge_dups.sh            # 默认 48 线程
#       bash run_purge_dups.sh 16         # 自定义线程数
#
# 流程（purge_dups 官方 README 完整步骤）：
#   Step 1a: minimap2 reads→asm → reads.paf → pbcstat → PB.stat → calcuts → cutoffs
#   Step 1b: split_fa 拆分 asm → asm.split；minimap2 asm→asm self → self.paf
#   Step 2:  purge_dups -2 -T cutoffs -c PB.base.cov self.paf > dups.bed
#   Step 3:  get_seqs 提取去冗余序列
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
SCHEME_DIR="$SCRIPT_DIR/01.hifi"
OUT_DIR="$SCHEME_DIR/purged"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据
CONTIGS="$SCHEME_DIR/canu_run/scer.contigs.fasta"
READS="${REPO_ROOT}/rawData/SRR13577847_subreads.fastq.gz"

# 工具路径（工具在 Download 目录，PATH 可能不含）
MINIMAP2="${DATA_ROOT}/Download/minimap2/minimap2"
PURGE_DUPS_BIN="${DATA_ROOT}/Download/purge_dups/bin"
export PATH="$PURGE_DUPS_BIN:$PATH"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
[[ -x "$MINIMAP2" ]] || { echo "[ERROR] minimap2 未找到: $MINIMAP2"; exit 1; }
command -v pbcstat >/dev/null || { echo "[ERROR] pbcstat 不在 PATH（purge_dups/bin）"; exit 1; }
command -v calcuts >/dev/null || { echo "[ERROR] calcuts 不在 PATH（purge_dups/bin）"; exit 1; }
command -v split_fa >/dev/null || { echo "[ERROR] split_fa 不在 PATH（purge_dups/bin）"; exit 1; }
command -v purge_dups >/dev/null || { echo "[ERROR] purge_dups 不在 PATH"; exit 1; }
command -v get_seqs >/dev/null || { echo "[ERROR] get_seqs 不在 PATH（purge_dups/bin）"; exit 1; }
[[ -f "$CONTIGS" ]] || { echo "[ERROR] 缺失 contigs: $CONTIGS"; exit 1; }
[[ -f "$READS" ]] || { echo "[ERROR] 缺失 reads: $READS"; exit 1; }

mkdir -p "$OUT_DIR" "$LOG_DIR"
cd "$OUT_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "purge_dups 去冗余启动"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  contigs: $CONTIGS"
    echo "  reads:   $READS"
    echo "  输出目录: $OUT_DIR"
    echo "============================================================"
} | tee "$LOG_DIR/purge_dups_startup.log"

START=$(date +%s)

# -----------------------------------------------------------------------------
# Step 1a: reads→asm 比对 + 覆盖度统计
# -----------------------------------------------------------------------------
echo ""
echo "[step 1a/4] minimap2 reads→asm $(date '+%H:%M:%S')"
"$MINIMAP2" -x map-hifi \
    -t "$THREADS" \
    "$CONTIGS" "$READS" \
    > reads.paf \
    2> "$LOG_DIR/minimap2.log"
[[ $? -eq 0 ]] || { echo "[ERROR] minimap2 (reads→asm) 失败"; exit 2; }
echo "  reads.paf: $(wc -l < reads.paf) 行"

echo ""
echo "[step 1b/4] pbcstat + calcuts $(date '+%H:%M:%S')"
pbcstat reads.paf 2> "$LOG_DIR/pbcstat.log"
[[ $? -eq 0 ]] || { echo "[ERROR] pbcstat 失败"; exit 3; }
# 注意：官方用 gzip 的 paf.gz，但 pbcstat 也接受普通 paf
# pbcstat 产生 PB.base.cov（碱基层覆盖）和 PB.stat（深度直方图）
calcuts PB.stat > cutoffs 2> "$LOG_DIR/calcuts.log"
[[ $? -eq 0 ]] || { echo "[ERROR] calcuts 失败"; exit 4; }
echo "  PB.base.cov / PB.stat / cutoffs 已生成"

# -----------------------------------------------------------------------------
# Step 1c: 组装自身拆分 + self-self 比对（purge_dups 主输入）
# -----------------------------------------------------------------------------
echo ""
echo "[step 1c/4] split_fa + self 比对 $(date '+%H:%M:%S')"
split_fa "$CONTIGS" > contigs.split 2> "$LOG_DIR/split_fa.log"
[[ $? -eq 0 ]] || { echo "[ERROR] split_fa 失败"; exit 5; }
echo "  contigs.split: $(wc -l < contigs.split) 行"

"$MINIMAP2" -x asm5 -DP \
    -t "$THREADS" \
    contigs.split contigs.split \
    > self.paf \
    2> "$LOG_DIR/minimap2_self.log"
[[ $? -eq 0 ]] || { echo "[ERROR] minimap2 (self) 失败"; exit 6; }
echo "  self.paf: $(wc -l < self.paf) 行"

# -----------------------------------------------------------------------------
# Step 2: purge_dups 去冗余（主输入是 self.paf！不是 reads.paf）
# -2: 双倍体模式
# -T cutoffs: 阈值文件
# -c PB.base.cov: 碱基层覆盖文件
# -----------------------------------------------------------------------------
echo ""
echo "[step 2/4] purge_dups 去冗余 $(date '+%H:%M:%S')"
purge_dups -2 -T cutoffs -c PB.base.cov self.paf \
    > dups.bed 2> "$LOG_DIR/purge_dups.log"
[[ $? -eq 0 ]] || { echo "[ERROR] purge_dups 失败"; exit 7; }
echo "  dups.bed: $(wc -l < dups.bed) 行"

# -----------------------------------------------------------------------------
# Step 3: get_seqs 提取去冗余后的序列
# -e dups.bed: 只去除 contig 末端的单倍型冗余（保守）
# -----------------------------------------------------------------------------
echo ""
echo "[step 3/4] get_seqs 提取 $(date '+%H:%M:%S')"
get_seqs -e dups.bed "$CONTIGS" 2> "$LOG_DIR/get_seqs.log"
[[ $? -eq 0 ]] || { echo "[ERROR] get_seqs 失败"; exit 8; }
echo "[step 3/4] get_seqs 完成"

END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "purge_dups 去冗余完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo ""
    echo "产物（$OUT_DIR）:"
    echo "  reads.paf           reads→asm 比对（用于覆盖度统计）"
    echo "  PB.base.cov         reads 碱基层覆盖"
    echo "  PB.stat             reads 覆盖深度直方图"
    echo "  cutoffs             覆盖度/杂合度阈值"
    echo "  contigs.split       拆分后的组装"
    echo "  self.paf            组装 self-self 比对（purge_dups 输入）"
    echo "  dups.bed            冗余区间"
    echo "  <前缀>.purged.fa    去冗余后主序列（主要产物）"
    echo "  <前缀>.hap.fa       单倍型序列"
    echo "============================================================"
} | tee -a "$LOG_DIR/purge_dups_startup.log"