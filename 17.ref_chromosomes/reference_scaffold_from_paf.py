#!/usr/bin/env python3
"""
reference_scaffold_from_paf.py — 纯参考引导挂载（无需 AGP）

只用 contig FASTA + contig 级 PAF（如 nextpolish.paf，query 为各 contig）
推导每条染色体的构成、顺序与方向，重建染色体级 FASTA。不依赖任何
Hi-C 挂载结果（yahs/3D-DNA 的 AGP 完全不需要）。

核心逻辑（RagTag 思路）：
  1. 每个 contig 取"最长"比对（不按 mapq，防端粒/rDNA 重复噪音）定染色体归属；
  2. 同一染色体内的 contig 按参考 tstart 排序；
  3. 比对链为 '-' 的 contig 取反向互补，使所有 contig 位于参考正链方向；
  4. 相邻 contig 在参考上重叠时（如 yahs 未去重的拼接），裁掉后一条 contig
     开头对应参考区间的冗余碱基（--no-trim-overlap 可关闭）；
  5. 染色体之间/内部以 N-gap（默认 100，AGP 规范的未知缺口占位符）连接。

用法（服务器，需要 contig FASTA）:
  python3 reference_scaffold_from_paf.py \
      --contigs nextpolish_output.fasta \
      --paf nextpolish.paf \
      --outdir 17.ref_scaffolding

预演（本地无 FASTA 也能出报告和 AGP，长度取自 PAF qlen）:
  python3 reference_scaffold_from_paf.py \
      --paf nextpolish.paf \
      --outdir preview

输出:
  ref_scaffold.fa      chrI–chrXVI + mtDNA（正向、已裁重叠、含 N-gap）
  ref_scaffold.agp     标准 AGP（引用原始 contig 名及使用的坐标区间）
  scaffold_report.txt  布局报告：构成、方向、裁剪量、长度校验
"""
import argparse
import os
import re
import sys

ROMAN = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
         "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13,
         "XIV": 14, "XV": 15, "XVI": 16}


def read_fasta(path):
    """读 FASTA 为 {name: seq}，名字取 > 后第一个空白前的字段。"""
    seqs, name, buf = {}, None, []
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith(">"):
                if name is not None:
                    seqs[name] = "".join(buf)
                name, buf = line[1:].split()[0], []
            else:
                buf.append(line.strip())
    if name is not None:
        seqs[name] = "".join(buf)
    return seqs


def revcomp(s):
    return s.translate(str.maketrans("ACGTNacgtnRYKMSWBDHVrykmswbdhv",
                                     "TGCANtgcanYRMKSWVHDByrmkswvhdb"))[::-1]


def parse_paf(path):
    """返回 {query_name: best_alignment_dict}，best = 比对块最长的一条。"""
    best = {}
    with open(path) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 12:
                continue
            qname, qlen = cols[0], int(cols[1])
            qstart, qend = int(cols[2]), int(cols[3])
            strand, tname, tlen = cols[4], cols[5], int(cols[6])
            tstart, tend, mapq = int(cols[7]), int(cols[8]), int(cols[11])
            aln_len = tend - tstart  # 参考上的跨度，比 query 跨度更抗 soft-clip 噪音
            if qname not in best or aln_len > best[qname]["aln_len"]:
                best[qname] = dict(qname=qname, qlen=qlen, qstart=qstart,
                                   qend=qend, strand=strand, tname=tname,
                                   tlen=tlen, tstart=tstart, tend=tend,
                                   mapq=mapq, aln_len=aln_len)
    return best


def chrom_sort_key(tname):
    """Mito 排最后，罗马数字按数值排序，其余按字母排前面。"""
    t = tname.strip()
    if t.lower() in ("mito", "mtdna", "mitochondrion", "chrmt"):
        return (2, 0, t)
    m = re.match(r"^(?:chr)?([IVX]+)$", t, re.I)
    if m and m.group(1).upper() in ROMAN:
        return (1, ROMAN[m.group(1).upper()], t)
    return (0, 0, t)


def chrom_label(tname):
    t = tname.strip()
    if t.lower() in ("mito", "mtdna", "mitochondrion", "chrmt"):
        return "mtDNA"
    m = re.match(r"^(?:chr)?([IVX]+)$", t, re.I)
    if m and m.group(1).upper() in ROMAN:
        return "chr" + m.group(1).upper()
    return t


