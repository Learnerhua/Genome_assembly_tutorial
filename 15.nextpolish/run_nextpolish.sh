#!/usr/bin/env bash
# =============================================================================
# NextPolish 运行脚本 - 以 nextDenovo ONT 组装为例
# =============================================================================
# 目的：用 NextPolish 对 nextDenovo 组装做三代数据 polish（碱基一致性校对）
# 工具：NextPolish 1.4.1（git clone + make 编译版）
# 数据：ONT 长读（PRJEB19900 ont_merged）+ HiFi（SRR13577847）+ 短读 PE（ERR1938683 clean）
# 阶段：task=best 自动编排（ONT×2 + HiFi×2 + 短读×4）
# =============================================================================
# 用法：bash run_nextpolish.sh
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# NextPolish 路径
NEXTPOLISH_DIR="${DATA_ROOT}/Download/NextPolish"
NEXTPOLISH="${NEXTPOLISH_DIR}/nextPolish"

# genome_assembly 环境的 Python（含 paralleltask）
PYTHON_BIN="${CONDA_PREFIX}/bin/python"

# 线程数由 run.cfg 的 parallel_jobs × multithread_jobs 控制（当前 8×6=48）
# 注意：nextPolish 命令行无 -t 参数，线程只在配置文件中设置
THREADS_HINT="48 (parallel_jobs=8 × multithread_jobs=6)"

# run.cfg 路径
RUN_CFG="$SCRIPT_DIR/run.cfg"

# =============================================================================
# 前置检查
# =============================================================================
[[ -x "$NEXTPOLISH" ]] || { echo "[ERROR] nextPolish 不存在: $NEXTPOLISH"; exit 1; }
[[ -x "$PYTHON_BIN" ]] || { echo "[ERROR] Python 不存在: $PYTHON_BIN（需要 genome_assembly 环境）"; exit 1; }
"$PYTHON_BIN" -c "import paralleltask" 2>/dev/null || { echo "[ERROR] paralleltask 未装（conda activate genome_assembly && pip install paralleltask）"; exit 1; }
[[ -f "$RUN_CFG" ]] || { echo "[ERROR] run.cfg 不存在: $RUN_CFG"; exit 1; }

# 配置里的路径是相对于 SCRIPT_DIR，所以 cd
[[ -f "$SCRIPT_DIR/ont.fofn" ]] || { echo "[ERROR] ont.fofn 不存在: $SCRIPT_DIR/ont.fofn"; exit 1; }

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "NextPolish 启动"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  NextPolish: $NEXTPOLISH"
echo "  Python: $PYTHON_BIN"
echo "  线程: $THREADS_HINT"
echo "  run.cfg: $RUN_CFG"
echo "  阶段: task=best（ONT×2 + HiFi×2 + 短读×4）"
echo "============================================================"

# =============================================================================
# 运行 NextPolish
# =============================================================================
cd "$SCRIPT_DIR"
START=$(date +%s)

# nextPolish 命令行只接受 run.cfg 一个参数（无阶段参数），
# 阶段由 run.cfg 的 task 控制（task=best 自动编排全部可用阶段）
"$PYTHON_BIN" "$NEXTPOLISH" "$RUN_CFG" 2>&1

CODE=$?
END=$(date +%s)
ELAPSED=$((END - START))

echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "NextPolish 完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s ($(date -d@$ELAPSED -u +%Hh%Mm%Ss))"
    echo
    echo "产物: $SCRIPT_DIR/03.nextpolish/genome.nextpolish.fasta  （5 阶段都跑完）"
    echo "      各阶段目录: $SCRIPT_DIR/01.ngsep/  $SCRIPT_DIR/02.polish/"
    echo "                    $SCRIPT_DIR/03.purge/  $SCRIPT_DIR/04.r1.polish/"
    echo "                    $SCRIPT_DIR/05.r2.polish/"
    echo "============================================================"
else
    echo "NextPolish 失败 (exit $CODE)"
    echo "日志: $SCRIPT_DIR/nextPolish.log.*"
    exit $CODE
fi