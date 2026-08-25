#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/04.score_chain/05.polish.ref.sh.work/polish_genome7
(  ${CONDA_PREFIX}/bin/python ${DATA_ROOT}/Download/NextPolish/lib/nextpolish1.py -p 6 -g ${REPO_ROOT}/15.nextpolish/04.score_chain/input.genome.fasta -b ${REPO_ROOT}/15.nextpolish/04.score_chain/input.genome.fasta.blc -i 6 -t 1 -s ${REPO_ROOT}/15.nextpolish/04.score_chain/sgs.sort.bam -l ${REPO_ROOT}/15.nextpolish/04.score_chain/lgs.sort.bam -o genome.nextpolish.part006.fasta )
touch ${REPO_ROOT}/15.nextpolish/04.score_chain/05.polish.ref.sh.work/polish_genome7/nextPolish.sh.done

