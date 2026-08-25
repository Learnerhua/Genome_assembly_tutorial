#!/usr/bin/env python3
"""
Fix S288C yeast Hi-C scaffolding misassemblies (v2).

Works with EITHER scaffold-level or contig-level PAF:
  - scaffold-level PAF (query = scaffold_1, scaffold_2, ...): contigs are assigned
    to chromosomes via AGP coordinate mapping + overlap with PAF query intervals.
  - contig-level PAF (query = contig names): direct assignment.

Usage:
  python3 fix_yeast_hic_scaffold.py \
      --agp scaffold_scaffolds_final.agp \
      --paf scaffold_hic.paf \
      [--contigs polished_contigs.fa] \
      --outdir 17.fixed_scaffolding

Inputs:
  --agp       3D-DNA/yahs final AGP
  --paf       minimap2 PAF vs S288C R64 (asm5)
  --contigs   polished contig FASTA (optional; without it only AGP+report are written)

Outputs (in --outdir):
  fixed_chromosomes.fa   chrI..chrXVI + mtDNA, oriented to reference forward strand
  fixed_chromosomes.agp  AGP referencing ORIGINAL contig names and their new placement
  fix_report.txt         which scaffolds were split, chromosome composition

Logic:
  1. For each contig, find the PAF primary alignment (tp:A:P) whose query interval
     maximally overlaps the contig's span inside its scaffold (via AGP).
  2. Contig -> chromosome = alignment target name.
     Contig orientation vs reference = flip(alignment strand) if AGP placed it
     reversed, else alignment strand.
  3. Split scaffolds where adjacent contigs map to different chromosomes;
     keep same-chromosome joins (chrIV, chrXVI).
  4. Order contigs within a chromosome by their interpolated reference coordinate.
  5. Emit chrI..chrXVI (+ mtDNA) sequences and AGP.
"""

import argparse
import os
import sys
from collections import defaultdict

RC = str.maketrans("ACGTacgtNn", "TGCAtgcaNn")

CHROM_ORDER = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII",
               "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "Mito"]


def reverse_complement(seq):
    return seq.translate(RC)[::-1]


def read_fasta(path):
    seqs = {}
    name = None
    buf = []
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith(">"):
                if name is not None:
                    seqs[name] = "".join(buf)
                name = line[1:].split()[0]
                buf = []
            else:
                buf.append(line)
        if name is not None:
            seqs[name] = "".join(buf)
    return seqs


def write_fasta(path, records):
    with open(path, "w") as f:
        for name, seq in records:
            f.write(f">{name} len={len(seq)}\n")
            for i in range(0, len(seq), 60):
                f.write(seq[i:i + 60] + "\n")


def parse_paf(path):
    """Return list of primary alignments (dicts). Falls back to mapq>0 lines
    when no tp:A:P tags are present."""
    recs = []
    with open(path) as f:
        for line in f:
            if not line.strip():
                continue
            cols = line.rstrip().split("\t")
            if len(cols) < 12:
                continue
            tp = None
            for c in cols[12:]:
                if c.startswith("tp:A:"):
                    tp = c[5:]
                    break
            recs.append({
                "qname": cols[0], "qlen": int(cols[1]),
                "qstart": int(cols[2]), "qend": int(cols[3]),
                "strand": cols[4], "tname": cols[5],
                "tstart": int(cols[7]), "tend": int(cols[8]),
                "matches": int(cols[9]), "mapq": int(cols[11]), "tp": tp,
            })
    primary = [r for r in recs if r["tp"] == "P"]
    if not primary:
        primary = [r for r in recs if r["mapq"] > 0 or r["tp"] is None]
    return primary


def parse_agp(path):
    """Return list of scaffolds; each component carries its span in the
    scaffold object (obj_start/obj_end) and placement strand."""
    scaffolds = []
    by_name = {}
    with open(path) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.rstrip().split("\t")
            if cols[4] != "W":
                continue
            scaf_name = cols[0]
            if scaf_name not in by_name:
                by_name[scaf_name] = {"name": scaf_name, "components": []}
                scaffolds.append(by_name[scaf_name])
            by_name[scaf_name]["components"].append({
                "cid": cols[5],
                "cstart": int(cols[6]), "cend": int(cols[7]),
                "agp_strand": cols[8],
                "obj_start": int(cols[1]), "obj_end": int(cols[2]),
            })
    return scaffolds


