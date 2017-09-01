. $GOT_SRC/got_env
echo "starting timer for list $1 and hash $2"
FILE=$1
HASH=$2

START_TIME=$(date +"%Y-%m-%dT%H:%M:%S")

function  finish {
  END_TIME=$(date +"%Y-%m-%dT%H:%M:%S")
  TOKEN_LINE=$(echo "-> $HASH $START_TIME $END_TIME")
  echo $TOKEN_LINE >> $FILE
  exit
}
trap finish EXIT
while read line
do
  echo ""
done 


