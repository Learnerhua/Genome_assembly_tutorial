#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split1
(  ${DATA_ROOT}/Download/NextPolish/bin/seq_split -d ${REPO_ROOT}/15.nextpolish -m 151464937.5 -n 8 -t 6 -i 1 -s 1211719500 -p input.sgspart ${REPO_ROOT}/15.nextpolish/sgs.fofn )
touch ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split1/nextPolish.sh.done

