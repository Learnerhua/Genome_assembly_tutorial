# Yeast Genome Assembly, Evaluation & Annotation Tutorial

> 📖 **中文版说明**：本教程有中文版 README（[README.CN.md](README.CN.md)），如需要中文阅读可参考。

## A Complete Pipeline from K-mer Analysis to Annotated Chromosome-Level Genome

A comprehensive tutorial for *Saccharomyces cerevisiae* S288C genome assembly, covering the full workflow from K-mer analysis to annotated chromosome-level genome. All scripts and results are reproducible on Linux/macOS.

---

## 📖 Overview

This tutorial uses budding yeast (S288C) as a model organism to demonstrate the **complete genome assembly workflow** in practice:

- **13 assembler comparison** (Illumina, CLR, HiFi, ONT)
- **Assembly quality evaluation** (QUAST + BUSCO + dotPlotly)
- **Polishing** (NextPolish)
- **Hi-C scaffolding** (YaHS)
- **Reference-guided reordering** (16 chromosomes + mtDNA)
- **Reference-transfer annotation** (Liftoff + mitochondrial annotation)

**Target audience**:

- Bioinformatics beginners learning genome assembly
- Bioinformaticians (as a template / reference implementation)
- Researchers working with yeast or closely related species

---

## 🎯 Tutorial Highlights

1. **13 assemblers in practice** — full coverage of Illumina, CLR, HiFi, ONT data types
2. **3-tool evaluation system** — QUAST (continuity/accuracy) + BUSCO (completeness) + dotPlotly (synteny)
3. **Hi-C scaffolding + reference-guided reordering** — complete demonstration of chromosome-level construction
4. **Annotation closed loop** — Liftoff nuclear annotation + mitochondrial annotation (with codon table caveat)
5. **Real-data driven** — every step has actual run results, not empty promises

---

## 📂 Project Structure

```
git_repo/
├── 01.kmer_analysis/             # K-mer analysis (genome size estimation)
├── 02.soapdenovo2_assembly/      # SOAPdenovo2 (short-read assembly)
├── 03.spades_assembly/           # SPAdes (multi-data assembly)
├── 04.canu_assembly/             # Canu + purge_dups (HiFi correction)
├── 05.wtdbg2_assembly/           # wtdbg2 (CLR fast assembly)
├── 06.nextdenovo_assembly/       # ★ nextDenovo ONT (main assembly)
├── 07.flye_assembly/             # Flye (ONT/HiFi)
├── 08.mecat2_assembly/           # MECAT2 (CLR)
├── 09.necat_assembly/            # NECAT (ONT)
├── 10.hifiasm_assembly/          # hifiasm (HiFi)
├── 11.quickmerge_assembly/       # quickmerge (hybrid merging)
├── 12.dotplotly_analysis/        # Synteny visualization (13 assemblies vs reference)
├── 13.quast_analysis/            # QUAST evaluation
├── 14.busco_analysis/            # BUSCO evaluation
├── 15.nextpolish/                # ★ NextPolish polishing
├── 16.hic_scaffolding/           # ★ Hi-C scaffolding (YaHS)
├── 17.ref_chromosomes/           # ★ Reference-guided reordering (16 chromosomes + mtDNA)
├── 18.annotation/                # ★ Annotation (nuclear + mitochondrial)
│   └── final_assembly/           # ★ Final deliverables
├── rawData/                      # Raw sequencing data (reference + WGS/PacBio/ONT/HiC)
└── Genome_assembly_tutorial.pdf  # Complete tutorial PDF (58 MB)
```

**Sections marked with ★ are the recommended core pipeline**:
nextDenovo ONT → NextPolish → Hi-C → reference-guided reordering → annotation

## 🖼 Final Deliverable: Reference-guided Chromosomes

![](17.ref_chromosomes/dotplotly_result/ref_scaffold.png)

*16 nuclear chromosomes + 1 mitochondrial chromosome (each contig maps to a single reference region, no cross-chromosome rearrangement)*

---

## 🚀 Quick Start

### System Requirements

- **OS**: Linux (Ubuntu 20.04+ recommended) or macOS
- **Conda**: miniforge3 / miniconda / anaconda
- **Disk**: ~150 GB raw data (tutorial outputs already slimmed)
- **RAM**: ≥64 GB recommended (≤32 GB works for small genomes)

### Required conda environments

| Environment | Purpose | Key tools |
| --- | --- | --- |
| `genome_assembly` | Main pipeline | minimap2, samtools, liftoff, yahs, bwa, quast, bandage |
| `busco` | BUSCO evaluation | busco, hmmsearch, prodigal |
| `RNA-seq` | Annotation helper | gffread |
| `old_base` | General utilities | aria2c, Rscript, juicer_tools |

### Key Environment Variables

All script paths use **portable environment variables** — no hardcoded paths:

