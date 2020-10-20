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

echo "+-------------------------------------------------------------------+"
echo "| 파일 및 디렉터리 관리에 대한 Linux 서버 취약점 분석을 시작합니다. |"
echo "+-------------------------------------------------------------------+"
echo

## 2.1 root 홈, 패스 디렉터리 권한 및 패스 설정(U-05)

VUL_ITEM="U-05"
start_diagnosis "$VUL_ITEM"

if echo $PATH |  egrep -e "^\." -e ":\.[^.]" > /dev/null 2>&1 ; then
	print_weak "PATH 환경변수 값에 '.'이 맨 앞에 포함되어 있습니다." "$VUL_ITEM"
	print_info "=> vi /etc/profile 파일에서 수정\n (수정 전) PATH=.:\$PATH:\$HOME/bin \n(수정 후) PATH=\$PATH:\$HOME/bin:." "$VUL_ITEM"
elif echo $PATH | grep :: > /dev/null 2>&1 ; then
	print_weak "PATH 환경변수 값에 '::'이 포함되어 있습니다." "$VUL_ITEM"
	print_info "=> vi /etc/profile 파일에서 수정 \n(수정 전) PATH=\$PATH::\$HOME/bin \n(수정 후) PATH=\$PATH:\$HOME/bin:" "$VUL_ITEM"
else
	print_good "PATH 설정에 문제가 없습니다." "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.2 파일 및 디렉터리 소유자 설정(U-06)

VUL_ITEM="U-06"
start_diagnosis "$VUL_ITEM"

if test -f `find / \( -nouser -o -nogroup \) -xdev -ls 2>/dev/null`; then
	print_good "소유자 혹은 그룹이 없는 파일 및 디렉터리가 존재하지 않습니다." "$VUL_ITEM"
else
	print_weak "소유자 혹은 그룹이 없는 파일 및 디렉터리가 존재합니다." "$VUL_ITEM"
        print_info "=> vi /etc/profile 파일에서 수정" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.3 /etc/passwd 파일 소유자 및 권한 설정(U-07)

VUL_ITEM="U-07"
start_diagnosis "$VUL_ITEM"

if ls -l /etc/passwd | grep '\-rw\-r\-\-r\-\- 1 root' > /dev/null 2>&1 ; then
        print_good "/etc/passwd 파일의 소유자는 root, 권한 644로 정상입니다." "$VUL_ITEM"
else
	print_weak "/etc/passwd 파일의 소유자 혹은 권한이 잘못 설정되어 있습니다." "$VUL_ITEM"
        print_info "=> chown root /etc/passwd \n=> chmod 644 /etc/passwd" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.4 /etc/passwd 파일 소유자 및 권한 설정(U-08)

VUL_ITEM="U-08"
start_diagnosis "$VUL_ITEM"

if test `ls -l /etc/shadow | awk {'print $1'} ` = -r--------.; then
	print_good "권한: `ls -l /etc/shadow | awk {'print $1'}`" "$VUL_ITEM"
else
        if test `ls -l /etc/shadow | awk {'print $1'} ` = ----------.; then
		print_good "권한: `ls -l /etc/shadow | awk {'print $1'}`" "$VUL_ITEM"
        else
		print_weak "권한: `ls -l /etc/shadow | awk {'print $1'}`" "$VUL_ITEM"
        	print_info "=> chmod 400 /etc/shadow" "$VUL_ITEM"
        fi
fi
if test `ls -l /etc/shadow | awk {'print $3'}` = root; then
	print_good "소유자: `ls -l /etc/shadow | awk {'print $3'}`" "$VUL_ITEM"
else
	print_weak "소유자: `ls -l /etc/shadow | awk {'print $3'}`" "$VUL_ITEM"
        print_info "=> chown root /etc/shadow" "$VUL_ITEM"
fi
if test `ls -l /etc/shadow | awk {'print $4'} ` = root; then
	print_good "그룹: `ls -l /etc/shadow | awk {'print $4'}`" "$VUL_ITEM"
else
	print_weak "그룹: `ls -l /etc/shadow | awk {'print $4'}`" "$VUL_ITEM"
        print_info "=> chown root:root /etc/shadow" "$VUL_ITEM"
fi


end_diagnosis "$VUL_ITEM"


## 2.5 /etc/hosts 파일 소유자 및 권한 설정(U-09)

VUL_ITEM="U-09"
start_diagnosis "$VUL_ITEM"

