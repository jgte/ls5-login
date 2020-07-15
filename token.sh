#!/bin/bash -ue

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

function echoerr { echo "$@" 1>&2 ; }

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
    echoerr "ERROR: cannot handle this OS (can only handle OSX and Ubuntu)"
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
  echoerr "ERROR: cannot find authenticator. Need npm and Node.js"
  exit 3
fi

#defaults
SERVICE=
SECRET=
LAST_TOKEN_FILE="$HOME/.last-token"
ECHO=
OPTIONS_FILE="$HOME/.ssh/$(basename $BASH_SOURCE).options"
LIST=false
FORCE=false
NOCLIP=false
#propagate input arguments
for i in "$@"
do
  case $i in
  service=*)
    SERVICE="${i#service=}"
  ;;
  secret=*)
    SECRET="${i#secret=}"
  ;;
  debug|echo)
    ECHO=echoerr
  ;;
  options-file=*)
    OPTIONS_FILE="${i#options-file=}"
  ;;
  last-token-file=*)
    LAST_TOKEN_FILE="${i#last-token-file=}"
  ;;
  list)
    LIST=true
  ;;
  -x)
    set -x
  ;;
  force)
    FORCE=true
  ;;
  no-clip)
    NOCLIP=true
  ;;
  *)
    SERVICE=$i
  esac
done
if [ ! -z "$ECHO" ]
then
  echoerr "--- arguments:"
  echoerr "        SERVICE=$SERVICE"
  echoerr "         SECRET=$SECRET"
  echoerr "           ECHO=$ECHO"
  echoerr "   OPTIONS_FILE=$OPTIONS_FILE"
  echoerr "LAST_TOKEN_FILE=$LAST_TOKEN_FILE"
fi

#propagate options file (if file is present and options not given in argument list)
if [ ! -z "$OPTIONS_FILE" ]
then
  if $LIST
  then
    if [ -z "$OPTIONS_FILE" ]
    then
      echoerr "ERROR: need options-file=..."
    else
      cat $OPTIONS_FILE | awk '/ / {print $1}'
      exit
    fi
  else
    while IFS='' read -r i || [[ -n "$i" ]]
    do
      case $i in
      debug|echo)
        ECHO=echoerr
      ;;
      service=*)
        [ -z "$SERVICE" ] && SERVICE="${i#service=}"
      ;;
      secret=*)
        [ -z "$SECRET" ] && SECRET="${i#secret=}"
      ;;
      last-token-file=*)
        [ -z "$LAST_TOKEN_FILE" ] && LAST_TOKEN_FILE="${i#last-token-file=}"
      ;;
      *)
        if [ ! -z "$SERVICE" ] && [[ ! "${i/$SERVICE}" == "$i" ]]
        then
          SECRET=$(echo $i | awk '/'$SERVICE'/ {print $2}')
        elif [[ "${i/ }" == "$i" ]]
        then
          echoerr "WARNING: Ignoring line from $OPTIONS_FILE: '$i'"
        fi
      ;;
      esac
    done < $OPTIONS_FILE
  fi
fi
if [ ! -z "$ECHO" ]
then
  echoerr "--- file:"
  echoerr "        SERVICE=$SERVICE"
  echoerr "         SECRET=$SECRET"
  echoerr "           ECHO=$ECHO"
  echoerr "   OPTIONS_FILE=$OPTIONS_FILE"
  echoerr "LAST_TOKEN_FILE=$LAST_TOKEN_FILE"
fi

#sanity and handling
if [ -z "$SECRET" ]
then
  echoerr "ERROR: need secret=<valid 32 character secret token>"
  exit 3
fi
if [ -z "$LAST_TOKEN_FILE" ]
then
  echoerr "ERROR: need last-token-file=<valid file>"
  exit 3
fi

#retrieve token
[ ! -z "$ECHO" ] && echoerr "authenticator --key $SECRET | grep Token | awk '{print $2}'"
TOKEN=$(authenticator --key $SECRET | grep Token | awk '{print $2}')
#try to get the last token
if [ -e "$LAST_TOKEN_FILE" ] && ! $FORCE
then
  LAST_TOKEN=$(cat "$LAST_TOKEN_FILE" )
  LAST_TOKEN_EPOCH=$(change_time "$LAST_TOKEN_FILE" )
else
  LAST_TOKEN="unknown"
  LAST_TOKEN_EPOCH=0
fi
#make sure token has changed
while [ ! "$LAST_TOKEN" == "unknown" ] &&  [ "$TOKEN" == "$LAST_TOKEN" ]
do
  sleep 1
  echoerr "last token ($LAST_TOKEN) as not yet changed, expecting new token in $(( 30 - $(now_time) + $LAST_TOKEN_EPOCH )) seconds)"
  TOKEN=$(authenticator --key $SECRET | grep Token | awk '{print $2}')
done
echo $TOKEN > $LAST_TOKEN_FILE

if $NOCLIP
then
  echo $TOKEN
else
  #copy it to the clipboard 
  if machine_is Darwin
  then
    echo $TOKEN | pbcopy
  elif machine is Ubuntu
  then
    if which xclip &> /dev/null
    then
      echo $TOKEN | xclip -selection clipboard
    else
      echoerr "Please run 'sudo apt-get install xclip'"
    fi
  else
    echoerr "The token is $TOKEN (cannot copy token to the clipboard, this OS is not supported: implementation needed)"
  fi
  echoerr "Copied to clipboard the token $TOKEN"
fi
  
