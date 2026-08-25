#!/usr/bin/env bash
# =============================================================================
# Liftoff reference transfer - yeast genome annotation (7.3)
# =============================================================================
# Purpose:
#   Use Liftoff to transfer S288C R64-1-1 reference annotations onto our
#   ref_scaffold_no_mito.fa (16 chromosomes, BUSCO 99.9%, ~12 Mb).
#
# Inputs:
#   ../ref/genome.fa.gz   reference FASTA (Ensembl R64-1-1)
#   ../ref/genome.gff3.gz reference GFF3 (Ensembl R64-1-1, build 63)
#   ../../17.ref_chromosomes/ref_scaffold_no_mito.fa  target assembly
#
# Outputs (in this dir):
#   liftoff.gff3     annotated GFF3 (target coordinates)
#   unmapped.txt      genes that failed to transfer
#   proteins.fa       protein sequences (gffread 提取)
#   busco_proteins/   BUSCO 蛋白模式评估
#
# Usage:
#   bash run_liftoff.sh
# =============================================================================

set -uo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
# 兼容 bash 调用时 ${BASH_SOURCE[0]} 是相对路径：用 readlink -f 转绝对路径
[[ "$SCRIPT_PATH" =~ ^/ ]] || SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# 脚本在 18.annotation/liftoff/，向上 3 级到项目根
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_PATH")")")"
THREADS="${THREADS:-8}"

# Tools
LIFTOFF="${CONDA_PREFIX}/bin/liftoff"
GFFREAD="${RNA_SEQ_BIN}/gffread"
GUNZIP="${MINIFORGE3}/bin/gunzip"
BUSCO_BIN="${BUSCO_BIN}/busco"

# Paths
REF_FA_GZ="$SCRIPT_DIR/../ref/genome.fa.gz"
REF_GFF_GZ="$SCRIPT_DIR/../ref/genome.gff3.gz"
TARGET_FA="$PROJECT_ROOT/17.ref_chromosomes/ref_scaffold_no_mito.fa"
REF_FA="$SCRIPT_DIR/../ref/genome.fa"
REF_GFF="$SCRIPT_DIR/../ref/genome.gff3"
LOG_DIR="$SCRIPT_DIR/../logs"

mkdir -p "$LOG_DIR"

# =============================================================================
# Pre-checks
# =============================================================================
[[ -f "$LIFTOFF" ]] || { echo "[ERROR] liftoff not found: $LIFTOFF"; exit 1; }
[[ -f "$REF_FA_GZ" ]] || { echo "[ERROR] reference FASTA not found: $REF_FA_GZ"; exit 1; }
[[ -f "$REF_GFF_GZ" ]] || { echo "[ERROR] reference GFF3 not found: $REF_GFF_GZ"; exit 1; }
[[ -f "$TARGET_FA" ]] || { echo "[ERROR] target assembly not found: $TARGET_FA"; exit 1; }

# Decompress reference files (if not already decompressed)
[[ -f "$REF_FA" ]] || gunzip -c "$REF_FA_GZ" > "$REF_FA"
[[ -f "$REF_GFF" ]] || gunzip -c "$REF_GFF_GZ" > "$REF_GFF"

# =============================================================================
# Startup info
# =============================================================================
START=$(date +%s)
echo "============================================================"
echo "Liftoff reference transfer (S288C -> ref_scaffold)"
echo "  started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  reference: $REF_FA + $REF_GFF"
echo "  target:    $TARGET_FA"
echo "  threads:   $THREADS"
echo "  output:    $SCRIPT_DIR/liftoff.gff3"
echo "============================================================"

# =============================================================================
# Step 1: Run Liftoff
# =============================================================================
echo ""
echo ">>> [1/3] Liftoff..."
"$LIFTOFF" \
    -g "$REF_GFF" \
    -o liftoff.gff3 \
    -u unmapped.txt \
    -p "$THREADS" \
    -copies \
    -dir liftoff_tmp \
    "$TARGET_FA" "$REF_FA" \
    2>&1 | tee "$LOG_DIR/liftoff.log"
[[ $? -eq 0 ]] || { echo "[ERROR] Liftoff failed"; exit 1; }

# =============================================================================
# Step 2: Extract protein sequences (gffread)
# =============================================================================
echo ""
echo ">>> [2/3] gffread (extract proteins)..."
"$GFFREAD" liftoff.gff3 -g "$TARGET_FA" -y proteins.fa \
    2>&1 | tee -a "$LOG_DIR/liftoff.log"
[[ $? -eq 0 ]] || { echo "[ERROR] gffread failed"; exit 1; }
echo "  proteins.fa: $(grep -c '^>' proteins.fa) sequences"

# =============================================================================
# Step 3: BUSCO protein-mode evaluation
# =============================================================================
echo ""
echo ">>> [3/3] BUSCO (proteins mode)..."
# Ensure busco env toolchain in PATH
export PATH="${BUSCO_BIN}:$PATH"

"$BUSCO_BIN" \
    -i proteins.fa \
    -m proteins \
    -l saccharomycetaceae_odb12.2 \
    -o busco_proteins \
    -c "$THREADS" \
    --offline \
    --download_path "$PROJECT_ROOT/14.busco_analysis/busco_downloads" \
    2>&1 | tee -a "$LOG_DIR/liftoff.log"
[[ $? -eq 0 ]] || { echo "[ERROR] BUSCO failed"; exit 1; }

# Clean up tmp
rm -rf liftoff_tmp

END=$(date +%s)
ELAPSED=$((END - START))
echo ""
echo "============================================================"
echo "Liftoff complete"
echo "  elapsed: ${ELAPSED}s"
echo
echo "Outputs:"
echo "  liftoff.gff3     annotated GFF3 (target coordinates)"
echo "  unmapped.txt      $(wc -l < unmapped.txt) unmapped genes"
echo "  proteins.fa       $(grep -c '^>' proteins.fa) protein sequences"
echo "  busco_proteins/   BUSCO protein-mode evaluation"
echo "============================================================"