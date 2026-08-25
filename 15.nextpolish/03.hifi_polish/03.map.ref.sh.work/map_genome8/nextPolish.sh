#!/bin/bash
set -xveo pipefail
hostname
cd ${REPO_ROOT}/15.nextpolish/03.hifi_polish/03.map.ref.sh.work/map_genome8
(  ${DATA_ROOT}/Download/NextPolish/bin/minimap2 --split-prefix tmp -a -x map-pb -t 6 ${REPO_ROOT}/15.nextpolish/03.hifi_polish/input.genome.fasta ${REPO_ROOT}/15.nextpolish/input.hifipart.007.fasta.gz|${DATA_ROOT}/Download/NextPolish/bin/samtools view --threads 5 -F 0x4 -b - |${DATA_ROOT}/Download/NextPolish/bin/samtools sort - -m 2g --threads 5 -o hifi.part007.sort.bam )
touch ${REPO_ROOT}/15.nextpolish/03.hifi_polish/03.map.ref.sh.work/map_genome8/nextPolish.sh.done

