${DATA_ROOT}/Download/NextPolish/bin/samtools merge -f -b ${REPO_ROOT}/15.nextpolish/06.score_chain/sgs.sort.bam.list --threads 3 -|${DATA_ROOT}/Download/NextPolish/bin/samtools markdup --threads 3 -r -s - ${REPO_ROOT}/15.nextpolish/06.score_chain/sgs.sort.bam
${DATA_ROOT}/Download/NextPolish/bin/samtools index -@ 6 ${REPO_ROOT}/15.nextpolish/06.score_chain/sgs.sort.bam

