#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/02.ctg_align.sh.work/ctg_align13
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd --step 3 -x map-ont -a -t 15 --minlen 8999 ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1/nd.asm.p.fasta ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.part.001.2bit|${DATA_ROOT}/Download/NextDenovo/bin/bam_sort -i -@ 15 -o input.part.001.2bit.sort.bam )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/02.ctg_align.sh.work/ctg_align13/nextDenovo.sh.done

