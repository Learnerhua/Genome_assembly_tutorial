#!/usr/bin/env python3
"""
用线粒体密码子表（NCBI table 3）翻译 liftoff 后的线粒体 CDS。

背景：
- gffread 的 -y 只用标准密码子表（table 1），对线粒体基因会译错。
- 酵母线粒体密码子表（table 3）与标准表差异：
    AUA: Ile -> Met（线粒体）
    CUN: Leu -> Thr（酵母线粒体特有）
    UGA: Stop -> Trp
- 本脚本从 mito_liftoff.gff3 提取每个 mRNA 的 CDS 坐标（拼接外显子），
  从目标线粒体 FASTA 切出序列，按 table 3 翻译。

用法：
    python3 translate_mito.py <gff3> <fasta> <output>
"""
import sys
from collections import defaultdict
from Bio.Seq import Seq
from Bio.Data import CodonTable


def parse_gff3(path):
    """返回 {mrna_id: [(chr, start, end, strand), ...]}（CDS 片段列表）"""
    cds_by_mrna = defaultdict(list)
    with open(path) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9 or cols[2] != "CDS":
                continue
            chrom, start, end, strand = cols[0], int(cols[3]), int(cols[4]), cols[6]
            attrs = dict(kv.split("=", 1) for kv in cols[8].split(";") if "=" in kv)
            mrna_id = None
            for key in ("Parent", "ID"):
                if key in attrs:
                    mrna_id = attrs[key].split(",")[0]
                    break
            if mrna_id:
                cds_by_mrna[mrna_id].append((chrom, start, end, strand))
    return cds_by_mrna


def read_fasta(path):
    seqs, name, buf = {}, None, []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line.startswith(">"):
                if name is not None:
                    seqs[name] = "".join(buf)
                name = line[1:].split()[0]
                buf = []
            elif name:
                buf.append(line.upper())
    if name is not None:
        seqs[name] = "".join(buf)
    return seqs


def main():
    gff3, fasta, out = sys.argv[1], sys.argv[2], sys.argv[3]
    cds_by_mrna = parse_gff3(gff3)
    seqs = read_fasta(fasta)
    table = CodonTable.generic_by_id[3]  # 线粒体密码子表

    records = []
    for mrna_id, cds_list in sorted(cds_by_mrna.items()):
        # 排序 CDS 片段（按坐标）
        cds_list.sort(key=lambda c: c[1])
        strand = cds_list[0][3]
        parts = []
        for chrom, start, end, s in cds_list:
            if chrom not in seqs:
                continue
            seg = seqs[chrom][start - 1:end]
            parts.append(seg)
        if not parts:
            continue
        cds_seq = "".join(parts)
        if strand == "-":
            cds_seq = str(Seq(cds_seq).reverse_complement())
        # 翻译（线粒体密码子表），去除末端 stop
        prot = str(Seq(cds_seq).translate(table=table, to_stop=True))
        records.append((mrna_id, prot))

    with open(out, "w") as f:
        for name, prot in records:
            f.write(f">{name}\n")
            for i in range(0, len(prot), 60):
                f.write(prot[i:i + 60] + "\n")
    print(f"Wrote {out}: {len(records)} proteins (mitochondrial codon table)")


if __name__ == "__main__":
    main()
