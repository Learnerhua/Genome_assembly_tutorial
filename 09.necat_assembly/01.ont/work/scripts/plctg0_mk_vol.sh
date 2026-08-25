#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  echo  "${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contigs.fasta" > "${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contig_list.txt" && ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2mkdb ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/pac_contigs ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contig_list.txt
  temp_result=(${PIPESTATUS[*]})
  for i in ${temp_result[*]} 
  do
    if [ $retVal -eq 0 ]; then
      retVal=$i
    else
      break
    fi
  done
fi
if [ $retVal -eq 0 ]; then
  echo  "${REPO_ROOT}/09.necat_assembly/01.ont/work/trimReads.fasta.gz" > "${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/read_list.txt" && ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2mkdb ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/pac_reads ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/read_list.txt
  temp_result=(${PIPESTATUS[*]})
  for i in ${temp_result[*]} 
  do
    if [ $retVal -eq 0 ]; then
      retVal=$i
    else
      break
    fi
  done
fi

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/plctg0_mk_vol.sh.done
