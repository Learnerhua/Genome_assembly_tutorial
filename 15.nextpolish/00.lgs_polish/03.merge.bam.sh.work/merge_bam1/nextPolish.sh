#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/00.lgs_polish/03.merge.bam.sh.work/merge_bam1
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools merge -f -b ${REPO_ROOT}/15.nextpolish/00.lgs_polish/lgs.sort.bam.list --threads 3 ${REPO_ROOT}/15.nextpolish/00.lgs_polish/lgs.sort.bam )
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools index -@ 6 ${REPO_ROOT}/15.nextpolish/00.lgs_polish/lgs.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/00.lgs_polish/03.merge.bam.sh.work/merge_bam1/nextPolish.sh.done

