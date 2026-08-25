#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/01.db_stat.sh.work/db_stat1
(  ${DATA_ROOT}/Download/NextDenovo/bin/seq_stat -f 1k -g 12.1m -d 45 -o ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/input.reads.stat ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/input.fofn )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/01.db_stat.sh.work/db_stat1/nextDenovo.sh.done