if ls -l /etc/hosts | grep '\-rw\-\-\-\-\-\-\- 1 root' > /dev/null 2>&1 ; then
        print_good "/etc/hosts 파일의 소유자는 root, 권한 600으로 정상입니다." "$VUL_ITEM"
else
        print_weak "/etc/hosts 파일의 소유자 혹은 권한이 잘못 설정되어 있습니다." "$VUL_ITEM"
        print_info "=> chown root /etc/hosts \n=> chmod 600 /etc/hosts" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.6 /etc/(x)inetd.conf 파일 소유자 및 권한 설정(U-10)

VUL_ITEM="U-10"
start_diagnosis "$VUL_ITEM"

if test -f /etc/inetd.conf; then
	print_good "inetd.conf 파일이 존재합니다." "$VUL_ITEM"
	root=`ls -l /etc/inetd.conf | awk '{print $3}'`
	per=`ls -l /etc/inetd.conf | awk '{print $1}'`
        if [ $root = root ]; then
		print_good "inetd.conf 파일 소유자: $IO" "$VUL_ITEM"
        else
		print_weak "inetd.conf 파일 소유자: $IO" "$VUL_ITEM"
        	print_info "=> chown root /etc/inetd.conf" "$VUL_ITEM"
        fi
        if [ $per = -rw-------. ]; then
		print_good "inetd.conf 파일 권한: $IP" "$VUL_ITEM"
        else
		print_weak "inetd.conf 파일 권한: $IP" "$VUL_ITEM"
        	print_info "=> chmod 600 /etc/inetd.conf" "$VUL_ITEM"
        fi
else
	print_weak "inetd.conf 파일이 존재하지 않습니다" "$VUL_ITEM"
fi
if test -f /etc/xinetd.conf; then
	print_good "xinetd.conf 파일이 존재합니다" "$VUL_ITEM"
	xroot=`ls -l /etc/xinetd.conf | awk '{print $3}'`
        xper=`ls -l /etc/xinetd.conf | awk '{print $1}'`
        if [ $xroot = root ]; then
		print_good "xinetd.conf 파일 소유자: $XO" "$VUL_ITEM"
        else
		print_weak "xinetd.conf 파일 소유자: $XO" "$VUL_ITEM"
        	print_info "=> chown root /etc/xinetd.conf" "$VUL_ITEM"
        fi
        if [ $xper = -rw-------. ]; then
		print_good "xinetd.conf 파일 권한: $XP" "$VUL_ITEM"
        else
		print_weak "xinetd.conf 파일 권한: $XP" "$VUL_ITEM"
        	print_info "=> chmod 600 /etc/inetd.conf" "$VUL_ITEM"
        fi
else
	print_weak "xinetd.conf 파일이 존재하지 않습니다" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.7 /etc/syslog.conf 파일 소유자 및 권한 설정(U-11)

VUL_ITEM="U-11"
start_diagnosis "$VUL_ITEM"

if ls -l /etc/rsyslog.conf | grep '\-rw\-r\-\-r\-\- 1 root' > /dev/null 2>&1 ; then
        print_good "/etc/rsyslog.conf 파일의 소유자는 root, 권한 644로 정상입니다." "$VUL_ITEM"
else
        print_weak "/etc/rsyslog.conf 파일의 소유자 혹은 권한이 잘못 설정되어 있습니다." "$VUL_ITEM"
        print_info "=> chown root /etc/rsyslog.conf \n=> chmod 644 /etc/rsyslog.conf" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.8 /etc/services 파일 소유자 및 권한 설정(U-12)

VUL_ITEM="U-12"
start_diagnosis "$VUL_ITEM"

root=`ls -l /etc/services | awk '{print $3}'`
per=`ls -l /etc/services | awk '{print $1}'`

if [ $root = root ]; then
	print_good "services 파일 소유자: $root" "$VUL_ITEM"
else
	print_weak "services 파일 소유자: $root" "$VUL_ITEM"
        print_info "=> chown root /etc/services" "$VUL_ITEM"
fi

if [ $per = -rw-r--r--. ]; then
	print_good "services 파일 권한: $per" "$VUL_ITEM"
else
	print_weak "services 파일 권한: $per" "$VUL_ITEM"
        print_info "=> chmod 644 /etc/services" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.9 SUID, SGID, Sticky bit 설정 및 권한 설정(U-13)

VUL_ITEM="U-13"
start_diagnosis "$VUL_ITEM"

FILE1=U-13_filelist
LOG_FILE=log/U-13.log

