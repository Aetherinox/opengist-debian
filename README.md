<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/debian-opengist/88ceb55da2457ade600394a1922005efc4b36fc9/docs/images/banner.jpg" width="860"></p>
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

Install this Debian package as you would any other by downloading and executing it.
Once OpenGist is installed, the following files will be placed in the below structure:

```
📁 /etc/opengist/config.yml
📁 /lib/systemd/system/opengist.service
📁 /usr/bin/opengist
```

<br />

This deb will create a new system user named `opengist` which will run the service.

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
dpkg-deb --root-owner-group --build opengist-1.5.2_amd64
dpkg-deb --root-owner-group --build opengist-1.5.2_arm64
```

<br />

Run the linter

```shell
lintian opengist-1.5.2_amd64.deb --tag-display-limit 0
lintian opengist-1.5.2_arm64.deb --tag-display-limit 0
```

<br />

---

<br />

# Structure
This debian package uses the following structure:

<br />

## opengist_1.5.2_amd64
File structure / tree for `opengist_1.5.2_amd64`

```console ignore
.
├── opengist_1.5.2_amd64
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
└── opengist_1.5.2_amd64.deb

30 directories, 21 files
```

<br />

---

<br />

## opengist_1.5.2_arm64
File structure / tree for `opengist_1.5.2_arm64`

```console ignore
├── opengist_1.5.2_arm64
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
└── opengist_1.5.2_arm64.deb

30 directories, 21 files
```

<br />

---

<br />

# Previews

![Main](https://i.imgur.com/3u3DBUj.png)