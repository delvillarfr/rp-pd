#!/usr/bin/env bash

WORKINGDIR='/Users/iorch/mxabierto/rp-pd'
CURRENT_DATA=${WORKINGDIR}'/current'
TEMPORARY=${WORKINGDIR}'/tmp'
DOWNLOADED=${WORKINGDIR}'/datasets'
RDATA=${WORKINGDIR}'/data'


c_date=`head -2 ${CURRENT_DATA}/contacts.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"2016"){print i} } }'|tail -1`
AFTER_CONTACTS=`head -2 ${CURRENT_DATA}/contacts.csv | awk -F, -v mon="$c_date" '{print $mon}' | tail -n 1`
m_date=`head -2 ${CURRENT_DATA}/messages.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"2016"){print i} } }'|tail -1`
AFTER_MESSAGES=`head -2 ${CURRENT_DATA}/messages.csv | awk -F, -v mon="$m_date" '{print $mon}' | tail -n 1`
f_date=`head -2 ${CURRENT_DATA}/flows.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"2016"){print i} } }'|tail -1`
AFTER_FLOWS=`head -2 ${CURRENT_DATA}/flows.csv | awk -F, -v mon="$f_date" '{print $mon}' | tail -n 1`
r_date=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"2016"){print i} } }'|tail -1`
AFTER_RUNS=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, -v mon="$r_date" '{print $mon}'|tail -n 1`

echo ${AFTER_CONTACTS}
echo ${AFTER_MESSAGES}
echo ${AFTER_FLOWS}
echo ${AFTER_RUNS}

python ./run.py c=${AFTER_CONTACTS} m=${AFTER_MESSAGES} f=${AFTER_FLOWS} r=${AFTER_RUNS}
echo 'query finished'

LINES_CONTACTS=$(( `wc -l < ${CURRENT_DATA}/contacts.csv`-1 ))
cp ${DOWNLOADED}/contacts.csv ${TEMPORARY}/contacts.csv
cat ${CURRENT_DATA}/contacts.csv | tail -n ${LINES_CONTACTS} >> ${TEMPORARY}/contacts.csv
head -1 ${TEMPORARY}/contacts.csv > ${CURRENT_DATA}/contacts.csv
tail -n+2 ${TEMPORARY}/contacts.csv | sort -t, -k${c_date} -ru >> ${CURRENT_DATA}/contacts.csv

LINES_MESSAGES=$(( `wc -l < ${CURRENT_DATA}/messages.csv`-1 ))
cp ${DOWNLOADED}/messages.csv ${TEMPORARY}/messages.csv
cat ${CURRENT_DATA}/messages.csv | tail -n ${LINES_MESSAGES} >> ${TEMPORARY}/messages.csv
head -1 ${TEMPORARY}/messages.csv > ${CURRENT_DATA}/messages.csv
tail -n+2 ${TEMPORARY}/messages.csv | sort -t, -k${m_date} -ru  >> ${CURRENT_DATA}/messages.csv

LINES_FLOWS=$(( `wc -l < ${CURRENT_DATA}/flows.csv`-1 ))
cp ${DOWNLOADED}/flows.csv ${TEMPORARY}/flows.csv
cat ${CURRENT_DATA}/flows.csv | tail -n ${LINES_FLOWS} >> ${TEMPORARY}/flows.csv
head -1 ${TEMPORARY}/flows.csv > ${CURRENT_DATA}/flows.csv
tail -n+2 ${TEMPORARY}/flows.csv | sort -t, -k${f_date} -ru >> ${CURRENT_DATA}/flows.csv

LINES_RUNSS=$(( `wc -l < ${CURRENT_DATA}/runs.csv`-1 ))
cp ${DOWNLOADED}/runs.csv ${TEMPORARY}/runs.csv
cat ${CURRENT_DATA}/runs.csv | tail -n ${LINES_FLOWS} >> ${TEMPORARY}/runs.csv
head -1 ${TEMPORARY}/runs.csv > ${CURRENT_DATA}/runs.csv
tail -n+2 ${TEMPORARY}/runs.csv | sort -t, -k${r_date} -ru >> ${CURRENT_DATA}/runs.csv