#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/${USER}/bin"
echo

# #
#   This script relies on the fact that you already have the basic structure set up within the github repo.
#
#   The script will download the latest version of Opengist from the official website, but also use the files
#   within https://github.com/Aetherinox/opengist-debian to create the package.
#
#   - base files for opengist are stored in the /template/ folder.
#   - script will compare version specified by --current <version> and the latest version available through opengist.
#   - if --current <version> is lesser than the most current version of opengist; an update is found, the .tar.gz files will be downloaded.
#   - binary files from the downloaded .tar.gz will be extracted and moved over to /src/ folder.
#   - files from the /template/ folder will then be moved over to /src/ folder. one copy will be added for each arch available. (i386, x64, etc)
#   - numerous files will be opened and the latest version variable will be replaced with the actual latest version.
# #

# #
#   vars > colors
#
#   tput setab  [1-7]       : Set a background color using ANSI escape
#   tput setb   [1-7]       : Set a background color
#   tput setaf  [1-7]       : Set a foreground color using ANSI escape
#   tput setf   [1-7]       : Set a foreground color
# #

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
ORANGE=$(tput setaf 208)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 156)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
PINK=$(tput setaf 200)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)
STRIKE="\e[9m"
END="\e[0m"

# #
#   DEFINE > Default Arguments
# #

OPT_PACKAGE_NAME="opengist"
OPT_DEV_ENABLE="false"
OPT_FORCE="false"
OPT_PRECHECK="false"
OPT_SKIP_CHANGELOG="false"

# #
#   DEFINE > Globals
# #

GITHUB_NAME="Aetherinox"

# #
#   vars > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > app > folders
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# #
#   Ensure we're in the correct directory
# #

cd ${app_dir}

# #
#   vars > app > files
# #

app_file_this=$(basename "$0")

# #
#   DEFINE > App repo paths and commands
# #

app_title="Opengist Deb Creator"
app_about="A bash utility to create a .deb file from the currently released Opengist .tar.gz releases."
app_ver=("1" "0" "0" "0")
app_repo_branch="main"
app_repo_apt="opengist-debian"
app_repo_url="https://github.com/${GITHUB_NAME}/${app_repo_apt}"
app_repo_mnfst="https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_apt}/${app_repo_branch}/manifest.json"
app_repo_source="thomiceli/opengist"

# #
#   https://man7.org/linux/man-pages/man1/date.1.html
#
#   Mon, 03 Jun 2024 14:33:00 +0200
#
#   %a      locale's abbreviated weekday name (e.g., Sun)
#   %d      day of month (e.g., 01)
#   %b      locale's abbreviated month name (e.g., Jan)
#   %Y      year
#   %H      hour (00..23)
#   %M      minute (00..59)
#   %S      second (00..60)
# #

date_now=$(date -u '+%a, %d %b %Y %H:%M:%S')

# #
#   vars > changelog
# #

CHANGELOG=$(cat <<-END
    * New release

-- Thomas Miceli <thomiceli@github.com>  ${date_now} +0200
END
)

# #
#   Create .gitignore
# #

if [ ! -f "${app_dir}/.gitignore" ] || [ ! -s "${app_dir}/.gitignore" ]; then

    touch $app_dir/.gitignore

sudo tee $app_dir/.gitignore << EOF > /dev/null
# ----------------------------------------
#   Misc
# ----------------------------------------
*.deb
EOF

fi

# #
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
#
#   proteus-aptget.sh will house the path needed for the script to run
#   anywhere with an entry similar to:
#
#       export PATH="/home/$USER/bin:$PATH"
# #

envpath_add_lastversion()
{
    local file_env="/etc/profile.d/lastversion.sh"
    if [ "$2" = "force" ] || ! echo ${PATH} | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee ${file_env} > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee ${file_env} > /dev/null
        fi
    fi
}

# #
#   packages > git
# #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}Git${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1
fi

# #
#   packages > gpg
# #

