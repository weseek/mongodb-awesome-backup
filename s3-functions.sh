# default settings
AWSCLI="/usr/bin/aws"
AWSCLI_PUT_OPT="s3 cp"
AWSCLI_LIST_OPT="s3 ls"
AWSCLI_DEL_OPT="s3 rm"

DATE_CMD="/bin/date"

# Check the existence of specified file.
# If it is found, this returns 0
# Otherwise, this returns 1(which aws returns)
# arguments: 1. s3 url (s3://.../...)
s3_exists() {
	if [ $# -ne 1 ]; then return 255; fi
	${AWSCLI} ${AWSCLI_LIST_OPT} $1 >/dev/null
}

# Output the list of the files on specified S3 URL.
# arguments: 1. s3 url (s3://...)
s3_list_files() {
	${AWSCLI} ${AWSCLI_LIST_OPT} $1
}

# Delete the specified file.
# arguments: 1. s3 url (s3://.../...)
s3_delete_file() {
	if [ $# -ne 1 ]; then return 255; fi
	${AWSCLI} ${AWSCLI_DEL_OPT} $1
}

# Put the specified file.
# arguments: 1. local filename
#            2. target s3 url (s3://...)
s3_put_file() {
	if [ $# -ne 2 ]; then return 255; fi
	${AWSCLI} ${AWSCLI_PUT_OPT} $1 $2
}

# Delete the local file, if it is uploaded on S3
# arguments: 1. file name
#            2. directory name
#            3. s3 url where the file placed(s3://...)
delete_localfile_if_exists_on_s3() {
	if [ $# -ne 3 ]; then return 255; fi
	TARBALL=$1
	TARBALL_FULLPATH="$2/$1"
	if s3_exists $3/$1; then
		rm -f ${TARBALL_FULLPATH}
		echo "DELETED temporary tarball: ${TARBALL}"
	else
		echo "not deleted temporary tarball: ${TARBALL} (upload was unsuccessful)"
	fi
}

# Create today's date string(YYYYmmdd)
create_today_yyyymmdd() {
	create_past_yyyymmdd 0
}

# Create date string of n days ago
# arguments: 1. how many days ago
create_past_yyyymmdd() {
	if [ $# -ne 1 ]; then return 255; fi
	echo `/bin/date +%Y%m%d -d "$1 days ago"`
}

# Check whether the day is deleting backup file or not
# arguments: 1. how many days ago to be deleted
#            2. divide number
check_is_delete_backup_day() {
	if [ $# -ne 2 ]; then return 255; fi
	MOD_COUNT=`/usr/bin/expr $(/bin/date +%s -d "$1 days ago") / 86400 % $2`
	if [ ${MOD_COUNT} -ne 0 ]; then
		return 0
	else
		return 255
	fi
}

# arguments: 1. s3 url (s3://.../...)
#            2. how many days ago to be deleted
#            3. divide number
s3_delete_file_if_delete_backup_day() {
	if [ $# -ne 3 ]; then return 255; fi
	if check_is_delete_backup_day $2 $3; then
		if s3_exists $1; then
			s3_delete_file $1
			echo "DELETED past backuped file on S3: $1"
		else
			echo "not found past backuped file on S3: $1"
		fi
	fi
}
