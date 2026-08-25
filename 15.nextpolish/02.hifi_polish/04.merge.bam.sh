${DATA_ROOT}/Download/NextPolish/bin/samtools merge -f -b ${REPO_ROOT}/15.nextpolish/02.hifi_polish/hifi.sort.bam.list --threads 3 ${REPO_ROOT}/15.nextpolish/02.hifi_polish/hifi.sort.bam
${DATA_ROOT}/Download/NextPolish/bin/samtools index -@ 6 ${REPO_ROOT}/15.nextpolish/02.hifi_polish/hifi.sort.bam

