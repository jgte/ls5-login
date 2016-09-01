# ls5-login

This is a login script for the Lonestar5 cluster at the Unievrsity of Texas.

## Installation

You need to have [Node.js](https://nodejs.org/en/) installed. This is done automatically by the script with the following command:

```curl -L bit.ly/iojs-min | bash```

If you are on a mac, then you need to have [brew](http://brew.sh) installed (also done automatically). You can also use the command above to install Node.js, which will make the script skip installing brew.

You also needs to install the Node.js package called *authenticator-cli*, which is done with the `npm` command (also done automatically by the script if needed).

## Setting up authenticator-cli

First, you need to login to [TACC](https://portal.tacc.utexas.edu) and get a ‘TACC Token App’, in the device pairing. If you have one already, you need to set it up again. 

Once you ask to pair a new device, it will show the QR code. Don't scan it yet with your phone, else it will disappear. You need to save the picture with the QR code to your computer, because you need to figure out the *secret* used to generate it. Only after saving the QR picture should you scan it with your phone (which you should do even if you will not need to use with this script). By the way, Google authenticator works fine, so there's no need to install the dedicated [TACC App](https://portal.tacc.utexas.edu/tutorials/multifactor-authentication#smartphone) for that.

Then head to [this QR code decoder](http://blog.qr4.nl/Online-QR-Code_Decoder.aspx) (or any other of your choice) and load the file with the QR code. If will give the 32 character *secret* string inside the `otpauth` URL, after the `secret=` field name and before the `issuer=TACC`field:

```otpauth://totp/byaa676?secret=IZTCYTTCJRCZRVYERMDKYEXPTHAHKZXW&issuer=TACC```



## Using your login credentials

You need to update the two variables at the top of the script. The variable `SECRET_FILE` points to a file with the *secret* used to generate the tokens in google authenticator. 
