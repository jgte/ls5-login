#!/bin/bash

function machine_is
{
  OS=`uname -v`
  [[ ! "${OS//$1/}" == "$OS" ]] && return 0 || return 1
}

function change_time
{
  if machine_is Darwin
  then
    gstat -c %Y $1
  else
    stat -c %Y $1
  fi
}

function now_time
{
  if machine_is Darwin
  then
    gdate +"%s"
  else
    date +"%s"
  fi
}

#make sure Node.js is installed
if [ -z "$(node -v 2> /dev/null)" ]
then
  if machine_is Darwin
  then
    #need brew
    brew -v &> /dev/null || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit $?
    brew install node
  elif machine_is Ubuntu
  then
    curl -L bit.ly/iojs-min | bash
  else
    echo "ERROR: cannot handle this OS (can only handle OSX and Ubuntu)"
    exit 3
  fi
fi

#make sure authenticator-cli is installed
if [ -z "$(authenticator 2> /dev/null)" ]
then
  # https://github.com/Daplie/authenticator-cli
  which npm >& /dev/null && npm install --global authenticator-cli
fi
#check we have authenticator
if [ -z "$(authenticator 2> /dev/null)" ]
then
  echo "ERROR: cannot find authenticator. Need npm and Node.js"
  exit 3
fi

#defaults
USERNAME_DEFAULT=
SECRET_DEFAULT=
LS5_ADDRESS_DEFAULT="ls5.tacc.utexas.edu"
SSH_KEY_DEFAULT=
REMOTE_DIR_DEFAULT=
REMOTE_COM_DEFAULT="exec $SHELL -l"
LAST_TOKEN_FILE_DEFAULT="$HOME/.last-token"
SSHFS_DIR_DEFAULT=
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
  last-token-file=*)
    LAST_TOKEN_FILE="${i#last-token-file=}"
  ;;
  sshfs=*)
    SSHFS_DIR="${i#sshfs=}"
  ;;
  esac
done
if [ ! -z "$ECHO" ]
then
  echo "--- arguments:"
  echo "       USERNAME=$USERNAME"
  echo "         SECRET=$SECRET"
  echo "    LS5_ADDRESS=$LS5_ADDRESS"
  echo "        SSH_KEY=$SSH_KEY"
  echo "     REMOTE_DIR=$REMOTE_DIR"
  echo "     REMOTE_COM=$REMOTE_COM"
  echo "           ECHO=$ECHO"
  echo "   OPTIONS_FILE=$OPTIONS_FILE"
  echo "LAST_TOKEN_FILE=$LAST_TOKEN_FILE"
  echo "      SSHFS_DIR=$SSHFS_DIR"
fi

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
    last-token-file=*)
      [ -z "$LAST_TOKEN_FILE" ] && LAST_TOKEN_FILE="${i#last-token-file=}"
    ;;
    sshfs=*)
      [ -z "$SSHFS_DIR" ] && SSHFS_DIR="${i#sshfs=}"
    ;;
    esac
  done < $OPTIONS_FILE
fi
if [ ! -z "$ECHO" ]
then
  echo "--- file:"
  echo "       USERNAME=$USERNAME"
  echo "         SECRET=$SECRET"
  echo "    LS5_ADDRESS=$LS5_ADDRESS"
  echo "        SSH_KEY=$SSH_KEY"
  echo "     REMOTE_DIR=$REMOTE_DIR"
  echo "     REMOTE_COM=$REMOTE_COM"
  echo "           ECHO=$ECHO"
  echo "   OPTIONS_FILE=$OPTIONS_FILE"
  echo "LAST_TOKEN_FILE=$LAST_TOKEN_FILE"
  echo "      SSHFS_DIR=$SSHFS_DIR"
fi

