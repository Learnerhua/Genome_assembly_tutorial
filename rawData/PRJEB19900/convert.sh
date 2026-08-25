#!/bin/bash
set -e
cd ${REPO_ROOT}/fastq || { mkdir -p ${REPO_ROOT}/fastq; cd ${REPO_ROOT}/fastq; }
for sra in *.sra; do
  acc=$(basename "$sra" .sra)
  if [ ! -f "${acc}.fastq" ] && [ ! -f "${acc}.fastq.gz" ]; then
    echo "[$(date +%T)] Converting $acc ..."
    fasterq-dump --split-files --threads 6 --temp "./tmp_${acc}" -O . "$sra" 2>&1 | tail -5
    gzip "${acc}.fastq" 2>/dev/null || gzip "${acc}_1.fastq" "${acc}_2.fastq" 2>/dev/null || true
    echo "[$(date +%T)] Done $acc"
  else
    echo "[$(date +%T)] Skip $acc (output exists)"
  fi
done
echo "=== All conversions complete ==="
ls -lh *.fastq* 2>&1
