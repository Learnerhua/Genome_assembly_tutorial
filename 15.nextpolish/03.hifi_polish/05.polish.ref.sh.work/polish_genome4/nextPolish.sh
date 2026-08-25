#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/03.hifi_polish/05.polish.ref.sh.work/polish_genome4
(  ${CONDA_PREFIX}/bin/python ${DATA_ROOT}/Download/NextPolish/lib/nextpolish2.py -sp -p 6 -g ${REPO_ROOT}/15.nextpolish/03.hifi_polish/input.genome.fasta -b ${REPO_ROOT}/15.nextpolish/03.hifi_polish/input.genome.fasta.blc -i 3 -l ${REPO_ROOT}/15.nextpolish/03.hifi_polish/hifi.sort.bam.list -r hifi -o genome.nextpolish.part003.fasta )
touch ${REPO_ROOT}/15.nextpolish/03.hifi_polish/05.polish.ref.sh.work/polish_genome4/nextPolish.sh.done

