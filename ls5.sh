#!/bin/bash

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
USERNAME_DEFAULT=
SECRET_DEFAULT=
LS5_ADDRESS_DEFAULT="ls5.tacc.utexas.edu"
SSH_KEY_DEFAULT=
REMOTE_DIR_DEFAULT=
REMOTE_COM_DEFAULT="exec $SHELL -l"
ECHO=
OPTIONS_FILE="$HOME/.ssh/$(basename $BASH_SOURCE).options"

#propagate input arguments
for i in "$@"
do
  case $i in
  username=*)
    USERNAME="${i#username=}"
  ;;
  secret=*)
    SECRET="${i#secret=}"
  ;;
  ls5-address=*)
    LS5_ADDRESS="${i#ls5-address=}"
  ;;
  ssh-key=*)
    SSH_KEY="${i#ssh-key=}"
  ;;
  remote-dir=*)
    REMOTE_DIR="${i#remote-dir=}"
  ;;
  remote-com=*)
    REMOTE_COM="${i#remote-com=}"
  ;;
  debug|echo)
    ECHO='echo '
  ;;
  options-file=*)
    OPTIONS_FILE="${i#options-file=}"
  ;;
  esac
done

#propagate options file (if file is present and options not given in argument list)
if [ ! -z "$OPTIONS_FILE" ]
then
  while IFS='' read -r i || [[ -n "$i" ]]
  do
    case $i in
    debug|echo)
      ECHO='echo '
    ;;
    username=*)
      [ -z "$USERNAME" ] && USERNAME="${i#username=}"
    ;;
    secret=*)
      [ -z "$SECRET" ] && SECRET="${i#secret=}"
    ;;
    ls5-address=*)
      [ -z "$LS5_ADDRESS" ] && LS5_ADDRESS="${i#ls5-address=}"
    ;;
    ssh-key=*)
      [ -z "$SSH_KEY" ] && SSH_KEY="${i#ssh-key=}"
    ;;
    remote-dir=*)
      [ -z "$REMOTE_DIR" ] && REMOTE_DIR="${i#remote-dir=}"
    ;;
    remote-com=*)
      [ -z "$REMOTE_COM" ] && REMOTE_COM="${i#remote-com=}"
    ;;
    esac
  done < $OPTIONS_FILE
fi

#propagate defaults
[ -z "$USERNAME" ]    &&    USERNAME=$USERNAME_DEFAULT
[ -z "$SECRET" ]      &&      SECRET=$SECRET_DEFAULT
[ -z "$LS5_ADDRESS" ] && LS5_ADDRESS=$LS5_ADDRESS_DEFAULT
[ -z "$SSH_KEY" ]     &&     SSH_KEY=$SSH_KEY_DEFAULT
[ -z "$REMOTE_DIR" ]  &&  REMOTE_DIR=$REMOTE_DIR_DEFAULT
[ -z "$REMOTE_COM" ]  &&  REMOTE_COM=$REMOTE_COM_DEFAULT


#sanity and handling
if [ -z "$USERNAME" ]
then
  echo "ERROR: need username=<valid username>"
  exit 3
fi
if [ -z "$LS5_ADDRESS" ]
then
  echo "ERROR: need ls5-address=<IP address of Lonestar5>"
  exit 3
fi
if [ -z "$SECRET" ]
then
  echo "ERROR: need secret=<valid 32 character secret token>"
  exit 3
fi
[ ! -z "$SSH_KEY" ] && SSH_KEY="-i $SSH_KEY"
[ -z "$REMOTE_COM" ] || REMOTE_COM="exec $SHELL -l"
[ -z "$REMOTE_DIR" ] || REMOTE_COM="cd $REMOTE_DIR; $REMOTE_COM"

#retrieve token
TOKEN=$(authenticator --key $SECRET | grep Token | awk '{print $2}')
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
    echo "The token is $TOKEN (cannot copy token to the clipboard, this OS is not supported: implementation needed)"
  fi
  echo "Copied to clipboard the token $TOKEN"
  exit
fi

if [ -z "$ECHO" ] && [ -z "$SSH_KEY" ]
then
  #retrieve password
  read -p "Password for user $USERNAME:" -s PASSWD
  echo ""
  PASSWD_EXPECT="expect \"Password: \"
send \"$PASSWD\r\""
else
  PASSWD_EXPECT=""
fi

#wait a little bit
WAIT_TOKEN=0.1

echo "Logging in (please wait, this takes a couple of seconds):"
$ECHO expect -c "
spawn ssh -l $USERNAME $SSH_KEY -Y -t $LS5_ADDRESS \"$REMOTE_COM\"
$PASSWD_EXPECT
expect \"TACC Token: \"
sleep $WAIT_TOKEN
send \"$TOKEN\r\"
interact
" || exit $?

