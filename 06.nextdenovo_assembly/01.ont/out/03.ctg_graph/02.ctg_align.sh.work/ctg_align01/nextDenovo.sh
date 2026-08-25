#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/02.ctg_align.sh.work/ctg_align01
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd --step 3 -x map-ont -a -t 15 ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1/nd.asm.p.fasta ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.001.2bit|${DATA_ROOT}/Download/NextDenovo/bin/bam_sort -i -@ 15 -o input.seed.001.2bit.sort.bam )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/02.ctg_align.sh.work/ctg_align01/nextDenovo.sh.done

