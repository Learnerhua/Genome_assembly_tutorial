${DATA_ROOT}/Download/NextPolish/bin/seq_split -d ${REPO_ROOT}/15.nextpolish -m 151464937.5 -n 8  -t 6 -i 1 -s 1211719500 -p input.sgspart ${REPO_ROOT}/15.nextpolish/sgs.fofn 
${DATA_ROOT}/Download/NextPolish/bin/seq_split -d ${REPO_ROOT}/15.nextpolish -m 151464937.5 -n 8 -i 0 -t 6 -f 1k -l 0 -s 1211719500 -p input.lgspart ${REPO_ROOT}/15.nextpolish/ont.fofn 
${DATA_ROOT}/Download/NextPolish/bin/seq_split -d ${REPO_ROOT}/15.nextpolish -m 151464937.5 -n 8 -i 0 -t 6 -f 1k -l 0 -s 1211719500 -p input.hifipart ${REPO_ROOT}/15.nextpolish/hifi.fofn 
${DATA_ROOT}/Download/NextPolish/bin/samtools faidx ${REPO_ROOT}/15.nextpolish/00.lgs_polish/input.genome.fasta

