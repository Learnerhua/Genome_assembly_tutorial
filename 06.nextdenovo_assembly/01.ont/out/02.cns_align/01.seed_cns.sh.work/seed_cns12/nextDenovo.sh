#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/01.seed_cns.sh.work/seed_cns12
(  ${CONDA_PREFIX}/bin/python ${DATA_ROOT}/Download/NextDenovo/lib/nextcorrect.py -f ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align//01.seed_cns.input.idxs -i ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/04.sort_align.sh.work/sort_align12/input.seed.012.sorted.ovl -p 15 -max_lq_length 10000 -r ont -min_len_seed 5000 -o cns.fasta; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/01.seed_cns.sh.work/seed_cns12/nextDenovo.sh.done

