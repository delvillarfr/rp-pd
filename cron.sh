#!/usr/bin/env bash

WORKINGDIR='/Users/iorch/mxabierto/rp-pd'
CURRENT_DATA=${WORKINGDIR}'/current'
TEMPORARY=${WORKINGDIR}'/tmp'
DOWNLOADED=${WORKINGDIR}'/datasets'
RDATA=${WORKINGDIR}'/data'
RSCRIPTS='/Users/iorch/mxabierto/rp-pd'

if [ -f ${CURRENT_DATA}/contacts.csv ]; then
c_date=`head -2 ${CURRENT_DATA}/contacts.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_CONTACTS=`head -2 ${CURRENT_DATA}/contacts.csv | awk -F, -v mon="$c_date" '{print $mon}' | tail -n 1`
echo ${AFTER_CONTACTS}
fi
if [ -f ${CURRENT_DATA}/messages.csv ]; then
m_date=`head -2 ${CURRENT_DATA}/messages.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_MESSAGES=`head -2 ${CURRENT_DATA}/messages.csv | awk -F, -v mon="$m_date" '{print $mon}' | tail -n 1`
echo ${AFTER_MESSAGES}
fi
if [ -f ${CURRENT_DATA}/flows.csv ]; then
f_date=`head -2 ${CURRENT_DATA}/flows.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_FLOWS=`head -2 ${CURRENT_DATA}/flows.csv | awk -F, -v mon="$f_date" '{print $mon}' | tail -n 1`
echo ${AFTER_FLOWS}
fi
if [ -f ${CURRENT_DATA}/runs.csv ]; then
r_date=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_RUNS=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, -v mon="$r_date" '{print $mon}'|tail -n 1`
echo ${AFTER_RUNS}
fi


python ./run.py c=${AFTER_CONTACTS} m=${AFTER_MESSAGES} f=${AFTER_FLOWS} r=${AFTER_RUNS}
echo 'query finished'

if [ ! -f ${CURRENT_DATA}/contacts.csv ]; then
cp ${DOWNLOADED}/contacts.csv ${CURRENT_DATA}/contacts.csv
else
LINES_CONTACTS=$(( `wc -l < ${CURRENT_DATA}/contacts.csv`-1 ))
cp ${DOWNLOADED}/contacts.csv ${TEMPORARY}/contacts.csv
cat ${CURRENT_DATA}/contacts.csv | tail -n ${LINES_CONTACTS} >> ${TEMPORARY}/contacts.csv
head -1 ${TEMPORARY}/contacts.csv > ${CURRENT_DATA}/contacts.csv
tail -n+2 ${TEMPORARY}/contacts.csv | sort -t, -k${c_date} -ur >> ${CURRENT_DATA}/contacts.csv
fi
echo 'contacs done'

if [ ! -f ${CURRENT_DATA}/messages.csv ]; then
cp ${DOWNLOADED}/messages.csv ${CURRENT_DATA}/messages.csv
else
LINES_MESSAGES=$(( `wc -l < ${CURRENT_DATA}/messages.csv`-1 ))
cp ${DOWNLOADED}/messages.csv ${TEMPORARY}/messages.csv
cat ${CURRENT_DATA}/messages.csv | tail -n ${LINES_MESSAGES} >> ${TEMPORARY}/messages.csv
head -1 ${TEMPORARY}/messages.csv > ${CURRENT_DATA}/messages.csv
tail -n+2 ${TEMPORARY}/messages.csv | sort -t, -k${m_date} -ur  >> ${CURRENT_DATA}/messages.csv
fi
echo 'messages done'

if [ ! -f ${CURRENT_DATA}/flows.csv ]; then
cp ${DOWNLOADED}/flows.csv ${CURRENT_DATA}/flows.csv
else
LINES_FLOWS=$(( `wc -l < ${CURRENT_DATA}/flows.csv`-1 ))
cp ${DOWNLOADED}/flows.csv ${TEMPORARY}/flows.csv
cat ${CURRENT_DATA}/flows.csv | tail -n ${LINES_FLOWS} >> ${TEMPORARY}/flows.csv
head -1 ${TEMPORARY}/flows.csv > ${CURRENT_DATA}/flows.csv
tail -n+2 ${TEMPORARY}/flows.csv | sort -t, -k${f_date} -ur >> ${CURRENT_DATA}/flows.csv
fi
echo 'flows done'

if [ ! -f ${CURRENT_DATA}/runs.csv ]; then
cp ${DOWNLOADED}/runs.csv ${CURRENT_DATA}/runs.csv
else
LINES_RUNS=$(( `wc -l < ${CURRENT_DATA}/runs.csv`-1 ))
cp ${DOWNLOADED}/runs.csv ${TEMPORARY}/runs.csv
cat ${CURRENT_DATA}/runs.csv | tail -n ${LINES_FLOWS} >> ${TEMPORARY}/runs.csv
head -1 ${TEMPORARY}/runs.csv > ${CURRENT_DATA}/runs.csv
tail -n+2 ${TEMPORARY}/runs.csv | sort -t, -k${r_date}  -ur >> ${CURRENT_DATA}/runs.csv
fi
echo 'runs done'

cp ${CURRENT_DATA}/*.csv ${RDATA}/

cd ${RSCRIPTS}


