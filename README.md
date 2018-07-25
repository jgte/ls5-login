# ls5-login

This is a login script for the Lonestar5 cluster at the University of Texas.

## Installation

You need to have [Node.js](https://nodejs.org/en/) installed. This is done automatically by the script with the following command:

```curl -L bit.ly/iojs-min | bash```

If you are on a mac, then you need to have [*brew*](http://brew.sh) installed (also done automatically). You can use the command above to install Node.js, which will make the script skip installing *brew*.

You also needs to install the Node.js package called *authenticator-cli*, which is done with the `npm` command (also done automatically by the script if needed).

## Setting up authenticator-cli

First, you need to login to [TACC](https://portal.tacc.utexas.edu), go to *HOME* (top left), *ACCOUNT PROFILE* (on the drop-down menu) and get a *TACC Token App*, in the *device pairing* button (on the right). If you have one already, you need to set it up again.

Once you ask to pair a new device, it will show the QR code. Don't scan it yet with your phone, else it will disappear. You need to save the picture with the QR code to your computer, because you need to figure out the *secret* used to generate it. Only after saving the QR picture should you scan it with your phone (which you should do even if you will not need to use with this script and also makes it possible for you to confirm *authenticator-cli* is working as expected). By the way, [Google authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2) works fine, so there's no need to install the dedicated [TACC App](https://portal.tacc.utexas.edu/tutorials/multifactor-authentication#smartphone) for that.

Then head to [this QR code decoder](https://zxing.org/w/decode.jspx) (or any other of your choice) and load the picture file with the QR code. It will spit out the 32 character *secret* string inside the `otpauth` URL, after the `secret=` field name and before the `issuer=TACC` field, `IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW` in the following example:

`otpauth://totp/byaa676?secret=IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW&issuer=TACC`

Finally, save the *secret* for later.

## Testing if the authenticator-cli is working

You can test if `authenticator-cli` is giving you the correct token by comparing what your phone says with the output of the following command:

`authenticator --key IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW`

I suggest you confirm that is the case before proceeding.

## Setting your login credentials

There are three ways to set your login credentials:

- Add them to the `USERNAME_DEFAULT` and `SECRET_DEFAULT` variables, towards the top of the script;

- Create a file (the default is `$HOME/.ssh/ls5.sh.options`, or any other defined with the `options-file=` argument) with `username=<something>` and `secret=<something>` in individual lines;

- Explicitly call the `ls5.sh` script with the arguments `username=<something>` and `secret=<something>` (this is not advisable since the *secret* string is exposed to `ps`).

## Logging in

Simply call the `ls5.sh` script (considering one of the three options of setting your login credentials explained above), give your password and wait for a few seconds.

## Advanced options

The following optional input arguments are supported:

- `username=<something>` defines the username in the remote system (defaults to `$USER`)
- `secret=<valid 32 character secret token>` defines the secret token (no default)
- `ls5-address=<address of Lonestar5>` to specify a different address to Lonestar5 (defaults to `ls5.tacc.utexas.edu`);
- `ssh-key=<some local ssh-key file>` to skip typing your password every time (no default); see [here](https://linuxconfig.org/passwordless-ssh) how to set-up password-less ssh), making this script completely non-interactive (which is specially useful in conjunction with the `remote-com=` argument
- `remote-dir=<some remote dir>` to change into that directory before doing anything else (no default)
- `remote-com=<some command to be run remotely>` to issue a command non-interactively (default `exec $SHELL -l`, don't forget `exit` if you want the session to end)
- `debug` or `echo` shows the commands that would be issued (without actually doing anything)
- `options-file=<some file with the options above, one in each line>` to store often-used options, such as `username=` and `secret=` (default is `$HOME/.ssh/ls5.sh.options`)
- `last-token-file=<some file>` defines the file where the last token is stored, so that no token is re-used in successive login attempts (defaults to `$HOME/.last-token`)
- `sshfs=<some local empty dir>` instead of an interactive login shell mount the remote machine using sshfs, needs [OSX Fuse](https://osxfuse.github.io) or any other sshfs implementation, which usually available in most Linux/Unix distros (no default)
- `token` retrieves the token, copying it to the clipboard (no other operations are done)

## Important notes

- with `echo`, no password is asked and you will not see how that affects the command that is shown;
- the order of the commands is not important;
- all input arguments described above can be written to a plain text file (default is `$HOME/.ssh/ls5.sh.options`), one option per line;
- the arguments `username=` and `secret=` must be defined in one of the ways explained in [Setting your login credentials](#setting-your-login-credentials).





