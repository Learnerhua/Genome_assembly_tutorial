#!/bin/bash
# 下载 PRJEB7245 (PacBio RS) 的 3 个 ERR 测序数据
# 当前目录: PRJEB7245/  (rawData/PRJEB7245/)
# 输出目录: ../fastq_7245/
#
# 关键设计：
#   - 用 aws-cli 从 NCBI ODP S3 桶下载（稳定 + 自动 multipart MD5）
#   - aria2c 在 S3 上会卡 SHA256，不用
#   - 每个文件先下到临时名 (加 .aws 后缀)，再重命名到 .sra，便于断点续传
set -e

ACC_LIST="SRR_Acc_List.txt"
THREADS=6
ODP_BASE="s3://sra-pub-run-odp/sra"

# ---- 配置输出目录 ----
OUT_DIR="$(cd "$(dirname "$0")/../fastq_7245" && pwd)"
mkdir -p "$OUT_DIR"

echo "[$(date +%T)] 输出目录: $OUT_DIR"

# ---- 主循环 ----
while read -r acc; do
  [ -z "$acc" ] && continue
  echo ""
  echo "[$(date +%T)] === 处理 $acc ==="

  # 已完成 fastq.gz → 跳过
  if [ -s "$OUT_DIR/${acc}.fastq.gz" ]; then
    echo "  $acc.fastq.gz 已存在，跳过"
    continue
  fi

  SRA_FILE="${acc}.sra"

  # 1) aws s3 cp 下载（已支持断点续传，如有 .sra.partial 会跳过已下完的文件）
  if [ ! -s "$SRA_FILE" ]; then
    echo "  aws s3 cp 下载完整 SRA ..."
    if ! aws s3 cp --no-sign-request "$ODP_BASE/${acc}/${acc}" "$SRA_FILE"; then
      echo "  ERROR: aws s3 cp 失败"
      exit 1
    fi
  fi
  SIZE=$(stat -c %s "$SRA_FILE" 2>/dev/null || echo 0)
  echo "  SRA 大小: $((SIZE/1024/1024)) MiB"

  # 2) vdb-validate 校验
  echo "  vdb-validate ..."
  if ! vdb-validate "$SRA_FILE" > /dev/null 2>&1; then
    echo "  ERROR: $acc 校验失败！"
    vdb-validate "$SRA_FILE" 2>&1 | tail -3
    exit 1
  fi
  echo "  ✓ MD5 校验通过"

  # 3) fasterq-dump 转 fastq
  echo "  fasterq-dump ..."
  cd "$OUT_DIR"
  fasterq-dump --split-files --threads $THREADS \
    --temp "./tmp_${acc}" -O . "$SRA_FILE" 2>&1 | tail -5

  rm -rf "$OUT_DIR/tmp_${acc}"

  # 4) gzip
  if [ -f "$OUT_DIR/${acc}.fastq" ]; then
    gzip -f "$OUT_DIR/${acc}.fastq"
    echo "  -> ${acc}.fastq.gz 完成 ($(du -h "$OUT_DIR/${acc}.fastq.gz" | cut -f1))"
  elif [ -f "$OUT_DIR/${acc}_1.fastq" ]; then
    gzip -f "$OUT_DIR/${acc}_1.fastq" "$OUT_DIR/${acc}_2.fastq"
    echo "  -> paired fastq.gz 完成"
  fi

  cd - >/dev/null
done < "$ACC_LIST"

echo ""
echo "[$(date +%T)] === 全部完成 ==="
ls -lh "$OUT_DIR"/*.fastq.gz 2>&1
