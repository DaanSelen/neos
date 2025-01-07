# How to escalate (securely) to a privileged user (root):

With the default minimal installation, there is a way to escalate to the root user using the following steps:

1. Right click on the taskbar (bottom bar) and select `panel` -> `logout`.
1. You are now at the login screen which usually is bypassed because of the autologin. Use the root password set in your configuration, the default minimal preseed sets the root password to: `Welkom01!`.
    > Once you log in with the root account, you might see a glitched desktop which is normal because the environment is made for the `user`-user.
1. Now you can right-click the desktop and select `Open Terminal Here` and you will have an elevated terminal.

This is only adviced when installation of a Remote Monitoring & Management (RMM) has failed and needs to manually be re-done.