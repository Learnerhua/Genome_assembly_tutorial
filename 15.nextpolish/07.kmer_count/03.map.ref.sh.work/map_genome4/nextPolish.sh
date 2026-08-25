#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/07.kmer_count/03.map.ref.sh.work/map_genome4
(  ${DATA_ROOT}/Download/NextPolish/bin/bwa mem -p -t 6 ${REPO_ROOT}/15.nextpolish/07.kmer_count/input.genome.fasta.sgs ${REPO_ROOT}/15.nextpolish/input.sgspart.003.fastq.gz|${DATA_ROOT}/Download/NextPolish/bin/samtools view --threads 5 -F 0x4 -b - |${DATA_ROOT}/Download/NextPolish/bin/samtools fixmate -m --threads 5 - - |${DATA_ROOT}/Download/NextPolish/bin/samtools sort - -m 2g --threads 5 -o sgs.part003.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/07.kmer_count/03.map.ref.sh.work/map_genome4/nextPolish.sh.done

