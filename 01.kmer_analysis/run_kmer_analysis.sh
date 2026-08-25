#!/usr/bin/env bash
# =============================================================================
# K-mer 调研流程脚本（酿酒酵母 S288C Illumina PE150, ERR1938683）
# =============================================================================
# 工具链：Jellyfish → GenomeScope（与 FastK/Smudgeplot、GCE 交叉验证）
# 数据：../rawData/ERR1938683_{1,2}.fastq.gz（PE150，标称 insert 367±128）
# 用法：cd 01.kmer_analysis && bash run_kmer_analysis.sh
# =============================================================================

set -uo pipefail

# -----------------------------------------------------------------------------
# 全局参数（与原始记录一致，未改动）
# -----------------------------------------------------------------------------
THREADS=48
K=19                 # K-mer 长度
HASH_SIZE=1G         # Jellyfish hash 表大小
MIN_HISTO=10000      # 直方图最大深度截断
SMUDGE_KOP=5         # Smudgeplot hetmers 最小覆盖阈值
GENOMESCOPE_P=1      # GenomeScopeP 倍性参数
R1_PATH="${REPO_ROOT}/rawData/ERR1938683_1.fastq.gz"
R2_PATH="${REPO_ROOT}/rawData/ERR1938683_2.fastq.gz"

# -----------------------------------------------------------------------------
# 路径设置
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_FILE="$SCRIPT_DIR/data.txt"
LOG_DIR="$SCRIPT_DIR/logs"
JELLYFISH_DIR="$SCRIPT_DIR/jellyfish_out"
FASTK_DIR="$SCRIPT_DIR/fastk_out"
SMUDGEPLOT_DIR="$SCRIPT_DIR/smudgeplot_out"
GENOMESCOPE_DIR="$SCRIPT_DIR/genomescope_out"
GCE_DIR="$SCRIPT_DIR/gce_out"

mkdir -p "$LOG_DIR" "$JELLYFISH_DIR" "$FASTK_DIR" "$SMUDGEPLOT_DIR" "$GENOMESCOPE_DIR" "$GCE_DIR"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
echo "============================================================"
echo "K-mer 调研流程启动"
echo "  K = $K   threads = $THREADS   hash_size = $HASH_SIZE"
echo "  R1 = $R1_PATH"
echo "  R2 = $R2_PATH"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

for cmd in jellyfish genomescope.R FastK smudgeplot gce gzip; do
    command -v "$cmd" >/dev/null || { echo "[ERROR] $cmd 不在 PATH"; exit 1; }
done
[[ -f "$R1_PATH" ]] || { echo "[ERROR] 缺失 R1"; exit 1; }
[[ -f "$R2_PATH" ]] || { echo "[ERROR] 缺失 R2"; exit 1; }

# -----------------------------------------------------------------------------
# data.txt：Jellyfish 通过该文件读取多组输入（gzip 流式解压）
# -----------------------------------------------------------------------------
cat > "$DATA_FILE" <<EOF
gzip -dc $R1_PATH
gzip -dc $R2_PATH
EOF

# =============================================================================
# 阶段 1：Jellyfish K-mer 计数
# =============================================================================
echo ""
echo "[stage 1/4] Jellyfish 启动 $(date '+%H:%M:%S')"

# count: K-mer 计数
jellyfish count \
    -t "$THREADS" \
    -C \
    -m "$K" \
    -s "$HASH_SIZE" \
    -g "$DATA_FILE" \
    -G 2 \
    -o "$JELLYFISH_DIR/kmer_counts.jf" \
    > "$LOG_DIR/jellyfish_count.log" 2>&1

# histo: 生成 K-mer 频次直方图
jellyfish histo \
    -v \
    -o "$JELLYFISH_DIR/kmer_counts.hist" \
    -t "$THREADS" \
    -h "$MIN_HISTO" \
    "$JELLYFISH_DIR/kmer_counts.jf" \
    > "$LOG_DIR/jellyfish_histo.log" 2>&1

# stats: 输出基础统计（Total 用于后续 GCE）
jellyfish stats \
    -o "$JELLYFISH_DIR/kmer_counts.stat" \
    "$JELLYFISH_DIR/kmer_counts.jf" \
    > "$LOG_DIR/jellyfish_stats.log" 2>&1

echo "[stage 1/4] Jellyfish 完成 $(date '+%H:%M:%S')"
echo "  K-mer 总数（来自 kmer_counts.stat）:"
grep '^Total' "$JELLYFISH_DIR/kmer_counts.stat" | sed 's/^/    /'

