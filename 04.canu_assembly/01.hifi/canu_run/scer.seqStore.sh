#!/bin/sh


#  Paths to things we run.

bin="${DATA_ROOT}/Download/canu-2.3/bin"

pn=/usr/bin/perl
pe=`command -v $pn`
pv=`command    $pn --version | grep version`

jn=java
je=`command -v $jn`
jv=`command    $jn -showversion 2>&1 | head -n 1`

cn=${DATA_ROOT}/Download/canu-2.3/bin/canu
ce=`command -v $cn`
cv=`command    $cn -version`

#  Report paths.

echo ""
echo "Found perl (from '$pn'):"
echo "  $pe"
echo "  $pv"
echo ""
echo "Found java (from '$jn'):"
echo "  $je"
echo "  $jv"
echo ""
echo "Found canu (from '$cn'):"
echo "  $ce"
echo "  $cv"
echo ""

#  Environment for any object storage.

export CANU_OBJECT_STORE_CLIENT=
export CANU_OBJECT_STORE_CLIENT_UA=
export CANU_OBJECT_STORE_CLIENT_DA=
export CANU_OBJECT_STORE_NAMESPACE=
export CANU_OBJECT_STORE_PROJECT=




${DATA_ROOT}/Download/canu-2.3/bin/sqStoreCreate \
  -o ./scer.seqStore.BUILDING \
  -minlength 1000 \
  -genomesize 12000000 \
  -coverage   50 \
  -bias       0 \
  -homopolycompress \
  -raw -trimmed -pacbio-hifi SRR13577847_subreads ${REPO_ROOT}/rawData/SRR13577847_subreads.fastq.gz \
&& \
mv ./scer.seqStore.BUILDING ./scer.seqStore \
&& \
exit 0

exit 1
