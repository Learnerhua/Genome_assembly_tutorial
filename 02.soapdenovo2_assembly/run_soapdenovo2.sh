#!/usr/bin/env bash
# =============================================================================
# SOAPdenovo2 一键组装脚本（酵母 S288C, Illumina PE150, ERR1938683）
# =============================================================================
# 用法：
#   cd ${REPO_ROOT}/02.soapdenovo2_assembly
#   bash run_soapdenovo2.sh                     # 默认 48 线程
#   bash run_soapdenovo2.sh 16                  # 自定义线程数
#
# 输出文件：out/scer.scafSeq.gz（最终 scaffold FASTA）
# 详细日志：logs/all.log
# =============================================================================

set -u
set -o pipefail

THREADS="${1:-48}"
PREFIX="scer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/out"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG="$SCRIPT_DIR/soapdenovo2.config"

mkdir -p "$OUT_DIR" "$LOG_DIR"

if ! command -v SOAPdenovo-63mer >/dev/null 2>&1; then
    echo "[ERROR] SOAPdenovo-63mer 不在 PATH 中" >&2; exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] 配置文件不存在: $CONFIG" >&2; exit 1
fi

echo "============================================================"
echo "SOAPdenovo2 组装启动"
echo "  线程数：$THREADS   前缀：$PREFIX"
echo "  配置文件：$CONFIG"
echo "  数据源：ERR1938683 (S. cerevisiae S288C, Illumina MiSeq PE150, fastp 质控后)"
echo "  启动时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# -----------------------------------------------------------------------------
# 一次调用 all 子命令，SOAPdenovo2 内部顺序完成 pregraph / contig / map / scaff
# -K 63    K-mer 长度（与 config 中 K=63 一致）
# -R       利用 reads 信息修正 graph
# -d 1     K-mer 最小覆盖阈值（与 config 中 minimum_kmer_cov=1 一致）
# -p N     各阶段并行度
# -----------------------------------------------------------------------------
SOAPdenovo-63mer all \
    -s "$CONFIG" \
    -K 63 \
    -R \
    -d 1 \
    -p "$THREADS" \
    -o "$OUT_DIR/$PREFIX" \
    > "$LOG_DIR/all.log" 2>&1

if [[ $? -ne 0 ]]; then
    echo "[ERROR] 组装失败，详见 $LOG_DIR/all.log" >&2
    exit 1
fi

echo ""
echo "============================================================"
echo "组装完成 $(date '+%Y-%m-%d %H:%M:%S')"
echo "最终产出：$OUT_DIR/$PREFIX.scafSeq"
echo "详细日志：$LOG_DIR/all.log"
echo "============================================================"