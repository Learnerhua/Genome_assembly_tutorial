#!/usr/bin/env bash
# =============================================================================
# Hi-C 染色体挂载脚本（bwa + yahs + juicer_tools）
# =============================================================================
# 目的：用 Hi-C 数据将 contigs 挂载到染色体水平（scaffolding）
# 输入：抛光后组装（genome.nextpolish.fasta）+ Hi-C reads（SRR28065402）
# 工具：bwa（比对）+ samtools（排序去重）+ yahs（挂载）+ juicer（热图）
# 参考：YaHS README（https://github.com/c-zhou/yahs）
# =============================================================================
# 用法：bash run_hic_scaffolding.sh
# 输出：16.hic_scaffolding/ 目录
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ---------------------------------------------------------------------------
# 路径配置
# ---------------------------------------------------------------------------
# 输入：抛光后组装（建议用 NextPolish 抛光版，碱基准确）
CONTIGS="$PROJECT_ROOT/15.nextpolish/genome.nextpolish.fasta"
# Hi-C reads（用户下载到 HiC_wget/ 目录）
HIC_1="$PROJECT_ROOT/rawData/HiC_wget/SRR28065402_1.fastq.gz"
HIC_2="$PROJECT_ROOT/rawData/HiC_wget/SRR28065402_2.fastq.gz"

# 工具路径（绝对路径，不依赖 PATH）
BWA="${DATA_ROOT}/Download/NextPolish/bin/bwa"
YAHS="${DATA_ROOT}/Download/yahs/yahs"
JUICER="${DATA_ROOT}/Download/yahs/juicer"
SAMTOOLS="${CONDA_PREFIX}/bin/samtools"

# juicer_tools.jar：生成 .hic 热图（可选，未装也不影响挂载）
JUICER_JAR="${JUICER_JAR:-${DATA_ROOT}/Download/juicer_tools/juicer_tools.2.20.00.jar}"

# 线程配置
THREADS="${THREADS:-48}"            # 比对/sort/juicer_tools 用
MARKDUP_THREADS="${MARKDUP_THREADS:-16}"  # markdup 单独（I/O 密集）

# 启动 juicer 步骤（默认 on；设 RUN_JUICER=0 跳过）
RUN_JUICER="${RUN_JUICER:-1}"

# Java 堆内存
JAVA_MEM="${JAVA_MEM:-32G}"

# 输出目录
OUT_DIR="$PROJECT_ROOT/16.hic_scaffolding"
WORK_DIR="$OUT_DIR/01.work"
mkdir -p "$OUT_DIR" "$WORK_DIR"

# =============================================================================
# 前置检查
# =============================================================================
[[ -f "$CONTIGS" ]] || { echo "[ERROR] 组装不存在: $CONTIGS（先跑 NextPolish）"; exit 1; }
[[ -f "$HIC_1" && -f "$HIC_2" ]] || { echo "[ERROR] Hi-C reads 不存在: $HIC_1 / $HIC_2（先下载）"; exit 1; }
for t in "$BWA" "$YAHS" "$JUICER" "$SAMTOOLS"; do
    [[ -x "$t" ]] || { echo "[ERROR] 工具缺失: $t"; exit 1; }
done

# =============================================================================
# 启动信息
# =============================================================================
echo "============================================================"
echo "Hi-C 染色体挂载启动"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  组装: $CONTIGS"
echo "  Hi-C: $HIC_1 + $HIC_2"
echo "  线程: $THREADS (markdup: $MARKDUP_THREADS)"
echo "  输出: $OUT_DIR"
echo "============================================================"

cd "$WORK_DIR"
START=$(date +%s)

# =============================================================================
# Step 1: samtools faidx（组装索引）
# =============================================================================
echo ""
echo ">>> [1/6] 索引组装（samtools faidx）..."
"$SAMTOOLS" faidx "$CONTIGS" || { echo "[ERROR] faidx 失败"; exit 1; }
echo "  ✓ $(basename $CONTIGS).fai 已生成"

