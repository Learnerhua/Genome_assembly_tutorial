#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/01.lgs_polish/05.polish.ref.sh.work/polish_genome6
(  ${CONDA_PREFIX}/bin/python ${DATA_ROOT}/Download/NextPolish/lib/nextpolish2.py -sp -p 6 -g ${REPO_ROOT}/15.nextpolish/01.lgs_polish/input.genome.fasta -b ${REPO_ROOT}/15.nextpolish/01.lgs_polish/input.genome.fasta.blc -i 5 -l ${REPO_ROOT}/15.nextpolish/01.lgs_polish/lgs.sort.bam.list -r ont -o genome.nextpolish.part005.fasta )
touch ${REPO_ROOT}/15.nextpolish/01.lgs_polish/05.polish.ref.sh.work/polish_genome6/nextPolish.sh.done