def flip(s):
    return "+" if s == "-" else "-"


def overlap(a1, a2, b1, b2):
    return max(0, min(a2, b2) - max(a1, b1) + 1)


def main():
    ap = argparse.ArgumentParser(description="Fix yeast Hi-C scaffolding misassemblies")
    ap.add_argument("--contigs", help="Polished contig FASTA (optional)")
    ap.add_argument("--agp", required=True, help="Final AGP from yahs/3D-DNA")
    ap.add_argument("--paf", required=True, help="minimap2 PAF vs reference")
    ap.add_argument("--outdir", default=".", help="Output directory")
    ap.add_argument("--gap-n", type=int, default=100, help="Ns between joined contigs")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    contigs = {}
    if args.contigs:
        sys.stderr.write("Reading contigs FASTA...\n")
        contigs = read_fasta(args.contigs)

    sys.stderr.write("Reading PAF...\n")
    alignments = parse_paf(args.paf)
    align_by_q = defaultdict(list)
    for a in alignments:
        align_by_q[a["qname"]].append(a)

    sys.stderr.write("Reading AGP...\n")
    scaffolds = parse_agp(args.agp)

    paf_queries = set(align_by_q.keys())
    agp_contig_names = {c["cid"] for s in scaffolds for c in s["components"]}
    scaffold_names = {s["name"] for s in scaffolds}

    # Decide PAF mode
    contig_level = len(paf_queries & agp_contig_names) >= len(paf_queries & scaffold_names)
    mode = "contig-level PAF" if contig_level else "scaffold-level PAF"
    sys.stderr.write(f"PAF mode: {mode}\n")

    # ---- assign each contig: chromosome, ref strand, ref coordinate ----
    contig_info = {}   # cid -> dict(chrom, ref_strand, ref_pos)
    unassigned = []

    if contig_level:
        for cid in agp_contig_names:
            best = None
            for a in align_by_q.get(cid, []):
                if best is None or a["matches"] > best["matches"]:
                    best = a
            if best is None:
                unassigned.append(cid)
                continue
            contig_info[cid] = {
                "chrom": best["tname"],
                "ref_strand": best["strand"],
                "ref_pos": (best["tstart"] + best["tend"]) / 2,
            }
    else:
        for scaf in scaffolds:
            scaf_aligns = align_by_q.get(scaf["name"], [])
            for comp in scaf["components"]:
                best, best_ov = None, 0
                for a in scaf_aligns:
                    ov = overlap(comp["obj_start"], comp["obj_end"],
                                 a["qstart"], a["qend"])
                    if ov > best_ov:
                        best, best_ov = a, ov
                if best is None or best_ov == 0:
                    unassigned.append(comp["cid"])
                    continue
                # reference position of contig midpoint (linear interpolation)
                qmid = (comp["obj_start"] + comp["obj_end"]) / 2
                span = best["qend"] - best["qstart"]
                frac = 0.0 if span <= 0 else (qmid - best["qstart"]) / span
                tlen = best["tend"] - best["tstart"]
                if best["strand"] == "+":
                    ref_pos = best["tstart"] + frac * tlen
                else:
                    ref_pos = best["tend"] - frac * tlen
                ref_strand = best["strand"] if comp["agp_strand"] == "+" \
                    else flip(best["strand"])
                contig_info[comp["cid"]] = {
                    "chrom": best["tname"],
                    "ref_strand": ref_strand,
                    "ref_pos": ref_pos,
                }

    # ---- split scaffolds at chromosome boundaries ----
    chrom_pieces = defaultdict(list)   # chrom -> list of cid (in scaffold order)
    split_log = []
    for scaf in scaffolds:
        groups = []
        cur = [scaf["components"][0]]
        cur_chrom = contig_info.get(cur[0]["cid"], {}).get("chrom", "?")
        for comp in scaf["components"][1:]:
            c = contig_info.get(comp["cid"], {}).get("chrom", "?")
            if c == cur_chrom and c != "?":
                cur.append(comp)
            else:
                groups.append((cur_chrom, cur))
                cur = [comp]
                cur_chrom = c
        groups.append((cur_chrom, cur))
        if len(groups) > 1:
            split_log.append((scaf["name"], [g[0] for g in groups]))
        for chrom, group in groups:
            if chrom == "?":
                continue
            chrom_pieces[chrom].extend(c["cid"] for c in group)

    # ---- order contigs within chromosome by reference coordinate ----
    for chrom in chrom_pieces:
        chrom_pieces[chrom].sort(key=lambda cid: contig_info[cid]["ref_pos"])

    # ---- emit ----
    report = ["# Yeast Hi-C scaffolding correction report\n"]
    report.append(f"PAF mode: {mode}\n")
    report.append(f"Input scaffolds: {len(scaffolds)}\n")
    report.append(f"Split events: {len(split_log)}\n")
    for name, chroms in split_log:
        report.append(f"  {name} split into: {' + '.join(chroms)}\n")
    report.append("\n# Chromosome composition (contigs ordered by reference position, "
                  "strand relative to reference):\n")

    final_records = []
    agp_lines = []
    for chrom in CHROM_ORDER:
        if chrom not in chrom_pieces:
            continue
        cids = chrom_pieces[chrom]
        cname = "mtDNA" if chrom == "Mito" else f"chr{chrom}"
        parts = []
        desc = []
        for i, cid in enumerate(cids):
            info = contig_info[cid]
            seq = contigs.get(cid)
            if seq is None:
                if args.contigs:
                    sys.stderr.write(f"WARNING: {cid} missing from contigs FASTA\n")
                seq = ""
            if info["ref_strand"] == "-":
                seq = reverse_complement(seq)
            parts.append(seq)
            desc.append(f"{cid}({info['ref_strand']})")
            if i < len(cids) - 1:
                parts.append("N" * args.gap_n)
        full = "".join(parts)
        final_records.append((cname, full))
        report.append(f"{cname}  ({len(cids)} contig(s), {len(full):,} bp): "
                      f"{', '.join(desc)}\n")

        # AGP referencing ORIGINAL contig sequences
        pos = 1
        for i, cid in enumerate(cids):
            clen = len(contigs[cid]) if args.contigs and cid in contigs else 0
            if clen:
                agp_lines.append(
                    f"{cname}\t{pos}\t{pos + clen - 1}\t{i * 2 + 1}\tW\t"
                    f"{cid}\t1\t{clen}\t{contig_info[cid]['ref_strand']}")
                pos += clen
            if i < len(cids) - 1:
                agp_lines.append(
                    f"{cname}\t{pos}\t{pos + args.gap_n - 1}\t{i * 2 + 2}\tU\t"
                    f"{args.gap_n}\tscaffold\tyes\tproximity_ligation")
                pos += args.gap_n

    if unassigned:
        report.append(f"\n# Contigs with no PAF assignment ({len(unassigned)}):\n")
        for cid in unassigned:
            report.append(f"  {cid}\n")

    out_report = os.path.join(args.outdir, "fix_report.txt")
    with open(out_report, "w") as f:
        f.writelines(report)

    out_agp = os.path.join(args.outdir, "fixed_chromosomes.agp")
    with open(out_agp, "w") as f:
        f.write("# Corrected yeast chromosomes (components reference original contigs)\n")
        f.write("\n".join(agp_lines) + "\n")

    if args.contigs:
        out_fa = os.path.join(args.outdir, "fixed_chromosomes.fa")
        write_fasta(out_fa, final_records)
        sys.stderr.write(f"Wrote {out_fa}\n")
    else:
        sys.stderr.write("No --contigs given: FASTA skipped (AGP + report only)\n")
    sys.stderr.write(f"Wrote {out_agp}\nWrote {out_report}\n")


if __name__ == "__main__":
    main()
