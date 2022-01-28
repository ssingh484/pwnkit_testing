PWNKIT Exploit Testing
======================

## Usage
* Clone this repository anywhere locally
* Using the docker command, build the image locally as such :
> `$ docker build -t pwnkit_testing .`
* Using the docker command, run the image via :
> `docker run -it pwnkit_testing`
> **Note:** The `-it` flag is needed to get the interactive shell as root which lets us verify we have escalated privilege
* Running a `whoami` command shows we are now root and no longer the lowpriv user that we started off as

## References

* Vulnerability discovered and disclosed by Qualys:
> [Qualys](https://www.qualys.com/2022/01/25/cve-2021-4034/pwnkit.txt)
* RedHat writeup on the vulnerability and a mitigation approach
> [RedHat](https://access.redhat.com/security/cve/CVE-2021-4034)
* Proof of Concept exploit by Davide Berardi, which provided the framework for this exploit
> [Davide Berardi](https://github.com/berdav/CVE-2021-4034)
* Article explaining privilege escalation via preload libraries, providing insight into why a vulnerability like this is important
> [R3d Buck3T](https://medium.com/r3d-buck3t/overwriting-preload-libraries-to-gain-root-linux-privesc-77c87b5f3bf8)

## Overview

pkexec is a program that is part of policykit which is essentially an application-level toolkit for allowing unprivileged processes to talk to privileged ones in order to let a user do certain tasks. This is similar to the `sudo` command often used to grant temporary privileges to a command. Both `sudo` and `pkexec` rely on the setuid bit for them being set, which makes these programs run as root and create a child process ( command supplied by user ) which can use the `setuid()` syscall to run as root. Usually this means that pkexec will ask for a password to authorize that the invoking user is allowed to run a command with elevated privileges.

However, in this vulnerability as described by the Qualys team, the pkexec program can be tricked into reading from and writing to environment variables instead of the command line arguments ( which is how a command would be given to pkexec to be run as root ). This allows carefully crafted input ( specifically input that makes the argc - number of command line arguments 0 ) to cause a loop as below in pkexec to set n as 1 :

` for (n = 1; n < (guint) argc; n++)
 {
 ...
 }
 `

But, due to the lack of any argument in the `argv[]` array at `argv[1]` , reading from this array index leads to an out of bounds read. Due to the way that arguments and environment variables are laid out contiguously in memory, reading out of bounds like this causes a read of the first environment variable instead of a command line argument.

After this, due to the code for pkexec, this `argv[n]` string ( where n has been set to 1 as described above ) is read in and treated as the path of the command supplied by the user. If this command doesn't begin with a `/` ( which would be an absolute path for a legitimate command given to pkexec like /usr/bin/ls ) then it is converted into an absolute path which is where the issue really begins. This converted absolute path is written back to `argv[n]` or the first environment variable before the rest of the program continues. This means that a carefully crafted input, with a specific environment variable supplied as the first environment variable, can cause pkexec to reintroduce an environment variable thanks to a specifically named directory and a specifically provided `PATH` environment variable.

This environment variable could easily be something like an `LD_PRELOAD` which can be set to the path of a shared object (.so file compiled from a .c file ) leading to that object being loaded before any other libraries. This can be an issue as the malicious shared object might override library functions with malicious code.

While pkexec does completely clear its environment prior to carrying on with the bulk of the rest of its functionality ( rendering any reintroduced enviornment variables worthless ), it does call a function to validate provided environment variables which is the `validate_environment_variable()` function. This function will error on a bad environment variable ( like a `SHELL` variable set to a non existent file ) and use the GLib or GNOME library function `g_printerr()` to log the error.

The GLib function g_printerr is affected by a `CHARSET` environment variable being set as that tells it to print using a different characterset than the default of UTF-8. The conversion from UTF-8 to whatever charset is provided is done by using the `GCONV_PATH` to read a config file telling it which shared libraries to use for the conversion. This **gconv-modules** file usually contains good shared libraries in the form of lines such as:

  `module  ISO-2022-JP//   EUC-JP//        ISO2022JP-EUCJP    1`
  `module  EUC-JP//        ISO-2022-JP//   ISO2022JP-EUCJP    1`
  
which are specifying how to convert from ISO-2022-JP charset to EUC-JP charset using the ISO2022JP-EUCJP.so module.

Here, we can use a malicious shared object (.so file compiled from a .c file ) and a reintroduced `GCONV_PATH` environment variable (pointing to a malicious gconv-modules file) to direct GLib's `g_printerr()` function to use the malicious shared object. This shared object has a `gconv_init` function that will be called to initialize a conversion function specific data structure or in a malicious case, execute the privilege escalation payload. This payload can use the same setuid() syscall that a child process of pkexec would have used, gaining root thanks to the setUID bit of pkexec being set and pkexec being owned by root, to gain root and run arbitrary code at that privilege. In the case of this demo, the malicious library spawns a shell as root.
