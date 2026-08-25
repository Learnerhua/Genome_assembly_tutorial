#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/00.lgs_polish/02.map.ref.sh.work/map_genome6
(  ${DATA_ROOT}/Download/NextPolish/bin/minimap2 --split-prefix tmp -a -x map-ont -t 6 ${REPO_ROOT}/15.nextpolish/00.lgs_polish/input.genome.fasta ${REPO_ROOT}/15.nextpolish/input.lgspart.005.fasta.gz|${DATA_ROOT}/Download/NextPolish/bin/samtools view --threads 5 -F 0x4 -b - |${DATA_ROOT}/Download/NextPolish/bin/samtools sort - -m 2g --threads 5 -o lgs.part005.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/00.lgs_polish/02.map.ref.sh.work/map_genome6/nextPolish.sh.done

