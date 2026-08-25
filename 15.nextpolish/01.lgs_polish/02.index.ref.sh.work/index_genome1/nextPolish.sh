#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/01.lgs_polish/02.index.ref.sh.work/index_genome1
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools faidx ${REPO_ROOT}/15.nextpolish/01.lgs_polish/input.genome.fasta )
touch ${REPO_ROOT}/15.nextpolish/01.lgs_polish/02.index.ref.sh.work/index_genome1/nextPolish.sh.done

