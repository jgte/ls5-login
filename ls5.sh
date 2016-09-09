#!/bin/bash

#define here the secret file
SECRET_FILE=<some file with a valid QR secret>

#define here the username
USER_NOW=<some valid username>

#define here the address of ls5
LS5_ADDRESS=ls5.tacc.utexas.edu

function machine_is
{
  OS=`uname -v`
  [[ ! "${OS//$1/}" == "$OS" ]] && return 0 || return 1
}

#make sure Node.js is installed
if [ -z "$(node -v 2> /dev/null)" ]
then
  if [ machine_is Darwin ]
  then
    #need brew
    brew -v &> /dev/null || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install node
  else
    curl -L bit.ly/iojs-min | bash
  fi
fi

#make sure authenticator-cli is installed
if [ -z "$(authenticator 2> /dev/null)" ]
then
  # https://github.com/Daplie/authenticator-cli
  npm install --global authenticator-cli
fi

#defaults
CSR=
ECHO=
SSHKEY_FILE=
REMOTE_COM="exec $SHELL -l"

#propagate input arguments
for i in "$@"
do
  case $i in
  debug|echo)
    ECHO='echo '
  ;;
  csr)
    CSR='login3.'
  ;;
  key=*)
    SSHKEY_FILE="-i ${i#key=}"
  ;;
  dir=*)
    REMOTE_COM="cd ${i#dir=}; $REMOTE_COM"
  ;;
  com=*)
    REMOTE_COM="${i#com=}"
  ;;
  esac
done

#retrieve token
TOKEN=$(authenticator --key $(cat $SECRET_FILE) | grep Token | awk '{print $2}')
if [[ ! "$@" == "${@/token/}" ]]
then
  if machine_is Darwin
  then
    echo $TOKEN | pbcopy
  elif machine is Ubuntu
  then
    if which xclip &> /dev/null
    then
      echo $TOKEN | xclip -selection clipboard
    else
      echo "Please run 'sudo apt-get install xclip'"
    fi
  else
    echo "ERROR: cannot copy token to the clipboard, this OS is not supported."
  fi
  echo "Copied to clipboard the token $TOKEN"
  exit
fi

if [ -z "$ECHO" ] && [ -z "$SSHKEY_FILE" ]
then
  #retrieve password
  read -p "Password for user $USER_NOW:" -s PASSWD
  echo ""
  PASSWD_EXPECT="expect \"Password: \"
send \"$PASSWD\r\""
else
  PASSWD_EXPECT=
fi

#wait a little bit
WAIT_TOKEN=0.1

echo "Logging in (please wait, this takes a couple of seconds):"
$ECHO expect -c "
spawn ssh -l $USER_NOW $SSHKEY_FILE -Y -t $CSR$LS5_ADDRESS \"$REMOTE_COM\"
$PASSWD_EXPECT
expect \"TACC Token: \"
sleep $WAIT_TOKEN
send \"$TOKEN\r\"
interact
" || exit $?