def main():
    ap = argparse.ArgumentParser(description="Reference-guided scaffolding from contig-level PAF (AGP-free)")
    ap.add_argument("--contigs", help="contig FASTA（提供则输出 FASTA，否则仅报告+AGP）")
    ap.add_argument("--paf", required=True, help="contig 级 PAF（query=contig 名，如 minimap2 asm5 输出）")
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--gap-n", type=int, default=100,
                    help="相邻 contig 间 N-gap 长度，默认 100（AGP 规范占位符）")
    ap.add_argument("--no-trim-overlap", action="store_true",
                    help="不裁剪相邻 contig 在参考上的重叠（默认裁剪）")
    args = ap.parse_args()

    contigs = read_fasta(args.contigs) if args.contigs else {}
    best = parse_paf(args.paf)

    if not best:
        sys.exit("PAF 中没有可比对记录，退出。")

    # 按参考染色体分组
    groups = {}
    for aln in best.values():
        groups.setdefault(aln["tname"], []).append(aln)

    report, agp_lines, fasta_recs = [], [], []
    total_len, total_trim = 0, 0

    for tname in sorted(groups, key=chrom_sort_key):
        cname = chrom_label(tname)
        members = sorted(groups[tname], key=lambda a: a["tstart"])
        report.append("\n== %s  (ref %s, %s bp) ==\n"
                      % (cname, tname, "{:,}".format(members[0]["tlen"])))
        report.append("%-20s%10s  %-20s%6s%8s%10s\n"
                      % ("contig", "qlen", "ref_interval", "orient", "trim", "used"))

        seq_parts, pos, part = [], 1, 0
        prev_tend = None
        for aln in members:
            cid = aln["qname"]
            qlen = aln["qlen"]
            # 未比对前缀：比对起点在"参考正链方向序列"中的位置
            # （'-' 时正链方向序列 = revcomp，其起点对应原序列的 qend）
            lead = aln["qstart"] if aln["strand"] == "+" else qlen - aln["qend"]

            # 重叠裁剪
            trim = 0
            if prev_tend is not None and not args.no_trim_overlap:
                ref_overlap = prev_tend - aln["tstart"]
                if ref_overlap > 0:
                    trim = lead + ref_overlap  # 先删未比对前缀再删重叠
                    trim = max(0, min(trim, qlen - 1))
            used = qlen - trim

            # FASTA 序列（有 contigs 时）
            if contigs:
                seq = contigs.get(cid)
                if seq is None:
                    sys.exit(f"contig {cid} 不在 FASTA 中，请检查名字是否一致")
                if len(seq) != qlen:
                    print(f"[warn] {cid} FASTA 长度 {len(seq)} != PAF qlen {qlen}",
                          file=sys.stderr)
                    seq = seq[:qlen] if len(seq) > qlen else seq
                if aln["strand"] == "-":
                    seq = revcomp(seq)
                seq = seq[trim:]
                seq_parts.append(seq)

            # AGP：W 行（引用原始 contig 的使用区间）
            # 原始坐标区间：'+' 用 [trim+1, qlen]；'-' 用 [1, qlen-trim]（先revcomp再裁头部）
            if aln["strand"] == "+":
                cbeg, cend = trim + 1, qlen
                orient = "+"
            else:
                cbeg, cend = 1, qlen - trim
                orient = "-"
            if part > 0:
                agp_lines.append(f"{cname}\t{pos}\t{pos + args.gap_n - 1}\t{part * 2}\tU\t"
                                 f"{args.gap_n}\tscaffold\tyes\tproximity_ligation")
                if contigs:
                    seq_parts.append("N" * args.gap_n)
                pos += args.gap_n
            agp_lines.append(f"{cname}\t{pos}\t{pos + used - 1}\t{part * 2 + 1}\tW\t"
                             f"{cid}\t{cbeg}\t{cend}\t{orient}")
            pos += used
            total_trim += trim

            interval = "%d-%d" % (aln["tstart"], aln["tend"])
            report.append("%-20s%10d  %-20s%6s%8s%10d\n"
                          % (cid, qlen, interval, aln["strand"],
                             "{:,}".format(trim), used))
            part += 1
            prev_tend = aln["tend"]

        if contigs:
            fasta_recs.append((cname, "".join(seq_parts)))
        clen = pos - 1
        total_len += clen
        report.append("   -> %s: %d contig(s), %s bp\n"
                      % (cname, len(members), "{:,}".format(clen)))

    # 输出
    os.makedirs(args.outdir, exist_ok=True)
    rep_path = os.path.join(args.outdir, "scaffold_report.txt")
    with open(rep_path, "w") as f:
        f.write("reference_scaffold_from_paf.py — 纯 PAF 参考引导挂载报告\n")
        f.write(f"输入 PAF: {args.paf}\n")
        f.write(f"contig 数: {len(best)}  染色体数: {len(groups)}\n")
        f.write(f"N-gap: {args.gap_n}  重叠裁剪: {'关闭' if args.no_trim_overlap else '开启'}\n")
        f.write(f"总长(含gap): {total_len:,} bp  总裁剪: {total_trim:,} bp\n")
        f.writelines(report)
        f.write("\n")

    agp_path = os.path.join(args.outdir, "ref_scaffold.agp")
    with open(agp_path, "w") as f:
        f.write("\n".join(agp_lines) + "\n")

    fa_path = None
    if contigs:
        fa_path = os.path.join(args.outdir, "ref_scaffold.fa")
        with open(fa_path, "w") as f:
            for name, seq in fasta_recs:
                f.write(f">{name}\n")
                for i in range(0, len(seq), 60):
                    f.write(seq[i:i + 60] + "\n")

    print(f"Wrote {rep_path}")
    print(f"Wrote {agp_path}")
    if fa_path:
        print(f"Wrote {fa_path}")


if __name__ == "__main__":
    main()
