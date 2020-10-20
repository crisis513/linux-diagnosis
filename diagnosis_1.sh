#!/bin/bash
#
# CentOS Diagnosis Tool, Version 0.1
# +-----------------------------------------------------------+
# |  Maintainer  | Son Han Gi     | crisis51526@gmail.com     |
# +-----------------------------------------------------------+
#

# import lib.sh
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/function"

DEBUG_LOG="../log/diagnosis_script.debug" 
exec 2>>$DEBUG_LOG
set -o xtrace

echo
echo "+-------------------------------------------------------------------+"
echo "| 계정관리에 대한 Linux 서버 취약점 분석을 시작합니다.              |"
echo "+-------------------------------------------------------------------+"
echo

## 1.1 root 계정 원격 접속 제한(U-01)

VUL_ITEM="U-01"
start_diagnosis "$VUL_ITEM"

grep ^pts /etc/securetty > /dev/null 2>&1

if [ $? -eq 0 ]; then
	print_weak "root 직접 접속이 허용되었거나, 원격서비스를 사용 중 입니다." "$VUL_ITEM"
	print_info " => vi /etc/securetty 파일에서 pts 주석처리." "$VUL_ITEM"
else
	print_good "원격 서비스를 사용하지 않고 있거나, 접속이 차단 되어 있습니다." "$VUL_ITEM"
fi

cat /etc/pam.d/login | grep "^auth required /lib/security/pam_securetty.so" > /dev/null 2>&1

if [ $? -eq 0 ]; then
	print_good "pam_securetty.so 파일을 통해 사용자 인증에 대한 보안이 적용되어 있습니다." "$VUL_ITEM"
else
	print_weak "pam_securetty.so 파일을 통한 사용자 인증에 대한 보안이 적용되어 있지 않습니다." "$VUL_ITEM"
        print_info "=> vi /etc/pam.d/login 파일에서 해당 내용을 추가하거나 주석을 해제하십시오. \nauth required /lib/security/pam_securetty.so" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 1.2 패스워드 복잡성 설정(U-02)

VUL_ITEM="U-02"
start_diagnosis "$VUL_ITEM"

MAX=`cat /etc/login.defs | grep PASS_MAX_DAYS | awk '{print $2}' | sed '1d'`
MIN=`cat /etc/login.defs | grep PASS_MIN_DAYS | awk '{print $2}' | sed '1d'`
DATE=`cat /etc/login.defs | grep PASS_WARN_AGE | awk '{print $2}' | sed '1d'`
FLAG=Flase

if [ $MAX == 60 ]; then
	print_good "최대 사용 기간 ${MAX}일 입니다." "$VUL_ITEM"
else
	print_weak "최대 사용 기간 ${MAX}일 입니다." "$VUL_ITEM"
	FLAG=True
fi
if [ $MIN == 1 ]; then
	print_good "최소 사용 기간 ${MIN}일 입니다." "$VUL_ITEM"
else
	print_weak "최소 사용 기간 ${MIN}일 입니다." "$VUL_ITEM"
	FLAG=True
fi
if [ $DATE == 7 ]; then
	print_good "기간 만료 경고 기간 ${DATE}일 입니다." "$VUL_ITEM"
else
	print_weak "기간 만료 경고 기간 ${DATE}일 입니다." "$VUL_ITEM"
	FLAG=True
fi

if [ $FLAG == "True" ]; then
	print_info "=> vi /etc/login.defs \npass_warn_age = 7 \npass_max_days = 60 \npass_min_day = 1" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 1.3 계정 잠금 임계값 설정(U-03)

VUL_ITEM="U-03"
start_diagnosis "$VUL_ITEM"

cat /etc/pam.d/system-auth | grep "^auth required /lib/security/pam_tally.so" | grep deny > /dev/null 2>&1

if [ $? -eq 0 ]; then
	cat /etc/pam.d/system-auth | grep "^account required /lib/security/pam_tally.so" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		print_good "계정 잠금 임계값이 설정되어 있는 경우입니다." "$VUL_ITEM"
	else
		print_weak "계정 잠금 임계값이 설정되지 않은 경우 입니다." "$VUL_ITEM"
		print_info " => vi /etc/pam.d/system-auth 확인. \nauth required /lib/security/pam_tally.so deny=5 unlock_time=120 no_magic_root \naccount required /lib/security/pam_tally.so no_magic_root reset" "$VUL_ITEM" 
	fi
else
	print_weak "계정 잠금 임계값이 설정되지 않은 경우 입니다." "$VUL_ITEM"
	print_info " => vi /etc/pam.d/system-auth 확인. \nauth required /lib/security/pam_tally.so deny=5 unlock_time=120 no_magic_root \naccount required /lib/security/pam_tally.so no_magic_root reset" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 1.4 패스워드 파일 보호(U-04)

VUL_ITEM="U-04"
start_diagnosis "$VUL_ITEM"

if [ "`cat /etc/passwd | grep "^root" | awk -F: '{print $2}'`" = x ]; then
	if test -r /etc/shadow; then
		print_good "Shadow 패스워드 시스템을 사용 중입니다." "$VUL_ITEM"
	else
		print_weak "Passwd 패스워드 시스템을 사용 중입니다." "$VUL_ITEM"
		print_info "=> pwconv \n 쉐도우 패스워드 정책 적용" "$VUL_ITEM"
	fi
fi

end_diagnosis "$VUL_ITEM"

set +o xtrace
