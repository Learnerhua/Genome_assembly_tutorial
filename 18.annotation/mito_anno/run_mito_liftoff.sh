#!/usr/bin/env bash
# =============================================================================
# 线粒体基因组 Liftoff 注释（18.annotation/mito_anno）
# =============================================================================
# 目的：
#   核基因组（ref_scaffold_no_mito.fa）已用 Liftoff 注释（liftoff.gff3），
#   但参考 GFF3 中的 27 个线粒体基因（Q 开头）因目标核基因组不含 mtDNA
#   而无法转移（进入 unmapped.txt）。本脚本用参考线粒体（ref_mito.fa +
#   ref_mito.gff3）对我们组装的 mtDNA（mtDNA.fa）单独做 Liftoff 注释。
#
# 输入：
#   ref_mito.fa      参考线粒体序列（从参考 FASTA 提取，85,779 bp）
#   ref_mito.gff3    参考线粒体注释（从参考 GFF3 提取，28 基因）
#   目标 mtDNA.fa    我们组装的线粒体（17.ref_chromosomes/mtDNA.fa，101,552 bp）
#
# 输出（本目录）：
#   mito_liftoff.gff3   目标线粒体的注释 GFF3
#   mito_unmapped.txt   未转移的线粒体基因
#   mito_proteins.fa    线粒体蛋白序列（gffread 提取）
#
# 用法：
#   bash run_mito_liftoff.sh
# =============================================================================

set -uo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
# 兼容 bash 调用时 ${BASH_SOURCE[0]} 是相对路径：用 readlink -f 转绝对路径
[[ "$SCRIPT_PATH" =~ ^/ ]] || SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# 脚本在 18.annotation/mito_anno/，向上 3 级到项目根
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_PATH")")")"

# Tools
LIFTOFF="${CONDA_PREFIX}/bin/liftoff"
GFFREAD="${RNA_SEQ_BIN}/gffread"

# Paths
REF_MITO_FA="$SCRIPT_DIR/ref_mito.fa"
REF_MITO_GFF="$SCRIPT_DIR/ref_mito.gff3"
TARGET_MITO_FA="$PROJECT_ROOT/17.ref_chromosomes/mtDNA.fa"

THREADS="${THREADS:-8}"

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$LIFTOFF" ]] || { echo "[ERROR] liftoff not found: $LIFTOFF"; exit 1; }
[[ -f "$REF_MITO_FA" ]] || { echo "[ERROR] ref mito FASTA not found: $REF_MITO_FA"; exit 1; }
[[ -f "$REF_MITO_GFF" ]] || { echo "[ERROR] ref mito GFF3 not found: $REF_MITO_GFF"; exit 1; }
[[ -f "$TARGET_MITO_FA" ]] || { echo "[ERROR] target mtDNA not found: $TARGET_MITO_FA"; exit 1; }

# =============================================================================
# Step 1: Liftoff（线粒体）
# =============================================================================
echo "============================================================"
echo "线粒体 Liftoff 注释"
echo "  参考: $REF_MITO_FA + $REF_MITO_GFF"
echo "  目标: $TARGET_MITO_FA"
echo "============================================================"

"$LIFTOFF" \
    -g "$REF_MITO_GFF" \
    -o mito_liftoff.gff3 \
    -u mito_unmapped.txt \
    -p "$THREADS" \
    -dir mito_liftoff_tmp \
    "$TARGET_MITO_FA" "$REF_MITO_FA" \
    2>&1 | tail -5

echo ""
echo "=== 结果统计 ==="
echo "转移基因数: $(grep -c $'\tgene\t' mito_liftoff.gff3 2>/dev/null || echo 0)"
echo "未转移基因数: $(wc -l < mito_unmapped.txt 2>/dev/null || echo 0)"
echo "  （unmapped 内容）:"
cat mito_unmapped.txt 2>/dev/null

# =============================================================================
# Step 2: gffread 提取蛋白（可选）
# =============================================================================
if [[ -f mito_liftoff.gff3 ]]; then
    echo ""
    echo "=== gffread 提取蛋白 ==="
    "$GFFREAD" mito_liftoff.gff3 -g "$TARGET_MITO_FA" -y mito_proteins.fa 2>&1 | tail -2
    echo "蛋白数: $(grep -c '^>' mito_proteins.fa 2>/dev/null || echo 0)"
fi

# Clean up
rm -rf mito_liftoff_tmp

echo ""
echo "=== 完成 ==="
