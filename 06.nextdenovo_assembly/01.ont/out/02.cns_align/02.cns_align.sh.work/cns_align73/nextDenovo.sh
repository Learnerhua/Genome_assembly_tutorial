#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/02.cns_align.sh.work/cns_align73
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd -I 6G --step 2 -t 4 -x ava-ont -k 17 -w 17 --minlen 1000 --maxhan1 5000 ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/01.seed_cns.sh.work/seed_cns10/cns.fasta ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/01.seed_cns.sh.work/seed_cns10/cns.fasta -o cns.filt.dovt.ovl; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/02.cns_align/02.cns_align.sh.work/cns_align73/nextDenovo.sh.done