# =============================================================================
# 阶段 2：GenomeScope 拟合（从 histo 推断基因组大小）
# =============================================================================
echo ""
echo "[stage 2/4] GenomeScope 启动 $(date '+%H:%M:%S')"

genomescope.R \
    -i "$JELLYFISH_DIR/kmer_counts.hist" \
    -o "$GENOMESCOPE_DIR" \
    -p "$GENOMESCOPE_P" \
    -k "$K" \
    --max_kmercov "$MIN_HISTO" \
    > "$LOG_DIR/genomescope.log" 2>&1

echo "[stage 2/4] GenomeScope 完成 $(date '+%H:%M:%S')"

# =============================================================================
# 阶段 3：FastK + Smudgeplot（K-mer 配对分析，倍性评估）
# =============================================================================
echo ""
echo "[stage 3/4] FastK + Smudgeplot 启动 $(date '+%H:%M:%S')"

# FastK 直接从 FASTQ 生成 ktab（不依赖 jellyfish_out）
FastK \
    -k"$K" \
    -t"$THREADS" \
    -T4 \
    -Nscer_k19 \
    "$R1_PATH" "$R2_PATH" \
    > "$LOG_DIR/fastk.log" 2>&1

# FastK 默认输出到当前目录，移动到 fastk_out
mv -f scer_k19.* "$FASTK_DIR/" 2>/dev/null || true

# smudgeplot hetmers：从 ktab 提取配对 k-mer
smudgeplot hetmers \
    -L "$SMUDGE_KOP" \
    -t"$THREADS" \
    -o scer_pairs \
    "$FASTK_DIR/scer_k19.ktab" \
    > "$LOG_DIR/smudgeplot_hetmers.log" 2>&1

# 同上，移动 smudgeplot 中间文件
mv -f scer_pairs.* "$SMUDGEPLOT_DIR/" 2>/dev/null || true

# smudgeplot plot：绘图（PNG 输出）
smudgeplot plot \
    --R \
    --kernel \
    --title "Yeast S288C K-mer Pairs" \
    -o "$SMUDGEPLOT_DIR/scer_smudge_smudgeplot.png" \
    "$SMUDGEPLOT_DIR/scer_pairs.smu" \
    >> "$LOG_DIR/smudgeplot_plot.log" 2>&1 || true

echo "[stage 3/4] FastK + Smudgeplot 完成 $(date '+%H:%M:%S')"

# =============================================================================
# 阶段 4：GCE 交叉验证（与 GenomeScope 对照基因组大小估计）
# =============================================================================
echo ""
echo "[stage 4/4] GCE 启动 $(date '+%H:%M:%S')"

# GCE 需要 -g 总 kmer 数（从 jellyfish stats 中读取）
TOTAL_KMERS=$(awk '/^Total:/{gsub(",",""); print $2}' "$JELLYFISH_DIR/kmer_counts.stat")
[[ -z "$TOTAL_KMERS" ]] && { echo "[ERROR] 无法读取 Total k-mer 数"; exit 1; }

gce \
    -f "$JELLYFISH_DIR/kmer_counts.hist" \
    -H 0 \
    -g "$TOTAL_KMERS" \
    -M "$MIN_HISTO" \
    > "$GCE_DIR/gce.table" 2> "$GCE_DIR/gce.log"

echo "[stage 4/4] GCE 完成 $(date '+%H:%M:%S')"

# =============================================================================
# 完成汇总
# =============================================================================
echo ""
echo "============================================================"
echo "K-mer 调研全部完成 $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo "产物:"
echo "  $JELLYFISH_DIR/"
echo "    kmer_counts.jf      二进制 K-mer 数据库"
echo "    kmer_counts.hist    K-mer 频次直方图"
echo "    kmer_counts.stat    统计（Total/Distinct/Unique）"
echo "  $GENOMESCOPE_DIR/"
echo "    summary.txt         拟合结果（基因组大小/重复/杂合）"
echo "    model.txt           模型参数"
echo "    linear_plot.png     主拟合图"
echo "  $FASTK_DIR/"
echo "    scer_k19.ktab       FastK 表"
echo "  $SMUDGEPLOT_DIR/"
echo "    scer_smudge_smudgeplot.png   倍性图"
echo "    scer_smudge.smudge_report.tsv  倍性报告"
echo "  $GCE_DIR/"
echo "    gce.table           GCE 估计表"
echo "    gce.log             GCE 日志"
echo ""
echo "详细日志: $LOG_DIR/"
echo "============================================================"