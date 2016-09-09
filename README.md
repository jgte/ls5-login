# ls5-login

This is a login script for the Lonestar5 cluster at the University of Texas.

## Installation

You need to have [Node.js](https://nodejs.org/en/) installed. This is done automatically by the script with the following command:

```curl -L bit.ly/iojs-min | bash```

If you are on a mac, then you need to have [brew](http://brew.sh) installed (also done automatically). You can use the command above to install Node.js, which will make the script skip installing brew.

You also needs to install the Node.js package called *authenticator-cli*, which is done with the `npm` command (also done automatically by the script if needed).

## Setting up authenticator-cli

First, you need to login to [TACC](https://portal.tacc.utexas.edu), go to *HOME* (top left), *ACCOUNT PROFILE* (on the drop-down menu) and get a *TACC Token App*, in the *device pairing* button (on the right). If you have one already, you need to set it up again.

Once you ask to pair a new device, it will show the QR code. Don't scan it yet with your phone, else it will disappear. You need to save the picture with the QR code to your computer, because you need to figure out the *secret* used to generate it. Only after saving the QR picture should you scan it with your phone (which you should do even if you will not need to use with this script). By the way, [Google authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2) works fine, so there's no need to install the dedicated [TACC App](https://portal.tacc.utexas.edu/tutorials/multifactor-authentication#smartphone) for that.

Then head to [this QR code decoder](http://blog.qr4.nl/Online-QR-Code_Decoder.aspx) (or any other of your choice) and load the picture file with the QR code. It will spit out the 32 character *secret* string inside the `otpauth` URL, after the `secret=` field name and before the `issuer=TACC` field, `IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW` in the following example:

`otpauth://totp/byaa676?secret=IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW&issuer=TACC`

Finally, copy and paste the *secret* string into an empty file.

## TEsting ig the authenticator-cli is working

You can test if `authenticator-cli` is giving you the correct token by comparing what your phone says with the output of the following command:

`authenticator --key IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW`

I suggest you confirm that is the case before proceeding.

## Setting your login credentials

You need to update the two variables at the top of the script. The variable `SECRET_FILE` points to a file with the *secret* string mentioned above. The variable `USER_NOW` defines your user-name in Lonestar5.

## Logging in

Simply call the `ls5.sh` script, give your password and wait for a few seconds.

## Advanced options

The following optional input arguments are supported:

- `debug` or `echo` to show the commands that would be issued (without actually doing anything);
- `csr` to login to `login3.ls5.tacc.utexas.edu` instead of `ls5.tacc.utexas.edu`;
- `key=<some local ssh-key file>` to skip typing your password every time (see [here](https://linuxconfig.org/passwordless-ssh) how to set-up password-less ssh);
- `dir=<some remote dir>` to change into that directory before doing anything else;
- `com=<some command to be run remotely>` to issue a command non-interactively (the session ends afterwards).

Important notes:

- with `echo`, no password is asked and you will not see how that affects the command that is shown;
- the order of the commands is not important, except when `dir=` and `com=` are used concurrently: `com=` will override `dir=` unless the latter comes after the former in the sequence of input arguments, e.g.:

<pre>
ls5.sh csr <b>com='ls -la' dir=bin</b> echo
</pre>

produces:

<pre>
Logging in (please wait, this takes a couple of seconds):
expect -c
spawn ssh -l username -Y -t login3.ls5.tacc.utexas.edu <b>"cd bin; ls -la"</b>

expect "TACC Token: "
sleep 0.1
send "695941\r"
interact
</pre>

while

<pre>
ls5.sh csr <b>dir=bin com='ls -la'</b> echo
</pre>

produces:

<pre>
Logging in (please wait, this takes a couple of seconds):
expect -c
spawn ssh -l username -Y -t login3.ls5.tacc.utexas.edu <b>"ls -la"</b>

expect "TACC Token: "
sleep 0.1
send "044298\r"
interact
</pre>

- the input `com=` forces a non-interactive session, while the input `dir=` does not:

<pre>
ls5.sh csr <b>com='cd bin'</b> echo
</pre>

produces (the pretty useless exercise of changing directory to `bin` and logging out immediately):

<pre>
Logging in (please wait, this takes a couple of seconds):
expect -c
spawn ssh -l username  -Y -t login3.ls5.tacc.utexas.edu <b>"cd bin"</b>

expect "TACC Token: "
sleep 0.1
send "309761\r"
interact
</pre>

while

<pre>
ls5.sh csr <b>dir=bin</b> echo
</pre>

produces:

<pre>
Logging in (please wait, this takes a couple of seconds):
expect -c
spawn ssh -l username  -Y -t login3.ls5.tacc.utexas.edu <b>"cd bin; exec /bin/bash -l"</b>

expect "TACC Token: "
sleep 0.1
send "041694\r"
interact
</pre>



