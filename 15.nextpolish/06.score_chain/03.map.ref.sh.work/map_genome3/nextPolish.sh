#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/06.score_chain/03.map.ref.sh.work/map_genome3
(  ${DATA_ROOT}/Download/NextPolish/bin/bwa mem -p -t 6 ${REPO_ROOT}/15.nextpolish/06.score_chain/input.genome.fasta.sgs ${REPO_ROOT}/15.nextpolish/input.sgspart.002.fastq.gz|${DATA_ROOT}/Download/NextPolish/bin/samtools view --threads 5 -F 0x4 -b - |${DATA_ROOT}/Download/NextPolish/bin/samtools fixmate -m --threads 5 - - |${DATA_ROOT}/Download/NextPolish/bin/samtools sort - -m 2g --threads 5 -o sgs.part002.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/06.score_chain/03.map.ref.sh.work/map_genome3/nextPolish.sh.done

