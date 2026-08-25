#!/usr/bin/env python3
# =============================================================================
# 组装结果统计脚本（N50/N90/总长/GC/N含量）
# =============================================================================
# 用途：SPAdes / SOAPdenovo2 等组装工具不输出最终统计报告，
#       本脚本直接从 FASTA 计算组装质量指标。
# 用法：
#   python3 assembly_stats.py scaffolds.fasta
#   python3 assembly_stats.py --label "方案1 仅Illumina" --time 11m57s 01.illumina_only/scaffolds.fasta
#   python3 assembly_stats.py \
#       --label "方案1 仅Illumina" --time 11m57s 01.illumina_only/scaffolds.fasta \
#       --label "方案2 +HiFi"      --time 18m39s 02.illumina_hifi/scaffolds.fasta
# =============================================================================

import sys


def fasta_stats(path):
    """统计单个 FASTA 文件的组装指标。

    返回 dict：
      n       序列数
      total   总长度（含 N）
      max_len 最长序列
      n50     N50（长度降序累加至总长 50% 处的序列长度）
      n90     N90（同上，90% 处）
      gc      GC 含量（G+C / (A+C+G+T)，不含 N）
      n_count N 碱基总数（scaffold 中未确定碱基，越少越好）
    """
    lengths = []
    n_count = 0
    gc = 0
    letters = 0
    with open(path) as f:
        cur = []
        for line in f:
            if line.startswith(">"):
                if cur:
                    seq = "".join(cur).upper()
                    lengths.append(len(seq))
                    n_count += seq.count("N")
                    letters += len(seq) - seq.count("N")
                    gc += sum(1 for c in seq if c in "GC")
                cur = []
            else:
                cur.append(line.strip())
        if cur:  # 最后一条序列
            seq = "".join(cur).upper()
            lengths.append(len(seq))
            n_count += seq.count("N")
            letters += len(seq) - seq.count("N")
            gc += sum(1 for c in seq if c in "GC")

    lengths.sort(reverse=True)
    total = sum(lengths)
    half = total / 2
    cum = 0
    n50 = n90 = None
    for L in lengths:
        cum += L
        if n50 is None and cum >= half:
            n50 = L
        if n90 is None and cum >= total * 0.9:
            n90 = L

    return {
        "n": len(lengths),
        "total": total,
        "max_len": lengths[0] if lengths else 0,
        "n50": n50 or 0,
        "n90": n90 or 0,
        "gc": gc / letters * 100 if letters else 0,
        "n_count": n_count,
    }


def parse_args(argv):
    """解析命令行参数，支持 --label / --time 前缀标注。

    返回 [(label, time, path), ...]，label/time 为 None 时用文件路径/空串。
    """
    items = []
    label = None
    time_ = None
    for a in argv:
        if a == "--label":
            label = None  # 下一参数
        elif a == "--time":
            time_ = None  # 下一参数
        elif label is None and time_ is None and a in ("--label", "--time"):
            pass
        elif label is None and a != "--time" and time_ is None:
            # 当前是 --label 的值？
            pass
        else:
            pass
    # 简单实现：顺序扫描
    items = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--label":
            label = argv[i + 1]
            i += 2
        elif a == "--time":
            time_ = argv[i + 1]
            i += 2
        else:
            items.append((label, time_, a))
            label = None
            time_ = None
            i += 1
    return items


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    items = parse_args(sys.argv[1:])
    if not items:
        print(__doc__)
        sys.exit(1)

    print(f"{'方案':<18} {'耗时':<9} {'Scaffold 数':<11} {'总长 (bp)':<13} "
          f"{'N50 (bp)':<10} {'N90 (bp)':<9} {'最长 (bp)':<10} {'GC%':<7} {'N 含量 (bp)'}")
    print("-" * 115)
    for label, time_, path in items:
        try:
            s = fasta_stats(path)
        except FileNotFoundError:
            print(f"{label or path:<18} {time_ or '':<9} [文件不存在]")
            continue
        lab = label if label else path
        t = time_ if time_ else ""
        print(f"{lab:<18} {t:<9} {s['n']:<11,} {s['total']:<13,} {s['n50']:<10,} "
              f"{s['n90']:<9,} {s['max_len']:<10,} {s['gc']:<7.2f} {s['n_count']:,}")


if __name__ == "__main__":
    main()