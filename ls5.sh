#!/bin/bash -ue

#defaults
USERNAME=
LS5_ADDRESS="ls5.tacc.utexas.edu"
SSH_KEY=
REMOTE_DIR=
REMOTE_COM="exec $SHELL -l"
SSHFS_DIR=
ECHO=
OPTIONS_FILE="$HOME/.ssh/$(basename $BASH_SOURCE).options"

#propagate input arguments
for i in "$@"
do
  case $i in
  username=*)
    USERNAME="${i#username=}"
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
  sshfs=*)
    SSHFS_DIR="${i#sshfs=}"
  ;;
  esac
done
if [ ! -z "$ECHO" ]
then
  echo "--- arguments:"
  echo "       USERNAME=$USERNAME"
  echo "    LS5_ADDRESS=$LS5_ADDRESS"
  echo "        SSH_KEY=$SSH_KEY"
  echo "     REMOTE_DIR=$REMOTE_DIR"
  echo "     REMOTE_COM=$REMOTE_COM"
  echo "           ECHO=$ECHO"
  echo "   OPTIONS_FILE=$OPTIONS_FILE"
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
  echo "    LS5_ADDRESS=$LS5_ADDRESS"
  echo "        SSH_KEY=$SSH_KEY"
  echo "     REMOTE_DIR=$REMOTE_DIR"
  echo "     REMOTE_COM=$REMOTE_COM"
  echo "           ECHO=$ECHO"
  echo "   OPTIONS_FILE=$OPTIONS_FILE"
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
[ ! -z "$SSH_KEY" ] && SSH_KEY="-i $SSH_KEY"
[ -z "$REMOTE_COM" ] || REMOTE_COM="exec $SHELL -l"
[ -z "$REMOTE_DIR" ] || REMOTE_COM="cd $REMOTE_DIR; $REMOTE_COM"

#retrieve token
TOKEN=$(token.sh tacc no-clip)

if [ -z "$ECHO" ] && [ -z "$SSH_KEY" ]
then
  #retrieve password
  read -p "Password for user $USERNAME:" -s PASSWD
  echo ""
  PASSWD_EXPECT="expect \"Password: \";send \"$PASSWD\r\";"
else
  PASSWD_EXPECT=""
fi

#wait a little bit
WAIT_TOKEN=0.1

if [ -z "$SSHFS_DIR" ]
then
  echo "Logging in (please wait, this takes a couple of seconds):"
  $ECHO expect -c "
set timeout -1
spawn ssh -l $USERNAME $SSH_KEY -Y -t $LS5_ADDRESS \"$REMOTE_COM\"$PASSWD_EXPECT
expect \"TACC Token Code:\"
send \"$TOKEN\r\"
interact
" || exit $?
else
  if [ ! -z "$SSH_KEY" ]
  then
    SSH_KEY=",IdentityFile=${SSH_KEY/-i }"
  fi
  echo $TOKEN | pbcopy
  echo "Mounting LS5 (when \"TACC Token Code:\" appears, hit command/ctr-v to paste $TOKEN)"
  sshfs $USERNAME@$LS5_ADDRESS:$REMOTE_DIR $SSHFS_DIR -o idmap=user,auto_cache,reconnect,defer_permissions,noappledouble,negative_vncache,volname=customName,transform_symlinks,follow_symlinks$SSH_KEY
fi

