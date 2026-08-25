#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split3
(  ${DATA_ROOT}/Download/NextPolish/bin/seq_split -d ${REPO_ROOT}/15.nextpolish -m 151464937.5 -n 8 -i 0 -t 6 -f 1k -l 0 -s 1211719500 -p input.hifipart ${REPO_ROOT}/15.nextpolish/hifi.fofn )
touch ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split3/nextPolish.sh.done