cat $FILE1 | while read FILENAME1
do
        `ls -l $FILENAME1 | awk '{print $1,$9}' >> $LOG_FILE`
done

cat $LOG_FILE | while read PERM FILENAME2
do
        if [ `echo $PERM | egrep '(s|t)'` ]; then
		print_good "$FILENAME2 파일의 특수 권한이 설정되어 있습니다." "$VUL_ITEM"
        else
        	print_weak "$FILENAME2 파일의 특수 권한이 설정되어 있지 않습니다." "$VUL_ITEM"
        fi
done

if [ -f $LOG_FILE ]; then
	rm $LOG_FILE
fi

end_diagnosis "$VUL_ITEM"


## 2.10 사용자, 시스템 시작파일 및 환경파일 소유자 및 권한 설정(U-14)

VUL_ITEM="U-14"

start_diagnosis "$VUL_ITEM"

U14_FILE=log/U-14.log

ls -lart ~/.* | sed '/^$/d' | awk 'BEGIN{OFS=";"}{print $1,$4,$9}' | egrep -v "^d|^l" | egrep -v "/|total" >> $U14_FILE

for i in `cat $U14_FILE`; do
        id2=`echo $i | cut -d";" -f2`
        a=`echo $i | cut -d";" -f1`
        hper=`echo $i | cut -d";" -f1 | cut -c 9`
        name=`echo $i | cut -d";" -f3`

	if [ "$USER" = "$id2" ] && [ "$hper" != "w" ]; then
		print_good "$name파일의 소유자, 권한이 안전합니다." "$VUL_ITEM"
        elif [ "$USER" = "$id2" ]; then
		print_weak "$name파일의 소유자는 동일하나 권한이 다릅니다. 권한: $a" "$VUL_ITEM"
        else
		print_weak "$name은 다른 소유자의 파일입니다. 소유자: $id2" "$VUL_ITEM"
	fi
done

if [ -f $U14_FILE ]; then
        rm $U14_FILE
fi

end_diagnosis "$VUL_ITEM"

## 2.12 /dev에 존재하지 않는 device 파일 점검(U-16)

VUL_ITEM="U-16"
start_diagnosis "$VUL_ITEM"

touch Device_file.txt
DF="Device_file.txt"
find /dev -type f -exec ls -l {} \; > $DF
check=`ls -l Device_file.txt | awk '{print $5}'`
check2=`cat Device_file.txt`

if [ $check == 0 ]; then
        print_good "존재하지 않는 Device 파일이 없습니다." "$VUL_ITEM"
        rm -rf $DF
else
        rm -rf $DF
        print_weak "존재하지 않는 Device 파일이 있습니다: $check2" "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


## 2.13 $HOME/.rhosts, hosts.equiv 사용 금지(U-17)

VUL_ITEM="U-17"
start_diagnosis "$VUL_ITEM"

if [ -f /etc/hosts.equiv ]; then
        if ls -l /etc/hosts.equiv | grep '\-rw\-\-\-\-\-\-\- 1 root' > /dev/null 2>&1 ; then
	        print_good "/etc/hosts.equiv를 사용 중이며, 소유자 및 권한이 재대로 설정되어 있습니다." "$VUL_ITEM"
	else
	        print_weak "/etc/hosts.equiv를 사용 중이며, 소유자 및 권한이 재대로 설정되어 있지 않습니다." "$VUL_ITEM"
	        print_info "=> chown root /etc/hosts.equiv \n=> chmod 600 /etc/hosts.equiv" "$VUL_ITEM"
	fi
else
	print_good "/etc/hosts.equiv 파일을 사용하고 있지 않습니다." "$VUL_ITEM"

fi

if [ -f $HOME/.rhosts ]; then
        if ls -l $HOME/.rhosts | grep '\-rw\-\-\-\-\-\-\- 1 root' > /dev/null 2>&1 ; then
		print_good "\$HOME/.rhosts를 사용 중이며, 소유자 및 권한이 재대로 설정되어 있습니다." "$VUL_ITEM"
	else
		print_weak "\$HOME/.rhosts를 사용 중이며,  소유자 혹은 권한이 재대로 설정되어 있지 않습니다." "$VUL_ITEM"
                print_info "=> chown root \$HOME/.rhosts \n=> chmod 600 \$HOME/.rhosts" "$VUL_ITEM"
	fi
else
	print_good "\$HOME/.rhosts 파일을 사용하고 있지 않습니다." "$VUL_ITEM"
fi

end_diagnosis "$VUL_ITEM"


set +o xtrace
