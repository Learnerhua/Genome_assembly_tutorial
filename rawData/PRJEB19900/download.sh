#!/bin/bash
# 下载 PRJEB19900 项目的 5 个 ERR 测序数据（Oxford Nanopore MinION）
# 当前目录: PRJEB19900/  (rawData/PRJEB19900/)
# 输出目录: ../fastq/
set -e

# ---- 配置 ----
ACC_LIST="SRR_Acc_List.txt"
OUT_DIR="$(cd "$(dirname "$0")/../fastq" && pwd)"
THREADS=6
mkdir -p "$OUT_DIR"

echo "[$(date +%T)] 输出目录: $OUT_DIR"

# ---- 主循环 ----
while read -r acc; do
  [ -z "$acc" ] && continue

  echo ""
  echo "[$(date +%T)] === 处理 $acc ==="

  # 已完成的跳过
  if [ -s "$OUT_DIR/${acc}.fastq.gz" ]; then
    echo "  $acc.fastq.gz 已存在，跳过"
    continue
  fi

  # 1) 通过 NCBI runinfo API 拿到 lite SRA 的直链
  CSV=$(wget -q -O - "https://trace.ncbi.nlm.nih.gov/Traces/sra-db-be/runinfo?acc=${acc}")
  DL_PATH=$(echo "$CSV" | awk -F, 'NR>1 {print $10}')
  if [ -z "$DL_PATH" ]; then
    echo "  ERROR: 找不到 $acc 的 download_path"
    continue
  fi
  echo "  直链: $DL_PATH"

  # 2) 并行下 .lite.1 (SRA lite 格式)
  SRA_FILE="$OUT_DIR/${acc}.sra"
  if [ ! -s "$SRA_FILE" ]; then
    echo "  下载 .lite.1 中 ..."
    wget -c -O "$SRA_FILE" -t 10 -T 600 "$DL_PATH" \
      > "$OUT_DIR/${acc}.wget.log" 2>&1
    # 下载完成后清理日志
    rm -f "$OUT_DIR/${acc}.wget.log"
  fi
  SIZE=$(stat -c %s "$SRA_FILE" 2>/dev/null || echo 0)
  echo "  SRA 大小: $((SIZE/1024/1024)) MiB"

  # 3) 校验完整性
  echo "  vdb-validate ..."
  if ! vdb-validate "$SRA_FILE" > "$OUT_DIR/${acc}.validate.log" 2>&1; then
    echo "  ERROR: $acc 校验失败！"
    cat "$OUT_DIR/${acc}.validate.log"
    continue
  fi
  rm -f "$OUT_DIR/${acc}.validate.log"

  # 4) 转换为 fastq 并 gzip
  echo "  fasterq-dump ..."
  cd "$OUT_DIR"
  fasterq-dump --split-files --threads $THREADS \
    --temp "./tmp_${acc}" -O . "$SRA_FILE" 2>&1 | tail -5

  rm -rf "$OUT_DIR/tmp_${acc}"

  if [ -f "$OUT_DIR/${acc}.fastq" ]; then
    gzip -f "$OUT_DIR/${acc}.fastq"
    echo "  -> ${acc}.fastq.gz 生成完成 ($(du -h "$OUT_DIR/${acc}.fastq.gz" | cut -f1))"
  elif [ -f "$OUT_DIR/${acc}_1.fastq" ]; then
    gzip -f "$OUT_DIR/${acc}_1.fastq" "$OUT_DIR/${acc}_2.fastq"
    echo "  -> paired fastq.gz 生成完成"
  fi

  cd - >/dev/null
done < "$ACC_LIST"

echo ""
echo "[$(date +%T)] === 全部完成 ==="
ls -lh "$OUT_DIR"/*.fastq.gz 2>&1