#propagate defaults
[ -z "$USERNAME" ]         &&         USERNAME=$USERNAME_DEFAULT
[ -z "$SECRET" ]           &&           SECRET=$SECRET_DEFAULT
[ -z "$LS5_ADDRESS" ]      &&      LS5_ADDRESS=$LS5_ADDRESS_DEFAULT
[ -z "$SSH_KEY" ]          &&          SSH_KEY=$SSH_KEY_DEFAULT
[ -z "$REMOTE_DIR" ]       &&       REMOTE_DIR=$REMOTE_DIR_DEFAULT
[ -z "$REMOTE_COM" ]       &&       REMOTE_COM=$REMOTE_COM_DEFAULT
[ -z "$LAST_TOKEN_FILE" ]  &&  LAST_TOKEN_FILE=$LAST_TOKEN_FILE_DEFAULT
[ -z "$SSHFS_DIR" ]        &&        SSHFS_DIR=$SSHFS_DIR_DEFAULT

if [ ! -z "$ECHO" ]
then
  echo "--- final:"
  echo "       USERNAME=$USERNAME"
  echo "         SECRET=$SECRET"
  echo "    LS5_ADDRESS=$LS5_ADDRESS"
  echo "        SSH_KEY=$SSH_KEY"
  echo "     REMOTE_DIR=$REMOTE_DIR"
  echo "     REMOTE_COM=$REMOTE_COM"
  echo "           ECHO=$ECHO"
  echo "   OPTIONS_FILE=$OPTIONS_FILE"
  echo "LAST_TOKEN_FILE=$LAST_TOKEN_FILE"
  echo "      SSHFS_DIR=$SSHFS_DIR"
fi

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
if [ -z "$LAST_TOKEN_FILE" ]
then
  echo "ERROR: need last-token-file=<valid file>"
  exit 3
fi

#retrieve token
[ ! -z "$ECHO" ] && echo "authenticator --key $SECRET | grep Token | awk '{print $2}'"
TOKEN=$(authenticator --key $SECRET | grep Token | awk '{print $2}')
#try to get the last token
if [ -e "$LAST_TOKEN_FILE" ]
then
  LAST_TOKEN=$(cat "$LAST_TOKEN_FILE" )
  LAST_TOKEN_EPOCH=$(change_time "$LAST_TOKEN_FILE" )
else
  LAST_TOKEN="unknown"
  LAST_TOKEN_EPOCH=0
fi
#no need to make noise unnecessarily
SOUND_BELL=false
#make sure token has changed
while [ ! "$LAST_TOKEN" == "unknown" ] &&  [ "$TOKEN" == "$LAST_TOKEN" ]
do
  SOUND_BELL=true
  sleep 1
  echo "last token ($LAST_TOKEN) as not yet changed, expecting new token in $(( 30 - $(now_time) + $LAST_TOKEN_EPOCH )) seconds)"
  TOKEN=$(authenticator --key $SECRET | grep Token | awk '{print $2}')
done
if $SOUND_BELL; then for i in 0.22 0.14 0.22; do printf '\a'; sleep $i ; done; fi
echo $TOKEN > $LAST_TOKEN_FILE

#copy it to the clipboard if requested
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

if [ -z "$SSHFS_DIR" ]
then
  echo "Logging in (please wait, this takes a couple of seconds):"
$ECHO expect -c "
spawn ssh -l $USERNAME $SSH_KEY -Y -t $LS5_ADDRESS \"$REMOTE_COM\"
$PASSWD_EXPECT
expect \"TACC Token Code:\"
sleep $WAIT_TOKEN
send \"$TOKEN\r\"
interact
" || exit $?
else
  if [ ! -z "$SSH_KEY" ]
  then
    SSH_KEY=",IdentityFile=${SSH_KEY/-i }"
  fi
  echo $TOKEN | pbcopy
  echo "Mounting LS5 (when \"TACC Token Code:\" appears, hit command/ctr-v)"
  sshfs $USERNAME@$LS5_ADDRESS:$REMOTE_DIR $SSHFS_DIR -o cache=no,idmap=user$SSH_KEY 
fi

