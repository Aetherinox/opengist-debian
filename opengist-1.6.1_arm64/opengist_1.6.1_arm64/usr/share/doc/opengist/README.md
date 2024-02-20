# OpenGist

Opengist is a self-hosted pastebin powered by Git. All snippets are stored in a Git repository and can be read and/or modified using standard Git commands, or with the web interface. It is similar to GitHub Gist, but open-source and could be self-hosted.

[View the official Github docs here.](https://github.com/thomiceli/opengist/blob/master/docs/index.md)

<br />

---

<br />

## Usage
Once you have installed the `.deb` page, the following files will be placed on your system:
- /etc/opengist/config.yml
- /usr/bin/opengist

<br />

To launch Opengist, run the binary and specify the path to your config file:
```shell
opengist --config /etc/opengist/config.yml
```

<br />

Once opengist has been launched, you can open your browser and access
- http://localhost:6157
