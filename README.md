<div align="center">
<h6>.deb package for Opengist</h6>
<h1>♾️ Opengist ♾️</h1>

<br />

<p>

Self-hosted gist software within a .deb package; available for install using `apt-get install`

</p>

<br />

<img src="https://raw.githubusercontent.com/Aetherinox/opengist-debian/main/Docs/images/banner.jpg" width="850">

<br />
<br />

</div>

<div align="center">

<!-- prettier-ignore-start -->
[![Version][github-version-img]][github-version-uri]
[![Build Status][github-build-img]][github-build-uri]
[![Downloads][github-downloads-img]][github-downloads-uri]
[![Size][github-size-img]][github-size-img]
[![Last Commit][github-commit-img]][github-commit-img]
[![Contributors][contribs-all-img]](#contributors-)
<!-- prettier-ignore-end -->

</div>

<br />

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

<br />

To install Opengist, you have two options -- pick only one:
1. [Proteus Apt Repo](#proteus-apt-repo)
2. [Manual](#manual)

<br />

> [!NOTE]
> After instaling this package; the following files will be placed in the below structure:
> 
> ```
> 📁 /etc/opengist/config.yml
> 📁 /lib/systemd/system/opengist.service
> 📁 /usr/bin/opengist
> ```
> 
> This .deb will create a new system user named `opengist` which will run the opengist service.

<br />

## Proteus Apt Repo
The Proteus Apt Repo is a special Ubuntu / Debian / CentOS repository hosted by this developer on Github. You can install this Opengist package using `apt-get install` by adding the proteus apt repo to your sources list.

<br />

Open `Terminal`, add the GPG key to your keyring
```bash
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-archive.gpg
```

<br />

Fetch the repo package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-archive.list
```

<br />

(Optional): You can test if the correct GPG key was added:
```shell
gpg -n -q --import --import-options import-show /usr/share/keyrings/aetherinox-proteus-archive.gpg | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "BCA07641EE3FCD7BC5585281488D518ABD3DC629") print "\nGPG fingerprint matches ("$0").\n"; else print "\GPG verification failed: Fngerprint ("$0") does not match the expected one.\n"}'
```

<br />

After completing the above; update your packages:
```shell
sudo apt update
```

<br />

You can now install the Opengist package with:
```shell ignore
sudo apt install opengist
```

<br />

## Manual

Download the latest `.deb` package from this repo's [Releases](https://github.com/Aetherinox/opengist-debian/releases) page. Once downloaded, install it using:

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
gitea.name:
oidc.client-key:
oidc.secret:
oidc.discovery-url:
custom.logo:
custom.favicon:
custom.static-links:
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

To build the debian package, run the following commands within this repo's `src/` folder:

```shell
dpkg-deb --root-owner-group --build opengist1.7.3-linux-amd64
dpkg-deb --root-owner-group --build opengist1.7.3-linux-arm64
dpkg-deb --root-owner-group --build opengist1.7.3-linux-386
```

<br />

Run the linter

```shell
lintian opengist1.7.3-linux-amd64.deb --tag-display-limit 0 | grep executable-not-elf
lintian opengist1.7.3-linux-arm64.deb --tag-display-limit 0 | grep executable-not-elf
lintian opengist1.7.3-linux-386.deb  --tag-display-limit 0 | grep executable-not-elf
```

<br />

---

<br />

# Structure

This debian package uses the following structure:

<br />

<details>
  <summary>opengist1.7.3-linux-amd64</summary>

<br />

File structure / tree for `opengist1.7.3-linux-amd64.deb`

```shell ignore
.
├── opengist1.7.3-linux-amd64
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
└── opengist1.7.3-linux-amd64.deb

30 directories, 21 files
```
</details>

<br />

<details>
  <summary>opengist1.7.3-linux-arm64</summary>

<br />

File structure / tree for `opengist1.7.3-linux-arm64.deb`

```shell ignore
.
├── opengist1.7.3-linux-arm64
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
└── opengist1.7.3-linux-arm64.deb

30 directories, 21 files
```
</details>

<br />

<details>
  <summary>opengist1.7.3-linux-386</summary>

<br />

File structure / tree for `opengist1.7.3-linux-386.deb`

```shell ignore
.
├── opengist1.7.3-linux-386
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
└── opengist1.7.3-linux-386.deb

30 directories, 21 files
```
</details>

<br />

---

<br />

# Previews

<p align="center"><img style="width: 85%;text-align: center;border: 1px solid #353535;" src="https://raw.githubusercontent.com/Aetherinox/opengist-debian/main/Docs/images/1.png"></p>

<br />

---

<br />

## Contributors ✨
We are always looking for contributors. If you feel that you can provide something useful to Gistr, then we'd love to review your suggestion. Before submitting your contribution, please review the following resources:

- [Pull Request Procedure](.github/PULL_REQUEST_TEMPLATE.md)
- [Contributor Policy](CONTRIBUTING.md)

<br />

Want to help but can't write code?
- Review [active questions by our community](https://github.com/Aetherinox/opengist-debian/labels/help%20wanted) and answer the ones you know.

<br />

The following people have helped get this project going:

<br />

<div align="center">

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![Contributors][contribs-all-img]](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top"><a href="https://gitlab.com/Aetherinox"><img src="https://avatars.githubusercontent.com/u/118329232?v=4?s=40" width="80px;" alt="Aetherinox"/><br /><sub><b>Aetherinox</b></sub></a><br /><a href="https://github.com/Aetherinox/opengist-debian/commits?author=Aetherinox" title="Code">💻</a> <a href="#projectManagement-Aetherinox" title="Project Management">📆</a> <a href="#fundingFinding-Aetherinox" title="Funding Finding">🔍</a></td>
    </tr>
  </tbody>
</table>
</div>
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

<br />
<br />

<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- BADGE > GENERAL -->
  [general-npmjs-uri]: https://npmjs.com
  [general-nodejs-uri]: https://nodejs.org
  [general-npmtrends-uri]: http://npmtrends.com/obsidian-gistr

<!-- BADGE > VERSION > GITHUB -->
  [github-version-img]: https://img.shields.io/github/v/tag/Aetherinox/opengist-debian?logo=GitHub&label=Version&color=ba5225
  [github-version-uri]: https://github.com/Aetherinox/opengist-debian/releases

<!-- BADGE > VERSION > NPMJS -->
  [npm-version-img]: https://img.shields.io/npm/v/obsidian-gistr?logo=npm&label=Version&color=ba5225
  [npm-version-uri]: https://npmjs.com/package/obsidian-gistr

<!-- BADGE > VERSION > PYPI -->
  [pypi-version-img]: https://img.shields.io/pypi/v/obsidian-gistr-plugin
  [pypi-version-uri]: https://pypi.org/project/obsidian-gistr-plugin/

<!-- BADGE > LICENSE > MIT -->
  [license-mit-img]: https://img.shields.io/badge/MIT-FFF?logo=creativecommons&logoColor=FFFFFF&label=License&color=9d29a0
  [license-mit-uri]: https://github.com/Aetherinox/opengist-debian/blob/main/LICENSE

<!-- BADGE > GITHUB > DOWNLOAD COUNT -->
  [github-downloads-img]: https://img.shields.io/github/downloads/Aetherinox/opengist-debian/total?logo=github&logoColor=FFFFFF&label=Downloads&color=376892
  [github-downloads-uri]: https://github.com/Aetherinox/opengist-debian/releases

<!-- BADGE > NPMJS > DOWNLOAD COUNT -->
  [npmjs-downloads-img]: https://img.shields.io/npm/dw/%40aetherinox%2Fmkdocs-link-embeds?logo=npm&&label=Downloads&color=376892
  [npmjs-downloads-uri]: https://npmjs.com/package/obsidian-gistr

<!-- BADGE > GITHUB > DOWNLOAD SIZE -->
  [github-size-img]: https://img.shields.io/github/repo-size/Aetherinox/opengist-debian?logo=github&label=Size&color=59702a
  [github-size-uri]: https://github.com/Aetherinox/opengist-debian/releases

<!-- BADGE > NPMJS > DOWNLOAD SIZE -->
  [npmjs-size-img]: https://img.shields.io/npm/unpacked-size/obsidian-gistr/latest?logo=npm&label=Size&color=59702a
  [npmjs-size-uri]: https://npmjs.com/package/obsidian-gistr

<!-- BADGE > CODECOV > COVERAGE -->
  [codecov-coverage-img]: https://img.shields.io/codecov/c/github/Aetherinox/opengist-debian?token=MPAVASGIOG&logo=codecov&logoColor=FFFFFF&label=Coverage&color=354b9e
  [codecov-coverage-uri]: https://codecov.io/github/Aetherinox/opengist-debian

<!-- BADGE > ALL CONTRIBUTORS -->
  [contribs-all-img]: https://img.shields.io/github/all-contributors/Aetherinox/opengist-debian?logo=contributorcovenant&color=de1f6f&label=contributors
  [contribs-all-uri]: https://github.com/all-contributors/all-contributors

<!-- BADGE > GITHUB > BUILD > NPM -->
  [github-build-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/opengist-debian/deb_build.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-uri]: https://github.com/Aetherinox/opengist-debian/actions/workflows/deb_build.yml

<!-- BADGE > GITHUB > BUILD > Pypi -->
  [github-build-pypi-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/opengist-debian/release-pypi.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-pypi-uri]: https://github.com/Aetherinox/opengist-debian/actions/workflows/pypi-release.yml

<!-- BADGE > GITHUB > TESTS -->
  [github-tests-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/opengist-debian/npm-tests.yml?logo=github&label=Tests&color=2c6488
  [github-tests-uri]: https://github.com/Aetherinox/opengist-debian/actions/workflows/npm-tests.yml

<!-- BADGE > GITHUB > COMMIT -->
  [github-commit-img]: https://img.shields.io/github/last-commit/Aetherinox/opengist-debian?logo=conventionalcommits&logoColor=FFFFFF&label=Last%20Commit&color=313131
  [github-commit-uri]: https://github.com/Aetherinox/opengist-debian/commits/main/

<!-- prettier-ignore-end -->
<!-- markdownlint-restore -->
