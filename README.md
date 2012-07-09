# FreshBing

FreshBing is a simple, unobtrusive script to update your wallpaper daily, from
the Bing Desktop images RSS feed. It includes a lightweight installer, and works
well with Windows XP and above, unlike the official Bing Desktop software, which
only works with Windows 7.

## Usage

Install the script using [the setup
program](https://github.com/downloads/ndabas/FreshBing/FreshBingSetup.exe). You
do not need administrative privileges to install it. FreshBing requires that you
have Windows PowerShell installed on your computer.

The script will run daily to update the wallpaper, or in the case of Windows XP,
on startup (every time you log on.)

You can also manually force an update to the next available wallpaper, by
clicking the FreshBing icon in your Start Menu.

The script can also be executed from a command line, like this:

    powershell -ExecutionPolicy unrestricted -File FreshBing.ps1

## How it works

The script is a simple PowerShell script that downloads the Bing Desktop RSS
feed, and then saves the newest image not already downloaded to your My Pictures
folder. It then proceeds to set that image as your current wallpaper.

It is set up as a scheduled task on Windows Vista and above, and runs on startup
for Windows XP. On Windows XP, It will also automatically convert the downloaded
JPEG files to BMP format before setting those as wallpaper.

Finally, it will automatically delete any previously downloaded file when it
downloads a new one, so it keeps only one file at a time.

## Uninstall

You can uninstall the script from the Control Panel, using the standard Windows
Add/Remove Programs or Programs and Features applet.

## License

Licensed under the Apache Licence, version 2.0.

## Credits

Created by [Nikhil Dabas](http://www.nikhildabas.com/).

Microsoft, Windows, Bing, and other Microsoft products and services may be
either trademarks or registered trademarks of Microsoft in the United States
and/or other countries.
