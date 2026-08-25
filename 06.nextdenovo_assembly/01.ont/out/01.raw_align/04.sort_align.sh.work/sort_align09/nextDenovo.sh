#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/04.sort_align.sh.work/sort_align09
(  ${DATA_ROOT}/Download/NextDenovo/bin/ovl_sort -m 20g -t 15 -k 40 -i ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/.input.seed.009.idx -o input.seed.009.sorted.ovl input.fofn; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/04.sort_align.sh.work/sort_align09/nextDenovo.sh.done

