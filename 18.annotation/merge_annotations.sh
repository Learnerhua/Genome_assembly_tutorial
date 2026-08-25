#!/usr/bin/env bash
# =============================================================================
# 合并核基因组 + 线粒体注释为最终交付（18.annotation/final_assembly）
# =============================================================================
# 目的：
#   将核基因组注释（liftoff.gff3，chrI-XVI，6,583 基因）与线粒体注释
#   （mito_liftoff.gff3，mtDNA，28 基因）合并为一个完整的交付结果，
#   格式与官方（Ensembl toplevel）保持一致：
#     - FASTA：核染色体（chrI-XVI）+ 线粒体（>Mito）在一个文件
#     - GFF3：所有染色体注释 + 标准 header 在一个文件
#
# 输入：
#   ../liftoff/liftoff.gff3           核基因组注释
#   ../mito_anno/mito_liftoff.gff3    线粒体注释
#   ../../17.ref_chromosomes/ref_scaffold_no_mito.fa  核基因组 FASTA（16 条）
#   ../../17.ref_chromosomes/mtDNA.fa                 线粒体 FASTA（>mtDNA）
#
# 输出（final_assembly/）：
#   genome.fa          完整基因组（chrI-XVI + Mito）
#   annotations.gff3   完整注释（核 + 线粒体）
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"
OUT_DIR="$SCRIPT_DIR"

# 输入
NUC_FA="$PROJECT_ROOT/17.ref_chromosomes/ref_scaffold_no_mito.fa"
MITO_FA="$PROJECT_ROOT/17.ref_chromosomes/mtDNA.fa"
NUC_GFF="$SCRIPT_DIR/../liftoff/liftoff.gff3"
MITO_GFF="$SCRIPT_DIR/../mito_anno/mito_liftoff.gff3"

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$NUC_FA" ]] || { echo "[ERROR] nuclear FASTA not found: $NUC_FA"; exit 1; }
[[ -f "$MITO_FA" ]] || { echo "[ERROR] mtDNA FASTA not found: $MITO_FA"; exit 1; }
[[ -f "$NUC_GFF" ]] || { echo "[ERROR] nuclear GFF3 not found: $NUC_GFF"; exit 1; }
[[ -f "$MITO_GFF" ]] || { echo "[ERROR] mito GFF3 not found: $MITO_GFF"; exit 1; }

# =============================================================================
# Step 1: 合并 FASTA（核染色体 + Mito）
# =============================================================================
echo ">>> [1/2] 合并 FASTA..."
cat "$NUC_FA" > "$OUT_DIR/genome.fa"
# mtDNA 的 header >mtDNA 改为 >Mito（与官方命名一致）
sed 's/^>mtDNA/>Mito/' "$MITO_FA" >> "$OUT_DIR/genome.fa"
echo "  genome.fa: $(grep -c '^>' "$OUT_DIR/genome.fa") 条序列"

# =============================================================================
# Step 2: 合并 GFF3（核注释 + 线粒体注释）
# =============================================================================
echo ">>> [2/2] 合并 GFF3..."
{
    echo "##gff-version 3"
    # 核注释（去掉可能的旧 header，只留 feature 行）
    grep -v '^#' "$NUC_GFF"
    # 线粒体注释（染色体名 mtDNA → Mito，与 FASTA 一致）
    sed 's/^mtDNA\t/Mito\t/' "$MITO_GFF" | grep -v '^#'
} > "$OUT_DIR/annotations.gff3"

echo "  基因总数: $(grep -c $'\tgene\t' "$OUT_DIR/annotations.gff3")"
echo "  核基因:   $(grep -c $'\tgene\t' "$NUC_GFF")"
echo "  线粒体基因: $(grep -c $'\tgene\t' "$MITO_GFF")"

echo ""
echo "=== 完成 ==="
echo "  $OUT_DIR/genome.fa"
echo "  $OUT_DIR/annotations.gff3"
