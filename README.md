# ls5-login
Login script for Lonestar5

## Installation

You need to have [Node.js](https://nodejs.org/en/) installed. This is done automatically by the script with the following command:

  curl -L bit.ly/iojs-min | bash

If you are on a mac, then you need to have [brew](http://brew.sh) installed (also done automatically). You can also use the command above to install Node.js, which will make the script skip installing brew.

You also needs to install the Node.js package called 'authenticator-cli’, which is done with the ‘npm’ command (also done automatically by the script if needed).

You need to update the two variables at the top of the script. The variable SECRET_FILE points to a file with the ‘secret’ used to generate the tokens in google authenticator. 


First, you need to login to TACC and get a ‘TACC Token App’, in the device pairing. If you have one already, you need to set it up again. It will show the QR code, and you need to save the picture with the QR code to your computer. Then

http://blog.qr4.nl/Online-QR-Code_Decoder.aspx 
