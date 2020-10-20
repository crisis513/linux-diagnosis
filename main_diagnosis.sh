#!/bin/bash
#
# CentOS Diagnosis Tool, Version 0.1
# +-----------------------------------------------------------+
# |  Maintainer  | Son Han Gi     | crisis51526@gmail.com     |
# +-----------------------------------------------------------+
#

if [ "$EUID" -ne 0 ]; then
        echo "root 권한으로 스크립트를 실행하여 주십시오."
        exit
fi

DEBUG_LOG="log/diagnosis_script.debug" 
exec 2>>$DEBUG_LOG
set -o xtrace

lib/diagnosis_1
lib/diagnosis_2

for host in $@; do
	echo "[$host] 호스트의 진단을 시작합니다."
	echo
	scp -r ../linux_diagnosis $host:/tmp
	ssh -T -oStrictHostKeyChecking=no $host << ENDSSH
cd /tmp/linux_diagnosis
lib/diagnosis_1
lib/diagnosis_2
ENDSSH
done

set +o xtrace