# =============================================================================
# Step 2: bwa index + bwa mem 比对
# =============================================================================
# 关键参数：
#   index     建立 BWA BWT 索引（如果未建）
#   mem -5SP  Hi-C 模式：
#     -5    标记 chimera/跨连接（Hi-C 重要）
#     -S    跳过 mate rescue（避免 mate 移到不同 contig）
#     -P    只输出唯一比对（减少冗余）
#   -t       线程
echo ""
echo ">>> [2/6] bwa index + bwa mem 比对..."
if [[ ! -f "$CONTIGS.bwt" ]]; then
    echo "  bwa index..."
    "$BWA" index "$CONTIGS" 2>"$WORK_DIR/bwa_index.log" || { echo "[ERROR] bwa index 失败"; exit 1; }
    echo "  ✓ 索引完成"
fi
echo "  bwa mem -5SP -t $THREADS ..."
"$BWA" mem -5SP -t "$THREADS" \
    "$CONTIGS" "$HIC_1" "$HIC_2" \
    > "$WORK_DIR/hic.sam" 2>"$WORK_DIR/bwa_mem.log" || { echo "[ERROR] bwa mem 失败"; exit 1; }
echo "  ✓ hic.sam 生成"

# =============================================================================
# Step 3: samtools view + sort + markdup
# =============================================================================
# 关键参数：
#   view -b        SAM → BAM（二进制）
#   sort -n        按 read 名排序（YaHS 推荐——同 pair 紧邻）
#   fixmate -m     添加 ms score tag（markdup 必需）+ 补 mate 信息
#   sort           第二次 sort 为坐标排序（markdup 需要）
#   markdup        标记/移除 PCR duplicate（Hi-C 文库建议去重）
#   index          生成 BAM 索引（YaHS 需要）
echo ""
echo ">>> [3/6] samtools view + sort + fixmate + markdup..."
"$SAMTOOLS" view -@ "$THREADS" -b "$WORK_DIR/hic.sam" -o "$WORK_DIR/hic.unsorted.bam" \
    || { echo "[ERROR] SAM→BAM 失败"; exit 1; }
rm -f "$WORK_DIR/hic.sam"  # 节省空间
"$SAMTOOLS" sort -@ "$THREADS" -n -o "$WORK_DIR/hic.sorted_by_name.bam" "$WORK_DIR/hic.unsorted.bam" \
    || { echo "[ERROR] sort-by-name 失败"; exit 1; }
rm -f "$WORK_DIR/hic.unsorted.bam"
"$SAMTOOLS" fixmate -@ "$THREADS" -m "$WORK_DIR/hic.sorted_by_name.bam" "$WORK_DIR/hic.fixmate.bam" \
    || { echo "[ERROR] fixmate 失败"; exit 1; }
rm -f "$WORK_DIR/hic.sorted_by_name.bam"
"$SAMTOOLS" sort -@ "$THREADS" -o "$WORK_DIR/hic.sorted_by_pos.bam" "$WORK_DIR/hic.fixmate.bam" \
    || { echo "[ERROR] sort-by-pos 失败"; exit 1; }
rm -f "$WORK_DIR/hic.fixmate.bam"
"$SAMTOOLS" markdup -@ "$MARKDUP_THREADS" "$WORK_DIR/hic.sorted_by_pos.bam" "$WORK_DIR/hic.markdup.bam" \
    || { echo "[ERROR] markdup 失败"; exit 1; }
rm -f "$WORK_DIR/hic.sorted_by_pos.bam"
"$SAMTOOLS" index "$WORK_DIR/hic.markdup.bam" || { echo "[ERROR] index 失败"; exit 1; }
echo "  ✓ hic.markdup.bam 生成（duplicate 已打 flag，未删除）"

# =============================================================================
# Step 4: YaHS 脚手架挂载
# =============================================================================
# 关键参数：
#   -o 前缀    输出文件名（生成 scaffold_scaffolds_final.{fa,agp} + scaffold.bin）
#   使用 YaHS 默认参数（断点 1000-500000，适合 12 Mb yeast）
echo ""
echo ">>> [4/6] YaHS 脚手架挂载..."
"$YAHS" \
    -o "$OUT_DIR/scaffold" \
    "$CONTIGS" "$WORK_DIR/hic.markdup.bam" \
    || { echo "[ERROR] yahs 失败"; exit 1; }
echo "  ✓ scaffold 结果已生成"

# =============================================================================
# Step 5: 检查最终产物
# =============================================================================
echo ""
echo ">>> [5/6] 检查最终产物..."
ls -lh "$OUT_DIR"/scaffold_scaffolds_final.* 2>&1 | head -5
[[ -f "$OUT_DIR/scaffold_scaffolds_final.fa" ]] || { echo "[WARN] 最终 FASTA 未生成"; }

