#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split4
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools faidx ${REPO_ROOT}/15.nextpolish/00.lgs_polish/input.genome.fasta )
touch ${REPO_ROOT}/15.nextpolish/00.lgs_polish/01.db_split.sh.work/db_split4/nextPolish.sh.done

