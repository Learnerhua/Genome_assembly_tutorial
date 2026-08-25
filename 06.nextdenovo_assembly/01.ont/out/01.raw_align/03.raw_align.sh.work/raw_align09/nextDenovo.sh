#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align09
(  ${DATA_ROOT}/Download/NextDenovo/bin/minimap2-nd --step 1 -I 3G --dual=yes -t 4 -x ava-ont ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.001.2bit ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.seed.008.2bit -o input.seed.001.2bit.8.ovl;ln -sf input.seed.001.2bit.8.ovl input.seed.008.2bit.8.ovl; )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/03.raw_align.sh.work/raw_align09/nextDenovo.sh.done

