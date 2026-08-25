#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/07.kmer_count/02.index.ref.sh.work/index_genome1
(  ${DATA_ROOT}/Download/NextPolish/bin/bwa index -p ${REPO_ROOT}/15.nextpolish/07.kmer_count/input.genome.fasta.sgs ${REPO_ROOT}/15.nextpolish/07.kmer_count/input.genome.fasta )
touch ${REPO_ROOT}/15.nextpolish/07.kmer_count/02.index.ref.sh.work/index_genome1/nextPolish.sh.done