if ! [ -x "$(command -v gpg)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}GPG${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install gpg -y -qq >/dev/null 2>&1
fi

# #
#   packages > lastversion
# #

if ! [ -x "$(command -v lastversion)" ]; then
    sudo apt-get update -y -q >> /dev/null 2>&1
    sudo apt-get install python3-pip python3-venv -y -qq >> /dev/null 2>&1
    sudo pip3 install --upgrade --force pip >> /dev/null 2>&1

    # wget https://github.com/dvershinin/lastversion/archive/refs/tags/v3.5.0.zip
    # mkdir ${HOME}/Packages/
    # unzip v3.5.0.zip -d ${HOME}/Packages/lastversion

    # #
    #   Uninstall with
    #       pip uninstall lastversion
    #
    #   note:   --break-system-packages is only available for pip
    #           23.1 and forward.
    #
    #           get version by using
    #               pip --version
    # #

    pip install lastversion --break-system-packages
    mkdir -p "${HOME}/bin"
    cp ${HOME}/.local/bin/lastversion ${HOME}/bin/
    sudo touch /etc/profile.d/lastversion.sh

    envpath_add_lastversion '${HOME}/bin'

    echo 'export PATH="${HOME}/bin:$PATH"' | sudo tee /etc/profile.d/lastversion.sh

    . ~/.bashrc
    . ~/.profile

    source ${HOME}/.profile # not executing for some reason
fi

# #
#   Display Usage Help
#
#   activate using ./proteus-git.sh --help or -h
# #

opt_usage()
{
    echo -e
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GREYL}${app_about}${NORMAL}\n" 1>&2
    echo -e
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}--skipChangelog${NORMAL}] [${GREYL}--precheck${NORMAL}] [${GREYL}--force${NORMAL}] [${GREYL}--current 1.7.3${NORMAL}] [${GREYL}--version${NORMAL}] [${GREYL}--help${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-n, --name" "sets package name" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "" "'${OPT_PACKAGE_NAME}' by default" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-p, --precheck" "check for update and return result. Does not actually update package." 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-a, --current" "specifies the current installed version of opengist" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "" "used in combination with Github Workflow 'github-action-get-previous-tag'" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-s, --skipChangelog" "build package but do not add anything into changelog" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-f, --force" "download and update Opengist no matter what version is installed" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "" "this will re-create every arch for Opengist and make a new .deb package for each" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-v, --version" "current version of this updater" 1>&2
    printf '  %-5s %-24s %-40s\n' "    " "-h, --help" "show this help menu" 1>&2
    echo -e
    echo -e
    exit 1
}

# #
#   command-line options
#
#   reminder that any functions which need executed must be defined BEFORE
#   this point. Bash sucks like that.
# #

while [ $# -gt 0 ]; do
  case "$1" in
    -n*|--name*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_PACKAGE_NAME="${1#*=}"
            if [ -z "${OPT_PACKAGE_NAME}" ]; then
                echo -e "  ${NORMAL}Must specify a valid name"
                echo -e "  ${NORMAL}      Default:  ${YELLOW}${OPT_PACKAGE_NAME}${NORMAL}"

                exit 1
            fi
            ;;

    -d|--dev)
            OPT_DEV_ENABLE="true"
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

    -f*|--force*)
            OPT_FORCE="true"
            ;;

    -p*|--precheck*)
            OPT_PRECHECK="true"
            ;;

    -s*|--skipChangelog*)
            OPT_SKIP_CHANGELOG="true"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -c*|--current*|--currentVer*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_VER_CURRENT="${1#*=}"
            if [ -z "${OPT_VER_CURRENT}" ]; then
                echo -e "  ${NORMAL}Must specify the current installed version"
                echo -e "      ${BOLD}${DEVGREY}./${app_file_this} --current 1.7.3${NORMAL}"
                exit 1
            fi
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${NORMAL} - v$(get_version)${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${app_repo_url}${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${OS} | ${OS_VER}${NORMAL}"
            echo
            exit 1
            ;;
    *)
            opt_usage
            ;;
  esac
  shift
done

# #
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
#
#   @usage      : get_version_compare_gt 2.5.7 2.5.6 && echo "yes" || echo "no" # no
# #

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

# #
#   get specified installed version
# #

PKG_VER_CURRENT=$( [[ -n "$OPT_VER_CURRENT" ]] && echo "$OPT_VER_CURRENT" || echo "false"  )

# #
#   if a --current version has been specified.
#   this will be matched against the latest released version.
#
#   if no --current version has been specified, script will exit
# #

if [ "${OPT_FORCE}" != "true" ] && ([ -z "${PKG_VER_CURRENT}" ] || [ "${PKG_VER_CURRENT}" == "false" ]); then

    echo -e
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Did not specify ${ORANGE}--current${WHITE} to compare with.${NORMAL}"
    echo -e "  ${BOLD}You must specify ${ORANGE}--current 1.X.X${WHITE} of Opengist you have installed.${NORMAL}"
    echo -e "  ${BOLD}This is usually done by the Github workflow when it checks for Opengist updates.${NORMAL}"
    echo -e
    echo -e "      ${BOLD}${DEVGREY}./${app_file_this} --current 1.7.3${NORMAL}"
    echo -e
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e

    rm *.tar.gz* >> /dev/null 2>&1

    exit 1
fi

# #
#   remove all .tar.gz files
# #

rm *.tar.gz* >> /dev/null 2>&1

# #
#   git > clone
# #

git clone "${app_repo_url}.git" >> /dev/null 2>&1
mv ${app_repo_apt}/{.,}* . >> /dev/null 2>&1
rm -rf ${app_repo_apt} >> /dev/null 2>&1

# #
#   list > architectures
# #

lst_arch=(
    'amd64'
    'arm64'
    '386'
)

        # #
        #   loop each architecture for each package
        #       amd64
        #       arm64
        #       386
        # #

        for j in "${!lst_arch[@]}"; do

            # #
            #   get architecture
            #       amd64, arm64, 386
            # #

            arch=${lst_arch[$j]}

            # #
            #   get lastversion URL of package
            # #

            PKG_URL=($( lastversion --pre --assets ${app_repo_source} --filter "(?:\b|_)(?:linux-${arch})\b.*\.tar.gz$" ) )

            # #
            #   download
            # #

            wget $PKG_URL >> /dev/null 2>&1

            # #
            #   Assign file names
            # #

            PKG_FOLDER=($( echo ${PKG_URL} | sed 's:.*/::' | sed 's/\.tar\.gz//g' ) )
            PKG_ARCHIVE=($( echo ${PKG_URL} | sed 's:.*/::' ) )
            PKG_VER=($( echo ${PKG_ARCHIVE} | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/' ) )

            echo -e "  ${WHITE}Download            ${GREEN}${PKG_URL}${NORMAL}"
            echo -e "  ${DEVGREY}Archive:            ${GREEN}${PKG_ARCHIVE}${NORMAL}"
            echo -e "  ${DEVGREY}Folder:             ${GREEN}${PKG_FOLDER}${NORMAL}"
            echo -e "  ${DEVGREY}Version:            ${GREEN}${PKG_VER}${NORMAL}"

            echo -e
            echo -e "  ${DEVGREY}OPT_FORCE:          ${GREEN}${OPT_FORCE}${NORMAL}"
            echo -e "  ${DEVGREY}OPT_PRECHECK:       ${GREEN}${OPT_PRECHECK}${NORMAL}"
            echo -e

            # #
            #   run version check if:    -f, --force    = FALSE
            #   run version check if:    -p, --precheck = TRUE
            # #

            if [ "${OPT_FORCE}" != "true" ] || [ "${OPT_PRECHECK}" == "true" ]; then

                echo -e "  ${DEVGREY}Prechecking for update ...${NORMAL}"

                # #
                #   Check for available update
                #
                #       returns TRUE if specified version is higher than current version
                #       returns FALSE if specified version is not higher than current version
                # #

                bUpdateAvailable=$(get_version_compare_gt "${PKG_VER}" "${PKG_VER_CURRENT}" && echo "true" || echo "false")

                if [[ "${bUpdateAvailable}" == "false" ]]; then
                    echo -e "  ${RED}An update was not found${NORMAL}"
                else
                    echo -e "  ${GREEN}An update was found${NORMAL}"
                fi

                # #
                #   Abort > Both versions are the same
                # #

                if [[ "${PKG_VER_CURRENT}" == "${PKG_VER}" ]]; then
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e
                    echo -e "  ${BOLD}${ORANGE}ABORTING  ${WHITE}Current version and built version are the same. No update found.${NORMAL}"
                    echo -e
                    echo -e "      ${YELLOW}CURRENT VERSION${WHITE} > ${YELLOW}${PKG_VER_CURRENT}${NORMAL}"
                    echo -e "      ${YELLOW}PACKAGE VERSION${WHITE} > ${YELLOW}${PKG_VER}${NORMAL}"
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e

                    if [ "${OPT_FORCE}" != "true" ]; then
                        rm *.tar.gz* >> /dev/null 2>&1
                        exit 1
                    fi
                fi

                # #
                #   Abort > Current version higher than specified version using argument
                #       '-a, --current, --currentVer 1.X.X'
                # #

                if [[ "${bUpdateAvailable}" == "false" ]]; then
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e
                    echo -e "  ${BOLD}${ORANGE}ABORTING  ${WHITE}Current version is higher than specified version. No update found.${NORMAL}"
                    echo -e
                    echo -e "      ${YELLOW}CURRENT VERSION${WHITE} > ${YELLOW}${PKG_VER_CURRENT}${NORMAL}"
                    echo -e "      ${YELLOW}PACKAGE VERSION${WHITE} > ${YELLOW}${PKG_VER}${NORMAL}"
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e

                    if [ "${OPT_FORCE}" != "true" ]; then
                        rm *.tar.gz* >> /dev/null 2>&1
                        exit 1
                    fi
                fi

                # #
                #   Precheck for update. Go no further after this point
                #       '-p, --precheck'
                #
                #   @example    : ./update.sh --available 1.7.1 --precheck
                # #

                if [[ "${bUpdateAvailable}" == "true" ]]; then
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e
                    echo -e "  ${BOLD}${GREEN}SUCCESS  ${WHITE}An update appears to be available.${NORMAL}"
                    echo -e "  ${BOLD}${WHITE}Run script again without ${GREEN}-p, --precheck${WHITE} to update.${NORMAL}"
                    echo -e
                    echo -e "      ${YELLOW}VERSION - CURRENT    ${WHITE} > ${YELLOW}${PKG_VER_CURRENT}${NORMAL}"
                    echo -e "      ${YELLOW}VERSION - LATEST     ${WHITE} > ${YELLOW}${PKG_VER}${NORMAL}"
                    echo -e
                    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
                    echo -e
                fi
            fi

            # #
            #   Create /build/opengist-* folders
            # #

            mkdir -p build/${OPT_PACKAGE_NAME}-${arch} | tar -xvzf ${PKG_ARCHIVE} -C build/${OPT_PACKAGE_NAME}-${arch} >> /dev/null 2>&1
            echo -e "  ${WHITE}Extract:                 ${GREEN}${PKG_ARCHIVE}${WHITE} > ${GREEN}build/${OPT_PACKAGE_NAME}-${arch}${NORMAL}"

            # #
            #   Delete the original .tar.gz files
            # #

            rm ${OPT_PACKAGE_NAME}*.tar.gz >> /dev/null 2>&1

            # #
            #   Create .deb structure folders
            #
            #   these should already be created within the github repo.
            # #

            mkdir -p src/$PKG_FOLDER/DEBIAN
            mkdir -p src/$PKG_FOLDER/etc/opengist
            mkdir -p src/$PKG_FOLDER/lib/systemd/system/
            mkdir -p src/$PKG_FOLDER/usr/bin/
            mkdir -p src/$PKG_FOLDER/usr/share/applications/
            mkdir -p src/$PKG_FOLDER/usr/share/doc/opengist/examples/
            mkdir -p src/$PKG_FOLDER/usr/share/icons/hicolor/
            mkdir -p src/$PKG_FOLDER/usr/share/lintian/overrides/
            mkdir -p src/$PKG_FOLDER/usr/share/man/man1/

            # #
            #   Copy > Template files from template/usr/share/ to src/$PKG_FOLDER/usr/share/
            #
            #   /usr/share/applications, docs, icons, lintian, man
            #
            #   the template files don't always have to be updated. After this copy process, the files will be updated later
            #   with the actual values needed for the release.
            # #

            cp -r template/usr/share/ src/$PKG_FOLDER/usr/ >> /dev/null 2>&1
            echo -e "  ${WHITE}Copy Template:           ${LIME_YELLOW}template/usr/share/ > ${GREEN}src/$PKG_FOLDER/usr/${NORMAL}"

            # #
            #   Create DEBIAN/conffile
            # #

tee src/$PKG_FOLDER/DEBIAN/conffiles << EOF > /dev/null
/etc/opengist/config.yml
EOF

            # #
            #   Create DEBIAN/control
            # #

tee src/$PKG_FOLDER/DEBIAN/control << EOF > /dev/null
Package: opengist
Version: ${PKG_VER}
Section: utils
Priority: optional
Architecture: ${arch}
Maintainer: Thomas Miceli <thomiceli@github.com>
Depends: adduser
Homepage: https://github.com/Aetherinox/opengist-debian
Description: Self-hosted pastebin powered by Git, open-source alternative to Github
 Gist. Opengist is a self-hosted pastebin powered by Git. All snippets are
 stored in a Git repository and can be read and/or modified using standard Git
 commands, or with the web interface. It is similar to GitHub Gist, but
 open-source and could be self-hosted.
EOF

            # #
            #   Create /DEBIAN/postinst
            # #

tee src/$PKG_FOLDER/DEBIAN/postinst << 'EOF' > /dev/null
#!/bin/sh
set -e

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Opengist .deb Package
#   @when   :           2024-08-02 02:14:53
#   @url    :           https://github.com/Aetherinox/opengist-debian
#
#   There are better ways to do some of this, but unfortunately since we're
#   not the developer, nor do we have the luxury of adding variables or
#   ways to seamlessly configure this, we will make do with what we have.
#
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   install desktop shortcut
##--------------------------------------------------------------------------

for user in /home/*
do
    username=${user##*/}
    path_desktop=${user}//Desktop

    if [ -d "$path_desktop" ]; then
        cp /usr/share/applications/opengist.desktop $path_desktop
        chgrp ${username} $path_desktop/opengist.desktop
        chown ${username} $path_desktop/opengist.desktop
        chmod 755 $path_desktop/opengist.desktop
        chmod a+x $path_desktop/opengist.desktop
    fi
done

##--------------------------------------------------------------------------
#   color chart
##--------------------------------------------------------------------------

ORANGE=$(tput setaf 208)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 156)
BLUE=$(tput setaf 033)
MAGENTA=$(tput setaf 5)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

##--------------------------------------------------------------------------
#   default vars
##--------------------------------------------------------------------------

OGIST_USER="opengist"
OGIST_HOME="/var/lib/opengist"
OGIST_SERV="/etc/systemd/system/opengist.service"
OGIST_CONF="/etc/opengist/config.yml"

if [ "$1" = "configure" ]; then
	#	add opengist user/group - will gracefully abort if the user already exists.
	#	homedir not created
	set +e
	adduser --system --home "${OGIST_HOME}" --no-create-home --group "${OGIST_USER}" 2>/dev/null
	set -e

	#	If the homedir does not already exist, create it with proper
	#	ownership and permissions.
	if [ ! -d "${OGIST_HOME}" ]; then
		mkdir -m 0750 -p "${OGIST_HOME}"
		chown "${OGIST_USER}:${OGIST_USER}" "${OGIST_HOME}"
	fi
fi

echo "Starting service"

if [ -d /run/systemd/system ]; then
	systemctl daemon-reload >/dev/null || true
	sleep 5

	if deb-systemd-invoke is-active opengist.service; then
		deb-systemd-invoke reload opengist.service
	else
		deb-systemd-helper enable opengist.service
		deb-systemd-invoke start opengist.service
	fi
fi

printf '\n%-35s\n\n' "  ${BOLD}${DEVGREY}OpenGist Installer${NORMAL}"
printf '%-35s\n' "  ${BOLD}${WHITE}Opengist has been installed. View the paths below to see where you can${NORMAL}"
printf '%-35s\n\n' "  ${BOLD}${WHITE}find certain files for configuring Opengist.${NORMAL}"
printf '%-38s %-40s\n' "  ${WHITE}Database Location${NORMAL}" "${BOLD}${YELLOW}${OGIST_HOME}${NORMAL}"
printf '%-38s %-40s\n' "  ${WHITE}Config Location${NORMAL}" "${BOLD}${YELLOW}${OGIST_CONF}${NORMAL}"
printf '%-38s %-40s\n\n' "  ${WHITE}Service Location${NORMAL}" "${BOLD}${YELLOW}${OGIST_SERV}${NORMAL}"
printf '%-35s\n' "  ${WHITE}The ${BOLD}${YELLOW}opengist.service${NORMAL} will be ran as user ${BOLD}${YELLOW}${OGIST_USER}${NORMAL}."
printf '%-35s\n\n\n' "  ${WHITE}To change the user, edit the service file and modify ${BOLD}${MAGENTA}USER=$OGIST_USER${NORMAL}"
EOF

            # #
            #   Copy opengist binary file
            #       build/ > src/
            # #

            cp build/${OPT_PACKAGE_NAME}-${arch}/opengist/opengist src/$PKG_FOLDER/usr/bin/opengist >> /dev/null 2>&1
            echo -e "  ${WHITE}Copy binary:             ${LIME_YELLOW}build/${OPT_PACKAGE_NAME}-${arch}/opengist/opengist > ${GREEN}src/$PKG_FOLDER/usr/bin/opengist${NORMAL}"

            # #
            #   Copy opengist config.yml
            # #

            cp build/${OPT_PACKAGE_NAME}-${arch}/opengist/config.yml src/$PKG_FOLDER/etc/opengist/config.yml >> /dev/null 2>&1
            echo -e "  ${WHITE}Copy config.yml:         ${LIME_YELLOW}build/${OPT_PACKAGE_NAME}-${arch}/opengist/config.yml > ${GREEN}src/$PKG_FOLDER/etc/opengist/config.yml${NORMAL}"

            cp build/${OPT_PACKAGE_NAME}-${arch}/opengist/config.yml src/$PKG_FOLDER/usr/share/doc/opengist/examples/config.yaml >> /dev/null 2>&1
            echo -e "  ${WHITE}Copy config.yml:         ${LIME_YELLOW}build/${OPT_PACKAGE_NAME}-${arch}/opengist/config.yml > ${GREEN}src/$PKG_FOLDER/usr/share/doc/opengist/examples/config.yaml${NORMAL}"

            # #
            #   open 'DEBIAN/control' and change version number
            # #

            sed -Ei "s/(Version:) .*/\1 ${PKG_VER}/" src/$PKG_FOLDER/DEBIAN/control >> /dev/null 2>&1
            echo -e "  ${WHITE}+w controls:             ${POWDER_BLUE}src/$PKG_FOLDER/DEBIAN/control${NORMAL}"

            # #
            #   open 'usr/share/applications/opengist.desktop' and change version number
            # #

            # sed -Ei "s/(Version=).*/\1${PKG_VER}/" src/$PKG_FOLDER/usr/share/applications/opengist.desktop >> /dev/null 2>&1
            # echo -e "  ${WHITE}+w opengist.desktop:     ${POWDER_BLUE}src/$PKG_FOLDER/usr/share/applications/opengist.desktop${NORMAL}"

            # #
            #   Create /usr/share/applications/opengist.desktop
            # #

            echo -e "  ${WHITE}+w opengist.desktop      ${POWDER_BLUE}src/$PKG_FOLDER/usr/share/applications/opengist.desktop${NORMAL}"

tee src/$PKG_FOLDER/usr/share/applications/opengist.desktop << EOF > /dev/null
[Desktop Entry]
Name=Opengist
GenericName=Opengist
Version=${PKG_VER}
Comment=Start Opengist server
Type=Application
Icon=opengist
Categories=Utility;
Exec=opengist --config "/etc/opengist/config.yml"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

            # #
            #   Create /usr/share/lintian/overrides/opengist
            # #

            echo -e "  ${WHITE}+w lintian overrides     ${POWDER_BLUE}src/$PKG_FOLDER/usr/share/lintian/overrides/opengist${NORMAL}"

tee src/$PKG_FOLDER/usr/share/lintian/overrides/opengist << 'EOF' > /dev/null
opengist: statically-linked-binary [usr/bin/opengist]
EOF

            # #
            #   Create /lib/systemd/system/opengist.service
            # #

            echo -e "  ${WHITE}+w service               ${POWDER_BLUE}src/$PKG_FOLDER/lib/systemd/system/opengist.service${NORMAL}"

tee src/$PKG_FOLDER/lib/systemd/system/opengist.service << 'EOF' > /dev/null
[Unit]
Description=Opengist - Host your own Gist
Documentation=man:opengist(1)
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=opengist
ExecStart=opengist --config=/etc/opengist/config.yml
Restart=on-failure
Restart=always
RestartSec=2s
TimeoutStopSec=20
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

[Install]
WantedBy=multi-user.target
EOF

            # #
            #   Skip changelog
            #
            #   do not edit changelog if -s, --skipChangelog
            #   do not edit changelog if -p, --precheck
            # #

            if [ "${OPT_SKIP_CHANGELOG}" == "false" ] && [ "${OPT_PRECHECK}" == "false" ]; then

                # #
                #   changelog
                # #

                    # #
                    #   changelog > decompress
                    #
                    #   this requires that you already have a file called changelog.gz which will be extracted.
                    # #

                    gunzip src/$PKG_FOLDER/usr/share/doc/opengist/changelog.gz >> /dev/null 2>&1
                    echo -e "  ${WHITE}Changelog > Unzip        ${GREEN}src/$PKG_FOLDER/usr/share/doc/opengist/changelog${NORMAL}"

                    # #
                    #   changelog > AMD64 > append to top of file
                    #       1i      : insert before line 1
                    #       .       : end inserting
                    #       wq      : save and quit
                    # #

ed src/$PKG_FOLDER/usr/share/doc/opengist/changelog << END_ED > /dev/null
1i
${OPT_PACKAGE_NAME} (${PKG_VER}) stable; urgency=low

${CHANGELOG}

.
wq
END_ED

                    echo -e "  ${WHITE}Changelog > Change       ${GREEN}src/$PKG_FOLDER/usr/share/doc/opengist/changelog${NORMAL}"

                    # #
                    #   changelog > compress
                    # #

                    gzip --best -n src/$PKG_FOLDER/usr/share/doc/opengist/changelog
                    echo -e "  ${WHITE}Changelog > Zip          ${GREEN}src/$PKG_FOLDER/usr/share/doc/opengist/changelog${NORMAL}"
            fi

            # #
            #   set permissions
            # #

            sudo chmod 0775 src/${PKG_FOLDER}/DEBIAN/postinst
            echo -e "  ${WHITE}CHMOD 0775:              ${YELLOW}src/${PKG_FOLDER}/DEBIAN/postinst${NORMAL}"

            # #
            #   create .deb package
            # #

            echo -e "  ${WHITE}Create .Deb:             ${YELLOW}src/${PKG_FOLDER}.deb${NORMAL}"
            dpkg-deb --root-owner-group --build src/${PKG_FOLDER}

            # #
            #   run lintian
            # #

            echo -e "  ${WHITE}Lintian:                 ${GREEN}${PKG_FOLDER}${NORMAL}"
            lintian src/${PKG_FOLDER}.deb --tag-display-limit 0 | grep executable-not-elf

            echo -e

            rm -rf "build" >> /dev/null 2>&1

            echo -e "  ${WHITE}Updating from ${PKG_VER_CURRENT} to ${GREEN}${PKG_VER}${NORMAL}"

            # #
            #   The last line but be just the version number, this is used in the Github workflow
            # #

            echo ${PKG_VER}
        done
