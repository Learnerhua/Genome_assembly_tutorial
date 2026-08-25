#!/usr/bin/env bash
# =============================================================================
# BUSCO 内部调用包装（确保 PATH/PYTHONPATH 正确后 exec busco）
# =============================================================================
# 关键：busco 内部用 multiprocessing.spawn 启动子进程，子进程需要：
#   1. python 在 PATH 中（否则 spawn 找不到 python 解释器）
#   2. busco 包 site-packages 在 PYTHONPATH 中（否则子进程 import busco 失败）
#   3. hmmsearch/blastp/prodigal/augustus/miniprot 在 PATH 中（BUSCO 调用的工具）
# 通过此 wrapper 设置正确环境后用 exec 替换当前 shell，避免污染调用者环境
# =============================================================================

set -uo pipefail

# 1. busco 环境的 bin（hmmsearch/blastp/prodigal/augustus/miniprot 等）
export PATH="${BUSCO_BIN}:$PATH"

# 2. busco 环境的 site-packages（PYTHONPATH 可能未定义，用 ${VAR:+...} 防御）
BUSCO_PYTHONPATH="${BUSCO_ENV}/lib/python3.12/site-packages"
export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}${BUSCO_PYTHONPATH}"

# 调用 BUSCO（用 exec 替换当前 shell 进程，保持环境变量继承）
# -----------------------------------------------------------------------------
# 参数说明：
#   -i $1               输入组装 FASTA 路径（nextdenovo 拼接结果）
#   -l $2               谱系数据集名称（saccharomycetaceae_odb12.2，对应 3105 个酵母 BUSCO）
#   -o $3               输出子目录名（BUSCO 在 --out_path 下创建该名称的子目录）
#   -m genome           运行模式：genome（基因组组装评估；另可用 tran 转录组、prot 蛋白）
#   -c $4               线程数（本项目设为 48）
#   --out_path $5       BUSCO 输出的父目录
#   --download_path $6  谱系数据集所在目录（含 lineages/ 子目录）
#   --offline           离线模式：跳过网络下载，直接用本地数据
#   -f                  强制覆盖已存在的输出目录（重跑时避免 BUSCO 报错）
# -----------------------------------------------------------------------------
exec busco \
    -i "$1" \
    -l "$2" \
    -o "$3" \
    -m genome \
    -c "$4" \
    --out_path "$5" \
    --download_path "$6" \
    --offline \
    -f