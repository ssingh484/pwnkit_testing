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

TODO

