#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/06.score_chain/02.index.ref.sh.work/index_genome2
(  ${DATA_ROOT}/Download/NextPolish/bin/samtools faidx ${REPO_ROOT}/15.nextpolish/06.score_chain/input.genome.fasta )
touch ${REPO_ROOT}/15.nextpolish/06.score_chain/02.index.ref.sh.work/index_genome2/nextPolish.sh.done

