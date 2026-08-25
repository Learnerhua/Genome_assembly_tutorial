#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/03.ctg_cns.sh.work/ctg_cns03
(  ${CONDA_PREFIX}/bin/python ${DATA_ROOT}/Download/NextDenovo/lib/ctg_cns.py -p 15 -g ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1/nd.asm.p.fasta -b ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1/nd.asm.p.fasta.blc -i 2 -r ont -l ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/03.ctg_cns.input.bams -o nd.asm.f.part002.fasta )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/03.ctg_cns.sh.work/ctg_cns03/nextDenovo.sh.done

