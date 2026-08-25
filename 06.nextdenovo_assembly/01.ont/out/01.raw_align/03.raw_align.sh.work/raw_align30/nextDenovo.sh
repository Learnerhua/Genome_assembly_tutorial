#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align30
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd --step 1 -I 3G --dual=yes -t 4 -x ava-ont ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.003.2bit ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.006.2bit -o input.seed.003.2bit.29.ovl;ln -sf input.seed.003.2bit.29.ovl input.seed.006.2bit.29.ovl; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align30/nextDenovo.sh.done

