#!/bin/bash

#define here the secret file
SECRET_FILE=<some file with the 32 character secret string>

#define here the username
USER_NOW=<some valid username>

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

if [[ ! "$@" == "${@/debug/}" ]] || [[ ! "$@" == "${@/echo/}" ]]
then
  ECHO='echo '
else
  ECHO=''
fi

if [[ ! "$@" == "${@/csr/}" ]]
then
  CSR='login3.'
else
  CSR=''
fi

if [ -z "$ECHO" ]
then
  #retrieve password
  read -p "Password for user $USER_NOW:" -s PASSWD
  echo ""
else
  PASSWD="fake password"
fi

#retrieve token
TOKEN=$(authenticator --key $(cat $SECRET_FILE) | grep Token | awk '{print $2}')
echo "Token is: $TOKEN"

#wait a little bit
WAIT_TOKEN=0.1

echo "Logging in (please wait, token will take $WAIT_TOKEN to be sent):"
$ECHO expect -c "
  spawn ssh -l $USER_NOW -Y ${CSR}ls5.tacc.utexas.edu
  expect \"Password: \"
  send \"$PASSWD\r\"
  expect \"TACC Token: \"
  sleep $WAIT_TOKEN
  send \"$TOKEN\r\"
  interact
" || exit $?