```bash
REPO_ROOT=${REPO_ROOT:-$(pwd)}        # Tutorial project root
CONDA_PREFIX=${CONDA_PREFIX:-}        # genome_assembly env
BUSCO_BIN=${BUSCO_BIN:-}              # busco env bin
BUSCO_ENV=${BUSCO_ENV:-}              # busco env root
RNA_SEQ_BIN=${RNA_SEQ_BIN:-}          # RNA-seq env bin
RNA_SEQ_ENV=${RNA_SEQ_ENV:-}          # RNA-seq env root
DATA_ROOT=${DATA_ROOT:-}              # Data root (Download tools etc.)
MINIFORGE3=${MINIFORGE3:-}            # miniforge install root
HOME=${HOME}                          # User home
```

In practice, **activate the relevant conda environment** or **explicitly export these variables** before running scripts.

---

## 📚 Tutorial Chapters

| Chapter | Title | Chapter | Title |
| --- | --- | --- | --- |
| 1 | Genome Survey | 5 | Assembly Quality Evaluation |
| 2 | K-mer Analysis | 6 | Analysis Examples (13 assemblies) |
| 3 | Data Types Overview | 7 | Genome Annotation |
| 4 | Assembly Algorithms | 8 | Tutorial Summary |

Each chapter maps to one `01-18.*` directory. The tutorial PDF (`Genome_assembly_tutorial.pdf`) contains complete commands, parameter explanations, and pitfalls encountered.

---

## 🎓 Key Deliverables

After completing this tutorial, you'll have:

```
18.annotation/final_assembly/
├── genome.fa          # Complete genome (17 sequences: chrI-XVI + Mito, 12 MB)
├── annotations.gff3   # Complete annotation (6,610 genes: 6,582 nuclear + 28 mitochondrial)
└── proteins.fa        # Protein sequences (6,577 proteins, mitochondrial with codon table 3)
```

**Quality metrics** (this tutorial, real results):

| Metric | Value | Evaluator |
| --- | --- | --- |
| Genome size | 12.04 Mb (nuclear 12.04 + mt 0.1) | QUAST |
| N50 | 928 Kb | QUAST |
| Misassemblies | 26 | QUAST |
| BUSCO C:99.9% / M:1 | Complete | BUSCO |
| Gene count | 6,610 (matches official S288C R64) | Liftoff |

---

## ⚠️ Important Notes

1. **Path pseudonymization**: All paths in scripts have been replaced with environment variables (`${REPO_ROOT}`, `${CONDA_PREFIX}`, etc.). Adjust them according to your actual environment before first use.
2. **Data download**: The `rawData/` directory contains only **sample data**. Complete datasets need to be downloaded from original databases (ENA/SRA).
3. **Large file slimming**: Intermediate products in this tutorial have been `touch`ed to 0 bytes; only key deliverables and visualizations are preserved.
4. **Intermediate products can be deleted**: `logs/`, `01.work/`, `*.bam`, `*.mmi` etc. can be cleaned up.

---

## 📦 Data Sources

| Data | Source | Usage |
| --- | --- | --- |
| Reference genome | Ensembl R64-1-1 | Alignment reference, annotation transfer |
| PacBio HiFi | SRR13577847 | HiFi assembly (hifiasm/Canu) |
| PacBio CLR | PRJEB7245 (ERR1655118-125) | CLR assembly (MECAT2/wtdbg2) |
| ONT | PRJEB19900 | ONT assembly (nextDenovo/Flye/NECAT) |
| Illumina WGS | ERR1938683 | SPAdes short-read assembly |
| Hi-C | SRR28065402 | Hi-C scaffolding (YaHS) |
| Gene annotation GFF3 | Ensembl R64-1-1.63 | Liftoff reference |

See Section 6.2 of the tutorial PDF for detailed download links.

---

## 🔧 Tool Versions

Tool versions used in this tutorial (other versions may also work):

| Tool | Version | conda env |
| --- | --- | --- |
| BUSCO | 6.1.0 | busco |
| Liftoff | 1.1.3 | genome_assembly |
| NextPolish | 1.4.1 | - |
| minimap2 | 2.31 | genome_assembly |
| samtools | 1.19 | genome_assembly |
| bwa | 0.7.17 | - |
| yahs | 1.2.2 | - |
| quast | 5.2.0 | genome_assembly |
| R | 4.5.1 | old_base |
| gffread | 0.12.7 | RNA-seq |

---

## 📜 License

This tutorial is for educational and research purposes only. When citing the tools used here, please refer to their original papers.

## 🙏 Acknowledgments

Thanks to all upstream tool developers: minimap2, samtools, bwa, yahs, busco, quast, liftoff, nextDenovo, nextPolish, spades, canu, flye, mecat2, necat, hifiasm, quickmerge, wtdbg2, soapdenovo2, juicer_tools, and many others.