#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/04.sort_align.sh.work/sort_align06
(  ${DATA_ROOT}/Download/NextDenovo/bin/ovl_sort -m 20g -t 15 -k 40 -i ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/.input.seed.006.idx -o input.seed.006.sorted.ovl input.fofn; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/04.sort_align.sh.work/sort_align06/nextDenovo.sh.done

