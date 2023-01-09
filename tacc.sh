#!/usr/bin/expect

set timeout -1
set prompt "$ "

set mode [lindex $argv 0]
send_user -- "mode: $mode\n"

set args [lrange $argv 0 end]
if {$mode=="sshfs"} {
  spawn /bin/bash -c "nohup $args"
} else {
  spawn {*}$args 
}
expect {
  Password: {
    interact "\r" return
    send -- "\r"
    exp_continue
  }
  "TACC Token Code:" {
    send_user -- " Calling ~/bin/token.sh ... "
    set token [exec ~/bin/token.sh tacc no-clip 2> /dev/null]
    send_user -- "Token is $token"
    send -- "$token\r"
    exp_continue
  }
  "Permission denied" {
    send_error -- "Auto-login failed..."
    exit 1
  }
  "$ " {
    if {$mode=="ssh"} {
      interact
    } else {
      exp_continue
    }
  }
}
