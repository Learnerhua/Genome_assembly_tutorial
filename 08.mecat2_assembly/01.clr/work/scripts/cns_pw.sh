#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2map -kmer_size 13 -task pm -outfmt seqidx -num_threads 48 -db_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_pm_dir -keep_db -min_query_size 2000 -out ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_pm.seqidx ${REPO_ROOT}/rawData/PRJEB7245/pacbio_clr_merged.fastq.gz ${REPO_ROOT}/rawData/PRJEB7245/pacbio_clr_merged.fastq.gz
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/cns_pw.sh.done
