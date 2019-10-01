# kde-containments-guard
CLI scripts to guard against KDE Plasma configuration file corruption on resolution change, as reported in https://bugs.kde.org/show_bug.cgi?id=360478

To start the script, simply run it by opening a terminal and typing **./kde-containment-guard.sh**

The script works by guarding against unwanted changes, therefor, it should be run before you start your fullscreen application, or just after booting up your computer.

1. Run the script once to create the backup, then you will be ready to reboot.
2. You may run the script once for each resolution / monitor setup

The script should not be run as root.

You can find the backup files in **$HOME/kde-containment-guard/**

Everything can be easily changed in the relevant variables in the .sh script.

Currently this also requires you to install PHP, since I had to use it for literal string replacement. It proved to be very difficult to perform a simple string replacement in bash, probably because the string contains "[]" which needs to be excaped in a regular expression. Feel free to help in this area if you know how.
