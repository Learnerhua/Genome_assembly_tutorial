#!/usr/bin/env bash
# =============================================================================
# Canu 组装脚本 - 方案：PacBio HiFi
# =============================================================================
# 数据：rawData/SRR13577847_subreads.fastq.gz（PacBio HiFi/CCS, ~569 MB）
# 目的：纯长读长组装，与 SPAdes+HiFi 对照（5.5.4 方案 2）
# =============================================================================
# 用法：bash run_hifi.sh            # 默认 48 线程 / 256G 内存
#       bash run_hifi.sh 16 64      # 自定义 16 线程 / 64G 内存
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS="${1:-48}"
MEMORY="${2:-256}"
SCHEME_NAME="01.hifi"
OUT_BASE="$SCRIPT_DIR/$SCHEME_NAME"
LOG_DIR="$SCRIPT_DIR/logs"

# 输入数据路径
HIFI="${REPO_ROOT}/rawData/SRR13577847_subreads.fastq.gz"

# Canu 必需的工作目录：每个 Canu run 必须在独立的 -d 目录里运行
CANU_D="$OUT_BASE/canu_run"
CANU_P="scer"

# -----------------------------------------------------------------------------
# 环境检查
# -----------------------------------------------------------------------------
# Canu 依赖 Java 和 samtools；脚本显式 export PATH（不动系统环境配置）
# 把 java/samtools 所在目录前置，再保留 canu 自身的安装路径（用户 zshrc 已配）
export PATH=/usr/bin:/usr/local/bin:${CONDA_ENVS}/old_base/bin:${DATA_ROOT}/Download/canu-2.3/bin:$PATH
# 注意：不要 export JAVA_HOME，且必须 unset 它！
#   Canu 的 checkJava() 会执行 `command -v $java`；在 bash 里 command -v 对
#   绝对路径返回空，导致 java 路径变空而报 "mhap overlapper requires java"。
#   用户 .zshrc 里设置了 JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64，
#   会让 Canu 走绝对路径分支 → bash 下 command -v 返回空 → 报错。
#   正确做法：unset JAVA_HOME，让 Canu 用 fallback "java"（java 在 PATH 中）。
unset JAVA_HOME
unset JAVA_CMD
unset JAVA

command -v canu >/dev/null || { echo "[ERROR] canu 不在 PATH"; exit 1; }
command -v java >/dev/null || { echo "[ERROR] java 未找到（Canu mhap overlapper 需要）"; exit 1; }
command -v samtools >/dev/null || { echo "[ERROR] samtools 未找到（Canu overlap correction 需要）"; exit 1; }
[[ -f "$HIFI" ]] || { echo "[ERROR] 缺失 HiFi: $HIFI"; exit 1; }

mkdir -p "$OUT_BASE" "$LOG_DIR"

# -----------------------------------------------------------------------------
# 启动信息
# -----------------------------------------------------------------------------
{
    echo "============================================================"
    echo "Canu 组装启动 - PacBio HiFi"
    echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  线程数: $THREADS"
    echo "  内存上限: ${MEMORY} GB"
    echo "  数据:"
    echo "    HiFi: $HIFI"
    echo "  输出目录: $CANU_D"
    echo "  日志: $LOG_DIR/canu.log"
    echo "============================================================"
} | tee "$LOG_DIR/canu_startup.log"

# -----------------------------------------------------------------------------
# 运行 Canu
# -pacbio-hifi: HiFi 数据专用参数（Canu 自动跳过纠错，因 HiFi 已是高一致性 reads）
# genomeSize=12m: 酵母 14 Mb 上下界，圆整 12 Mb（参考酵母 R64 = 12.16 Mb）
# useGrid=false: 单机运行（不送集群调度）
# maxThreads: 限制并行线程
# maxMemory: 限制内存（GB）
# stopOnLowCoverage: 单 run 模式（不要多个 run）
#
# 其他 Canu 关键参数（使用默认值，本数据无需修改）：
#   minReadLength=1000（默认）
#     忽略 < 1000 bp 的 reads。HiFi 数据读长均 >1 Kb，默认已合适。
#     若用短读长（如部分 CLR <1Kb），可改为 500。
#   corMinCoverage=auto（默认根据覆盖自动：<30×=0, 30-60×=4, ≥60×=5）
#     纠错时支持每个碱基的最少 reads 数。本数据 ~47× 覆盖，自动用 4。
#     数据偏少时(<30×)改为 2；数据充足(>60×)改为 5。
#   corOutCoverage=40（默认）
#     仅对最长 reads 做纠错至该覆盖覆盖。本数据 ~47× 覆盖，默认 40 合适。
#     数据充足（HiFi >100×）可改为 80，让更多 reads 参与纠错。
#
# 本数据 ~47× HiFi 覆盖，所有上述参数走默认即可。强行手动指定反而易出错。
#
# 重要：本机 perl 反引号无法执行 `command -v`（builtin），导致 Canu 默认的
# mhap overlapper 做 java 版本检查时拿到空路径而报错
#   "mhap overlapper requires java version at least 1.8.0; you have unknown (from '')"
# 解决：改用 ovl overlapper（纯 C 实现，不需要 java），绕过 mhap。
#   代价：ovl 比 mhap 慢，但酵母 14 Mb 数据量小，影响可忽略。
# -----------------------------------------------------------------------------
START=$(date +%s)
canu \
    -d "$CANU_D" \
    -p "$CANU_P" \
    genomeSize=12m \
    -pacbio-hifi "$HIFI" \
    useGrid=false \
    corOverlapper=ovl \
    obtOverlapper=ovl \
    utgOverlapper=ovl \
    maxThreads="$THREADS" \
    maxMemory="$MEMORY" \
    stopOnLowCoverage=0 \
    > "$LOG_DIR/canu.log" 2>&1
EXIT_CODE=$?
END=$(date +%s)
ELAPSED=$((END - START))

# -----------------------------------------------------------------------------
# 结果汇报
# -----------------------------------------------------------------------------
if [[ $EXIT_CODE -eq 0 ]]; then
    {
        echo "============================================================"
        echo "组装完成 - Canu HiFi"
        echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
        echo ""
        echo "最终 contigs:    $CANU_D/$CANU_P.contigs.fasta"
        echo "最终 unitigs:    $CANU_D/$CANU_P.unitigs.fasta"
        echo "最终 unassembled: $CANU_D/$CANU_P.unassembled.fasta"
        echo "详细日志:        $LOG_DIR/canu.log"
        echo "============================================================"
    } | tee -a "$LOG_DIR/canu_startup.log"
else
    {
        echo "============================================================"
        echo "[ERROR] Canu 失败 - exit code $EXIT_CODE"
        echo "  耗时: ${ELAPSED}s"
        echo "  查看: $LOG_DIR/canu.log (tail)"
        echo "============================================================"
    } | tee -a "$LOG_DIR/canu_startup.log"
    tail -30 "$LOG_DIR/canu.log" >&2
    exit $EXIT_CODE
fi