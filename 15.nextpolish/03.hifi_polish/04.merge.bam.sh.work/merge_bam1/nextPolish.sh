#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/03.hifi_polish/04.merge.bam.sh.work/merge_bam1
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools merge -f -b ${REPO_ROOT}/15.nextpolish/03.hifi_polish/hifi.sort.bam.list --threads 3 ${REPO_ROOT}/15.nextpolish/03.hifi_polish/hifi.sort.bam )
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools index -@ 6 ${REPO_ROOT}/15.nextpolish/03.hifi_polish/hifi.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/03.hifi_polish/04.merge.bam.sh.work/merge_bam1/nextPolish.sh.done