# =============================================================================
# Step 6: juicer pre + juicer_tools
# =============================================================================
if [[ "$RUN_JUICER" == "1" ]]; then
    echo ""
    echo ">>> [6/6] juicer pre + juicer_tools（生成 .hic 热图）..."

    "$SAMTOOLS" faidx "$OUT_DIR/scaffold_scaffolds_final.fa" 2>/dev/null || true
    cut -f1,2 "$OUT_DIR/scaffold_scaffolds_final.fa.fai" > "$OUT_DIR/chrom.sizes"

    AGP="$OUT_DIR/scaffold_scaffolds_final.agp"
    BIN="$OUT_DIR/scaffold.bin"
    FAI="$CONTIGS.fai"

    if [[ ! -f "$BIN" || ! -f "$AGP" || ! -f "$FAI" ]]; then
        echo "  [WARN] juicer pre 缺少必要输入文件，跳过"
        echo "    bin: $BIN $([ -f "$BIN" ] && echo "✅" || echo "❌")"
        echo "    agp: $AGP $([ -f "$AGP" ] && echo "✅" || echo "❌")"
        echo "    fai: $FAI $([ -f "$FAI" ] && echo "✅" || echo "❌")"
    else
        # 6a: juicer pre → alignments_sorted.txt + Juicebox JBAT 文件（手动编辑用）
        #     -a    生成 JBAT 兼容文件（.assembly/.liftover.agp/.txt），用于 Juicebox 手动调整
        #     -o    输出前缀（仅对 -a 模式生效）
        "$JUICER" pre -a -o "$OUT_DIR/jbat" "$BIN" "$AGP" "$FAI" \
            > "$OUT_DIR/jbat.log" 2>&1
        echo "  ✓ JBAT 文件（jbat.assembly/.liftover.agp/.txt）"

        # 6a.2: 同时生成 alignments_sorted.txt（用于 juicer_tools → .hic）
        "$JUICER" pre "$BIN" "$AGP" "$FAI" \
            | sort -k2,2d -k6,6d -T "$OUT_DIR" --parallel=8 -S32G \
            | awk 'NF' > "$OUT_DIR/alignments_sorted.txt"
        echo "  ✓ alignments_sorted.txt"

        # 6b: juicer_tools → .hic
        if [[ ! -f "$JUICER_JAR" ]]; then
            echo "  [WARN] juicer_tools.jar 不存在: $JUICER_JAR"
            echo "         下载: wget https://github.com/aidenlab/Juicebox/releases/download/v2.20.00/juicer_tools.2.20.00.jar"
        else
            java -Xmx"$JAVA_MEM" -jar "$JUICER_JAR" pre \
                --threads "$THREADS" \
                "$OUT_DIR/alignments_sorted.txt" \
                "$OUT_DIR/scaffold.hic.part" \
                "$OUT_DIR/chrom.sizes" \
                && mv "$OUT_DIR/scaffold.hic.part" "$OUT_DIR/scaffold.hic" \
                || { echo "[ERROR] juicer_tools 失败"; }
            echo "  ✓ scaffold.hic"
        fi
    fi
else
    echo ""
    echo ">>> [6/6] juicer 步骤已跳过（RUN_JUICER=$RUN_JUICER）"
fi

END=$(date +%s)
ELAPSED=$((END - START))
echo ""
echo "============================================================"
echo "Hi-C 挂载完成"
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  耗时: ${ELAPSED}s"
echo ""
echo "  核心产物:"
echo "    $OUT_DIR/scaffold_scaffolds_final.fa   挂载后染色体序列"
echo "    $OUT_DIR/scaffold_scaffolds_final.agp  AGP 文件"
echo "    $OUT_DIR/scaffold.bin                    YaHS 中间格式"
if [[ "$RUN_JUICER" == "1" ]]; then
    echo ""
    echo "  可视化产物:"
    echo "    $OUT_DIR/alignments_sorted.txt         Juicebox 输入"
    echo "    $OUT_DIR/scaffold.hic                  Hi-C 热图"
    echo "    可视化: Juicebox.js (https://www.aidenlab.org/juicebox.js)"
fi
echo "============================================================"