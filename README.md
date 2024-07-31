<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/debian-opengist/main/Docs/images/banner.jpg" width="860"></p>
<h1 align="center"><b>Opengist (Debian Package)</b></h1>

<div align="center">

![Version](https://img.shields.io/github/v/tag/Aetherinox/debian-opengist?logo=GitHub&label=version&color=ba5225) ![Downloads](https://img.shields.io/github/downloads/Aetherinox/debian-opengist/total) ![Repo Size](https://img.shields.io/github/repo-size/Aetherinox/debian-opengist?label=size&color=59702a) ![Last Commit)](https://img.shields.io/github/last-commit/Aetherinox/debian-opengist?color=b43bcc)

</div>

---

<br />

# About
Opengist is a self-hosted pastebin powered by Git. All snippets are stored in a Git repository and can be read and/or modified using standard Git commands, or with the web interface. It is similiar to GitHub Gist, but open-source and could be self-hosted.

<br />

<div align="center">

[![View](https://img.shields.io/badge/%20-%20View%20OpenGist%20Repo-%20%23de2343?style=for-the-badge&logo=github&logoColor=FFFFFF)](https://github.com/thomiceli/opengist)

</div>

<br />

---

<br />

# Install

After instaling this package; the following files will be placed in the below structure:

```
📁 /etc/opengist/config.yml
📁 /lib/systemd/system/opengist.service
📁 /usr/bin/opengist
```

<br />

This .deb will create a new system user named `opengist` which will run the opengist service.

<br />

To install Opengist, you have two options -- pick only one:
1. [Proteus Apt Repo](#proteus-apt-repo)
2. [Manually](#manually)

<br />

## Proteus Apt Repo
The Proteus Apt Repo is a special Ubuntu / Debian / CentOS repository hosted by this developer on Github. You can install this Opengist package using `apt-get install` by adding the proteus apt repo to your sources list.

<br />


Open `Terminal` and add the GPG key to your keyring
```bash
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-archive.gpg
```

<br />

Fetch the repo package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-archive.list
```

<br />

(Optional): To test if the correct GPG key was added:
```shell
gpg -n -q --import --import-options import-show /usr/share/keyrings/aetherinox-proteus-archive.gpg | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "BCA07641EE3FCD7BC5585281488D518ABD3DC629") print "\nGPG fingerprint matches ("$0").\n"; else print "\GPG verification failed: Fngerprint ("$0") does not match the expected one.\n"}'
```

<br />

Finally, run in terminal
```shell
sudo apt update
```

<br />

Once the above steps are complete, you can install the Opengist package by executing:
```shell ignore
sudo apt install opengist
```


<br />

## Manually

Download the latest `.deb` package from this repo's [Releases](/releases) page. Once you have downloaded the `.deb` file, install it using:

```shell ignore
sudo dpkg -i opengist_1.7.3_amd64.deb
```

<br />

---

<br />

# Config
You may edit the Opengist config file by opening `/etc/opengist/config.yml`

```yml
log-level: warn
external-url:
opengist-home:
db-filename: opengist.db
sqlite.journal-mode: WAL
http.host: 0.0.0.0
http.port: 6157
http.git-enabled: true
ssh.git-enabled: true
ssh.host: 0.0.0.0
ssh.port: 2222
ssh.external-domain:
ssh.keygen-executable: ssh-keygen
github.client-key:
github.secret:
gitea.client-key:
gitea.secret:
gitea.url: https://gitea.com/
oidc.client-key:
oidc.secret:
oidc.discovery-url:
```

<br />

---

<br />

# Start / Manage Service
To start/stop opengist, execute the following:

```bash
sudo systemctl start opengist
sudo systemctl stop opengist
sudo systemctl status opengist
```

<br />

The system service will activate the binary in `/usr/bin/opengist`

<br />

---

<br />

# Build

To build the debian package

```shell
dpkg-deb --root-owner-group --build opengist-1.7.3_amd64
dpkg-deb --root-owner-group --build opengist-1.7.3_arm64
```

<br />

Run the linter

```shell
lintian opengist_1.7.3_amd64.deb --tag-display-limit 0 | grep executable-not-elf
lintian opengist_1.7.3_arm64.deb --tag-display-limit 0 | grep executable-not-elf
```

<br />

---

<br />

# Structure
This debian package uses the following structure:

<br />

## opengist_1.7.3_amd64
File structure / tree for `opengist_1.7.3_amd64`

```console ignore
.
├── opengist_1.7.3_amd64
│   ├── DEBIAN
│   │   ├── conffiles
│   │   ├── control
│   │   └── postinst
│   ├── etc
│   │   └── opengist
│   │       └── config.yml
│   ├── lib
│   │   └── systemd
│   │       └── system
│   │           └── opengist.service
│   └── usr
│       ├── bin
│       │   └── opengist
│       └── share
│           ├── applications
│           │   └── opengist.desktop
│           ├── doc
│           │   └── opengist
│           │       ├── AUTHORS
│           │       ├── changelog.gz
│           │       ├── copyright
│           │       ├── examples
│           │       │   └── config.yaml
│           │       ├── README
│           │       └── README.md
│           ├── icons
│           │   └── hicolor
│           │       ├── 128x128
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 16x16
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 256x256
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 32x32
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       └── 64x64
│           │           └── apps
│           │               └── opengist.png
│           ├── lintian
│           │   └── overrides
│           │       └── opengist
│           └── man
│               └── man1
│                   └── opengist.1.gz
└── opengist_1.7.3_amd64.deb

30 directories, 21 files
```

<br />

---

<br />

## opengist_1.7.3_arm64
File structure / tree for `opengist_1.7.3_arm64`

```console ignore
├── opengist_1.7.3_arm64
│   ├── DEBIAN
│   │   ├── conffiles
│   │   ├── control
│   │   └── postinst
│   ├── etc
│   │   └── opengist
│   │       └── config.yml
│   ├── lib
│   │   └── systemd
│   │       └── system
│   │           └── opengist.service
│   └── usr
│       ├── bin
│       │   └── opengist
│       └── share
│           ├── applications
│           │   └── opengist.desktop
│           ├── doc
│           │   └── opengist
│           │       ├── AUTHORS
│           │       ├── changelog.gz
│           │       ├── copyright
│           │       ├── examples
│           │       │   └── config.yaml
│           │       ├── README
│           │       └── README.md
│           ├── icons
│           │   └── hicolor
│           │       ├── 128x128
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 16x16
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 256x256
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       ├── 32x32
│           │       │   └── apps
│           │       │       └── opengist.png
│           │       └── 64x64
│           │           └── apps
│           │               └── opengist.png
│           ├── lintian
│           │   └── overrides
│           │       └── opengist
│           └── man
│               └── man1
│                   └── opengist.1.gz
└── opengist_1.7.3_arm64.deb

30 directories, 21 files
```

<br />

---

<br />

# Previews

<p align="center"><img style="width: 85%;text-align: center;border: 1px solid #353535;" src="https://raw.githubusercontent.com/Aetherinox/debian-opengist/main/Docs/images/1.png"></p>