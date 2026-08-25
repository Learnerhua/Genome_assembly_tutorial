${DATA_ROOT}/Download/NextPolish/bin/samtools merge -f -b ${REPO_ROOT}/15.nextpolish/05.kmer_count/sgs.sort.bam.list --threads 3 -|${DATA_ROOT}/Download/NextPolish/bin/samtools markdup --threads 3 -r -s - ${REPO_ROOT}/15.nextpolish/05.kmer_count/sgs.sort.bam
${DATA_ROOT}/Download/NextPolish/bin/samtools index -@ 6 ${REPO_ROOT}/15.nextpolish/05.kmer_count/sgs.sort.bam

