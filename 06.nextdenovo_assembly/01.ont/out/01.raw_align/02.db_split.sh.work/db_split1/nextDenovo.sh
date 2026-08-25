#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/02.db_split.sh.work/db_split1
(  ${DATA_ROOT}/Download/NextDenovo/bin/seq_dump -f 1k -s 10000 -b 544736154 -n 12 -d ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/input.fofn )
touch ${REPO_ROOT}/06.nextdenovo_assembly/01.ont/out/01.raw_align/02.db_split.sh.work/db_split1/nextDenovo.sh.done

