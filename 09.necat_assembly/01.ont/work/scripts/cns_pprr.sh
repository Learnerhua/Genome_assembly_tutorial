#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/fsa_rd_tools longest --ifname ont_read_list.txt --ofname ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/raw_reads/filtered_raw_reads.fasta --min_length 2000 --base_size 486289840 --discard_illegal_read
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz -f -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/raw_reads/filtered_raw_reads.fasta
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/raw_reads/filtered_raw_reads.fasta.gz > ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/raw_reads/raw_read_list.txt
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/cns_pprr.sh.done
