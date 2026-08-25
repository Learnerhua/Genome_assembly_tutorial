#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align83
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd --step 1 -I 3G -t 4 -x ava-ont ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.010.2bit ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.010.2bit -o input.seed.010.2bit.82.ovl; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align83/nextDenovo.sh.done

