#!/usr/bin/env bash
# =============================================================================
# QUAST 复评脚本 - 基于参考基因组评估 NextPolish 抛光效果
# =============================================================================
# 目的：用 QUAST（基于酵母参考基因组）对比抛光前 vs 抛光后的组装，
#       看 NA50/参考覆盖率/misassemblies 等指标的变化
# 工具：QUAST 5.3.0（Download/quast，wrapper 屏蔽 SyntaxWarning）
# =============================================================================
# 用法：bash run_quast_eval.sh
# 输出：15.nextpolish/quast_result/quast_compare/
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ---------------------------------------------------------------------------
# 路径配置
# ---------------------------------------------------------------------------
ORIGINAL_ASM="$PROJECT_ROOT/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/nd.asm.fasta"  # 抛光前
POLISHED_ASM="$SCRIPT_DIR/genome.nextpolish.fasta"    # 抛光后（NextPolish 产物）
REF="$PROJECT_ROOT/rawData/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz"  # 参考基因组
QUAST_WRAPPER="${DATA_ROOT}/Download/quast/quast.sh"  # QUAST wrapper
QUAST_OUT="$SCRIPT_DIR/quast_result"                   # 输出目录（独立）

# =============================================================================
# 前置检查
# =============================================================================
[[ -f "$ORIGINAL_ASM" ]] || { echo "[ERROR] 抛光前组装不存在: $ORIGINAL_ASM"; exit 1; }
[[ -f "$POLISHED_ASM" ]] || { echo "[ERROR] 抛光后组装不存在: $POLISHED_ASM（先跑 run_nextpolish.sh）"; exit 1; }
[[ -f "$REF" ]] || { echo "[ERROR] 参考基因组不存在: $REF"; exit 1; }
[[ -x "$QUAST_WRAPPER" ]] || { echo "[ERROR] QUAST 不存在: $QUAST_WRAPPER"; exit 1; }
mkdir -p "$QUAST_OUT"

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "QUAST 复评启动（抛光前 vs 抛光后，基于参考）"
echo "  启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  抛光前: $ORIGINAL_ASM"
echo "  抛光后: $POLISHED_ASM"
echo "  参考:   $REF"
echo "  输出:   $QUAST_OUT"
echo "============================================================"

# =============================================================================
# 运行 QUAST（双组装对比 + 参考）
# =============================================================================
# 关键参数：
#   两个 FASTA    抛光前 + 抛光后同时评估，输出对比表
#   -r 参考基因组（酵母 R64-1-1）→ 算 NA50/参考覆盖率/misassemblies
#   -t 1 --memory-efficient  绕开 joblib 多进程（Python 3.14 兼容）
#   -o 输出目录
#   -l "名称1,名称2"  对比表列名（方法名而非文件名）
# -----------------------------------------------------------------------------
cd "$SCRIPT_DIR"
START=$(date +%s)

"$QUAST_WRAPPER" \
    "$ORIGINAL_ASM" "$POLISHED_ASM" \
    -r "$REF" \
    -t 1 \
    --memory-efficient \
    -o "$QUAST_OUT/quast_compare" \
    -l "nextdenovo_raw,nextpolish_polished" 2>&1 | tee "$QUAST_OUT/quast_compare.log"

CODE=${PIPESTATUS[0]}
END=$(date +%s)
ELAPSED=$((END - START))

echo
echo "============================================================"
if [[ $CODE -eq 0 ]]; then
    echo "QUAST 复评完成"
    echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  耗时: ${ELAPSED}s"
    echo
    echo "结果: $QUAST_OUT/quast_compare/report.html（浏览器打开对比表）"
    echo "      $QUAST_OUT/quast_compare/report.tsv（机器可读）"
    echo "      （对比指标：NA50/NGA50/参考覆盖率/misassemblies 等）"
    echo "============================================================"
else
    echo "QUAST 复评失败 (exit $CODE)"
    echo "日志: $QUAST_OUT/quast_compare.log"
    exit $CODE
fi