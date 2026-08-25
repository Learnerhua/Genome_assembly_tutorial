#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1
(  ${DATA_ROOT}/Download/NextDenovo/bin/nextgraph -a 1 -f ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.input.seqs ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.input.ovls -o nd.asm.p.fasta; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/03.ctg_graph/01.ctg_graph.sh.work/ctg_graph1/nextDenovo.sh.done

