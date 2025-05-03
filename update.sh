#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/${USER}/bin"
echo

# #
#   @author             aetherinox
#   @script             Opengist Debian Updater
#   @date               2025-05-01 00:00:00
#   @url                https://github.com/Aetherinox/opengist-debian
#
#   This script relies on the fact that you already have the basic structure set up within the github repo.
#
#   The script will download the latest version of Opengist from the official website, but also use the files
#   within https://github.com/Aetherinox/opengist-debian to create the package.
#
#   total process involves:
#       - base files for opengist are stored in the /template/ folder.
#       - script will compare version specified by --current <version> and the latest version available through opengist.
#       - if --current <version> is lesser than the most current version of opengist; an update is found, the .tar.gz files will be downloaded.
#       - binary files from the downloaded .tar.gz will be extracted and moved over to /src/ folder.
#       - files from the /template/ folder will then be moved over to /src/ folder. one copy will be added for each arch available. (i386, x64, etc)
#       - numerous files will be opened and the latest version variable will be replaced with the actual latest version.
# #

# #
#   define > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

declare -A c=(
    [end]=$'\e[0m'
    [white]=$'\e[97m'
    [bold]=$'\e[1m'
    [dim]=$'\e[2m'
    [underline]=$'\e[4m'
    [strike]=$'\e[9m'
    [blink]=$'\e[5m'
    [inverted]=$'\e[7m'
    [hidden]=$'\e[8m'
    [black]=$'\e[38;5;0m'
    [fuchsia1]=$'\e[38;5;205m'
    [fuchsia2]=$'\e[38;5;198m'
    [red]=$'\e[38;5;160m'
    [red2]=$'\e[38;5;196m'
    [orange]=$'\e[38;5;202m'
    [orange2]=$'\e[38;5;208m'
    [magenta]=$'\e[38;5;5m'
    [blue]=$'\e[38;5;033m'
    [blue2]=$'\e[38;5;033m'
    [blue3]=$'\e[38;5;68m'
    [cyan]=$'\e[38;5;51m'
    [green]=$'\e[38;5;2m'
    [green2]=$'\e[38;5;76m'
    [yellow]=$'\e[38;5;184m'
    [yellow2]=$'\e[38;5;190m'
    [yellow3]=$'\e[38;5;193m'
    [grey1]=$'\e[38;5;240m'
    [grey2]=$'\e[38;5;244m'
    [grey3]=$'\e[38;5;250m'
    [navy]=$'\e[38;5;62m'
    [olive]=$'\e[38;5;144m'
    [peach]=$'\e[38;5;210m'
)

# #
#   unicode for emojis
#       https://apps.timwhitlock.info/emoji/tables/unicode
# #

declare -A icon=(
    ["symbolic link"]=$'\xF0\x9F\x94\x97' # 🔗
    ["regular file"]=$'\xF0\x9F\x93\x84' # 📄
    ["directory"]=$'\xF0\x9F\x93\x81' # 📁
    ["regular empty file"]=$'\xe2\xad\x95' # ⭕
    ["log"]=$'\xF0\x9F\x93\x9C' # 📜
    ["1"]=$'\xF0\x9F\x93\x9C' # 📜
    ["2"]=$'\xF0\x9F\x93\x9C' # 📜
    ["3"]=$'\xF0\x9F\x93\x9C' # 📜
    ["4"]=$'\xF0\x9F\x93\x9C' # 📜
    ["5"]=$'\xF0\x9F\x93\x9C' # 📜
    ["pem"]=$'\xF0\x9F\x94\x92' # 🔑
    ["pub"]=$'\xF0\x9F\x94\x91' # 🔒
    ["pfx"]=$'\xF0\x9F\x94\x92' # 🔑
    ["p12"]=$'\xF0\x9F\x94\x92' # 🔑
    ["key"]=$'\xF0\x9F\x94\x91' # 🔒
    ["crt"]=$'\xF0\x9F\xAA\xAA ' # 🪪
    ["gz"]=$'\xF0\x9F\x93\xA6' # 📦
    ["zip"]=$'\xF0\x9F\x93\xA6' # 📦
    ["gzip"]=$'\xF0\x9F\x93\xA6' # 📦
    ["deb"]=$'\xF0\x9F\x93\xA6' # 📦
    ["sh"]=$'\xF0\x9F\x97\x94' # 🗔
)

# #
#   define > App repo paths and commands
# #

app_title="Opengist Debian (.deb) Builder"
app_about="A bash utility to create a .deb file from the currently released Opengist .tar.gz releases."
app_ver=("1" "1" "0" "0")
app_repo_author="Aetherinox"
app_repo_name="opengist-debian"
app_repo_branch="main"
app_repo_url="https://github.com/${app_repo_author}/${app_repo_name}"
app_repo_mnfst="https://raw.githubusercontent.com/${app_repo_author}/${app_repo_name}/${app_repo_branch}/manifest.json"
app_repo_src="thomiceli/opengist"

# #
#   define > Default Arguments
# #

argPackageName="opengist"
argDevEnabled=false
argForceUpdate=false
argPrecheck=false
argSkipChangelog=false
argVerCurrent=1.1.0
argChownOwner=root
argDryRun=false
argWorkflowEnabled=false
argBranchReset="${app_repo_branch}"

# #
#   define > files
# #

app_file_this=$(basename "$0")                                                      #  update.sh (with ext)
app_file_bin="${app_file_this%.*}"                                                  #  update (without ext)
app_pid=$BASHPID

# #
#   define > folders
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
app_dir_this_dir="${PWD}"                                                           #  current script directory
app_dir_bin="${HOME}/bin"                                                           #  /home/$USER/bin

# #
#   https://man7.org/linux/man-pages/man1/date.1.html
#
#   Thu, 01 May 2025 14:33:00 +0200
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
#   define > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   define > distro
#       freedesktop.org and systemd
#       returns distro information.
# #

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        sys_os_name=$NAME
        sys_os_ver=$VERSION_ID

# #
#   distro > linuxbase.org
# #

    elif type lsb_release >/dev/null 2>&1; then
        sys_os_name=$(lsb_release -si)
        sys_os_ver=$(lsb_release -sr)

# #
#   distro > versions of Debian/Ubuntu without lsb_release cmd
# #

    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        sys_os_name=$DISTRIB_ID
        sys_os_ver=$DISTRIB_RELEASE

# #
#   distro > older Debian/Ubuntu/etc distros
# #

    elif [ -f /etc/debian_version ]; then
        sys_os_name=Debian
        sys_os_ver=$(cat /etc/debian_version)

# #
#   distro > fallback: uname, e.g. "Linux <version>", also works for BSD
# #

    else
        sys_os_name=$(uname -s)
        sys_os_ver=$(uname -r)
    fi

# #
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
# #

get_version()
{
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

# #
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
# #

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

# #
#   Ensure we're in the correct directory
# #

cd ${app_dir}

# #
#   define > changelog
# #

CHANGELOG=$(cat <<-end
    * New release

-- Thomas Miceli <thomiceli@github.com>  ${date_now} +0200
end
)

# #
#   Create .gitignore
# #

if [ ! -f "${app_dir}/.gitignore" ] || [ ! -s "${app_dir}/.gitignore" ]; then

    touch "$app_dir/.gitignore"

sudo tee "$app_dir/.gitignore" << EOF > /dev/null
# #
#   Misc
# #
*.deb
EOF

fi

# #
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   opengist bin folder.
#
#   opengist.sh will house the path needed for the script to run
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
#   Packages > git not installed
# #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${c[green]}OK           ${c[end]}Installing package ${c[blue2]}Git${c[end]}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1
fi

# #
#   Packages > gpg not installed
# #

if ! [ -x "$(command -v gpg)" ]; then
    echo -e "  ${c[green]}OK           ${c[end]}Installing package ${c[blue2]}GPG${c[end]}"
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
    cp "${HOME}/.local/bin/lastversion" "${HOME}/bin/"
    sudo touch "/etc/profile.d/lastversion.sh"

    envpath_add_lastversion '${HOME}/bin'

    echo 'export PATH="${HOME}/bin:$PATH"' | sudo tee "/etc/profile.d/lastversion.sh"

    . ~/.bashrc
    . ~/.profile

    source "${HOME}/.profile" # not executing for some reason
fi

# #
#   Display Usage Help
#
#   activate using ./opengist.sh --help or -h
# #

opt_usage()
{
    echo -e
    printf "  ${c[blue]}${app_title}${c[end]}\n" 1>&2
    printf "  ${c[grey2]}${app_about}${c[end]}\n" 1>&2
    printf "  ${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--precheck ${c[end]} || ${c[grey2]}--current ${c[yellow]}\"1.10.0\"${c[end]} [ ${c[grey2]}--force${c[end]} ] \n" 1>&2
    echo -e
    echo -e
    printf '  %-5s %-40s\n' "${c[grey1]}Syntax:${c[end]}" "" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Command${c[end]}           " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-option${c[end]} [ ${c[yellow]}arg${c[end]} ]${c[end]} ]" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Options${c[end]}           " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-h${c[end]} | ${c[grey2]}--help${c[end]} ]" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}-A${c[end]}            " "required" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}-A...${c[end]}         " "required; multiple can be specified" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}[ -A ]${c[end]}        " "optional" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}[ -A... ]${c[end]}     " "optional; multiple can be specified" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}{ -A | -B }${c[end]}   " "one or the other; do not use both" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Arguments${c[end]}         " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-r${c[yellow]} arg${c[end]} | ${c[grey2]}--repo ${c[yellow]}arg${c[end]} ] ${c[yellow]}arg${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Examples${c[end]}          " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--current${c[yellow]} \"${argVerCurrent}\"${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--precheck$${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--current${c[yellow]} \"${argVerCurrent}\"${c[end]} ${c[grey2]}--name${c[yellow]} \"${argPackageName}\"${c[end]} ${c[grey2]}--dev${c[end]}" 1>&2

    echo -e
    printf '  %-5s %-40s\n' "${c[grey1]}Options:${c[end]}" "" 1>&2

    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-c${c[grey1]},${c[blue2]}  --current ${c[yellow]}<string>${c[end]}         " "specifies your currently installed version of Opengist; requires format \"1.x.x\" ${c[navy]}<default> ${c[peach]}${argVerCurrent}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-p${c[grey1]},${c[blue2]}  --precheck ${c[yellow]}${c[end]}                " "checks if a new version of Opengist exists${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-m${c[grey1]},${c[blue2]}  --message ${c[yellow]}<string>${c[end]}         " "commit message ${c[navy]}<default> ${c[peach]}${argDefaultCommitMsg}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-s${c[grey1]},${c[blue2]}  --status ${c[yellow]}${c[end]}                  " "view list of assigned variables${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-v${c[grey1]},${c[blue2]}  --version ${c[yellow]}${c[end]}                 " "current version of this app${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-x${c[grey1]},${c[blue2]}  --dev ${c[yellow]}${c[end]}                     " "developer mode; verbose logging${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-h${c[grey1]},${c[blue2]}  --help ${c[yellow]}${c[end]}                    " "show this help menu${c[end]}" 1>&2
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

        # #
        #   specifies the name of the package
        #
        #   @usage              opengist -n opengist
        #                       opengist --name opengist
        # #

        -n|--name)
            if [[ "$1" != *=* ]]; then shift; fi
            argPackageName="${1#*=}"
            if [ -z "${argPackageName}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Did not specify a package name; must specify one to continue${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --name ${c[yellow]}\"opengist\"${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -n ${c[yellow]}\"opengist\"${c[end]}"
                exit 1
            fi
            ;;

        # #
        #   forces the opengist package to be re-compiled. does not matter if an update is available or not
        #
        #   @usage              opengist -f
        #                       opengist --force
        # #

        -f|--force)
            argForceUpdate=true
            ;;

        # #
        #   checks to see if the current repository version of Opengist is out of date. does not actually build new .deb package
        #
        #   @usage              opengist -p
        #                       opengist --precheck
        # #

        -p|--precheck)
            argPrecheck=true
            ;;

        # #
        #   skips re-generating .deb packagae changelog
        #
        #   @usage              opengist -s
        #                       opengist --skipChangelog
        # #

        -s|--skipChangelog)
            argSkipChangelog=true
            ;;

        # #
        #   specifies user's current version of Opengist
        #
        #   @usage              opengist -c 1.10.0
        #                       opengist --current 1.10.0
        # #

        -c|--current|--current-version)
            if [[ "$1" != *=* ]]; then shift; fi
            argVerCurrent="${1#*=}"
            if [ -z "${argVerCurrent}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Must specifiy your currently installed version of Opengist${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --current ${c[yellow]}\"1.10.0\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -c ${c[yellow]}\"1.10.0\"${c[grey2]}${c[end]}"
                exit 1
            fi
            ;;

        # #
        #   kills any instances / processes of this script currently running
        #
        #   @usage              opengist -k
        #                       opengist --kill
        # #

        -k|--kill)
            kill -9 `pgrep ${app_file_bin}`
            exit 1
            ;;

        # #
        #   resets the local repo files back to the state of the remote opengist repo (git reset --hard origin/main)
        #
        #   @usage              opengist -R main
        #                       opengist --reset main
        # #

        -R|--reset)
            if [[ "$1" != *=* ]]; then shift; fi
            argBranchReset="${1#*=}"
            if [ -z "${argBranchReset}" ]; then
                argBranchReset="${app_repo_branch}"
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify a branch; defaulting to ${c[yellow]}${argBranchReset}${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --reset ${c[yellow]}\"${argBranchReset}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -R ${c[yellow]}\"main\"${c[grey2]}${c[end]}"
            fi

            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Resetting local repository back to remote status for branch ${c[yellow]}${argBranchReset}${c[end]}"
            git reset --hard origin/${argBranchReset}
            exit 1
            ;;

        # #
        #   fixes permissions on opengist.sh and sets +x
        #
        #   @usage              opengist -f
        #                       opengist --fixperms root
        # #

        -f|-fp|--fixperms|--fix-perms)
            if [[ "$1" != *=* ]]; then shift; fi
            argChownOwner="${1#*=}"
            if [ -z "${argChownOwner}" ]; then
                argChownOwner=root
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify an owner; defaulting to ${c[yellow]}${argChownOwner}${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --fixperms ${c[yellow]}\"${argChownOwner}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -f ${c[yellow]}\"username\"${c[grey2]}${c[end]}"
            fi

            sudo chown -R "${argChownOwner}:${argChownOwner}" "${app_dir}/${app_file_this}" >/dev/null 2>&1
            sudo chmod +x "${app_dir}/${app_file_this}" >/dev/null 2>&1
            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Set perms on ${c[yellow]}${app_dir}/${app_file_this}${c[end]}; chown ${c[yellow]}${argChownOwner}:${argChownOwner}${c[end]}"
            echo -e
            exit 1
            ;;

        # #
        #   enables developer mode; this outputs special debug prints when actions are performed.
        #
        #   @usage              opengist -d
        #                       opengist --dev
        # #

        -w|--workflow)
            argWorkflowEnabled=true
            ;;

        # #
        #   runs the entire process but does not commit changes
        #
        #   @usage              opengist -D
        #                       opengist --dryrun
        # #

        -D|--dryrun)
            argDryRun=true
            ;;

        # #
        #   enables developer mode; this outputs special debug prints when actions are performed.
        #
        #   @usage              opengist -d
        #                       opengist --dev
        # #

        -d|--dev)
            argDevEnabled=true
            ;;

        # #
        #   shows version inforrmation about this script
        #
        #   @usage              opengist -v
        #                       opengist --version
        # #

        -v|--version)
            printf "  ${c[blue]}${app_title} (v$(get_version))${c[end]}\n" 1>&2
            printf "  ${c[end]}${app_about}${c[end]}\n" 1>&2
            printf "  ${c[grey2]}${app_repo_url}${c[end]}\n" 1>&2
            printf "  ${c[grey2]}${sys_os_name} | ${sys_os_ver} (${sys_code} - ${sys_arch})${c[end]}\n\n" 1>&2
            exit 1
            ;;

        # #
        #   shows help menu
        #
        #   @usage              opengist -h
        #                       opengist --help
        # #

        -h|--help)
            opt_usage
            ;;

        # #
        #   default action if invalid flag specified. shows the help menu if the flag specified by the user
        #   does not really exist.
        #
        #   @usage              opengist -Z
        #                       opengist --afgfsdg
        # #

        *)
            opt_usage
            ;;
    esac
    shift
done

# #
#   get specified installed version
# #

pkgVerCurrent=$( [[ -n "$argVerCurrent" ]] && echo "$argVerCurrent" || echo "false"  )

# #
#   if a --current version has been specified.
#   this will be matched against the latest released version.
#
#   if no --current version has been specified, script will exit
# #

if [ "${argForceUpdate}" = false ] && ([ -z "${pkgVerCurrent}" ] || [ "${pkgVerCurrent}" == false ]); then

    echo -e
    echo -e " ${c[blue]}---------------------------------------------------------------------------------------------------${c[end]}"
    echo -e
    echo -e "  ${c[bold]}${c[orange]}WARNING  ${c[end]}Did not specify ${c[orange]}--current${c[end]} to compare with.${c[end]}"
    echo -e "  ${c[bold]}You must specify ${c[orange]}--current 1.X.X${c[end]} of Opengist you have installed.${c[end]}"
    echo -e "  ${c[bold]}This is usually done by the Github workflow when it checks for Opengist updates.${c[end]}"
    echo -e
    echo -e "      ${c[bold]}${c[grey2]}./${app_file_this} --current 1.7.3${c[end]}"
    echo -e
    echo -e " ${c[blue]}---------------------------------------------------------------------------------------------------${c[end]}"
    echo -e

    rm *.tar.gz* >> /dev/null 2>&1

    exit 1
fi

# #
#   remove all .tar.gz files
# #

printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Remove all ${c[yellow]}*.tar.gz*${c[end]}"
rm *.tar.gz* >> /dev/null 2>&1

# #
#   git > clone
# #

# printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Cloning ${c[yellow]}${app_repo_url}.git${c[end]}"
# git clone "${app_repo_url}.git" >> /dev/null 2>&1

# #
#   move all files including hidden with /{.,}*
# #

# printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Moving ${c[yellow]}${app_repo_name}${c[end]} to current directory"
# mv --force ${app_repo_name}/{.,}* .

# #
#   remove opengist-debian/ folder left over from clone and move
# #

# printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Removing folder ${c[yellow]}${app_repo_name}${c[end]}"
# rm -rf "${app_repo_name}/" >> /dev/null 2>&1

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

            pkgArch=${lst_arch[$j]}
            pkgArchLabel=${pkgArch}

            if [ "${pkgArch}" = "386" ]; then
                pkgArchLabel="i386"
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Detected Architecture ${pkgArch}; renaming to ${c[yellow]}${pkgArchLabel}${c[end]}"
            fi

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Processing architecture ${c[yellow]}${pkgArch}${c[end]}"

            # #
            #   get lastversion URL of package
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Fetching package URL from ${c[yellow]}LastVersion${c[end]}"
            pkgUrl=($( lastversion --pre --assets ${app_repo_src} --filter "(?:\b|_)(?:linux-${pkgArch})\b.*\.tar.gz$" ) )

            # #
            #   download
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Downloading package from ${c[yellow]}${pkgUrl}${c[end]}"
            wget "$pkgUrl" >> /dev/null 2>&1

            # #
            #   Assign file names
            # #

            pkgFolder=($( echo "${pkgUrl}" | sed 's:.*/::' | sed 's/\.tar\.gz//g' ) )
            pkgArchive=($( echo "${pkgUrl}" | sed 's:.*/::' ) )
            pkgVersion=($( echo "${pkgArchive}" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/' ) )

            if [ -f "${app_dir_this_dir}/${pkgArchive}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Successfully downloaded archive to ${c[green]}${app_dir_this_dir}/${pkgArchive}${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to download archive file ${c[red2]}${pkgArchive}${c[end]} to ${c[red2]}${app_dir_this_dir}/${pkgArchive}${c[end]}; aborting run${c[end]}"
                if [ "${argPrecheck}" = true ]; then
                    exit "abort"
                else
                    echo 1
                fi
            fi

            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$pkgUrl${c[grey1]} with value ${c[navy]}${pkgUrl}${c[end]}"
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$pkgArchive${c[grey1]} with value ${c[navy]}${pkgArchive}${c[end]}"
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$pkgFolder${c[grey1]} with value ${c[navy]}${pkgFolder}${c[end]}"
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$pkgVersion${c[grey1]} with value ${c[navy]}${pkgVersion}${c[end]}"
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$argForceUpdate${c[grey1]} with value ${c[navy]}${argForceUpdate}${c[end]}"
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$argPrecheck${c[grey1]} with value ${c[navy]}${argPrecheck}${c[end]}"
            fi

            # #
            #   run version check if:    -f, --force    = FALSE
            #   run version check if:    -p, --precheck = TRUE
            # #

            if [ "${argForceUpdate}" = false ] || [ "${argPrecheck}" = true ]; then

                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Checking for any opengist updates available${c[end]}"

                # #
                #   Check for available update
                #
                #       returns TRUE if specified version is higher than current version
                #       returns FALSE if specified version is not higher than current version
                # #

                bUpdateAvailable=$(get_version_compare_gt "${pkgVersion}" "${pkgVerCurrent}" && echo "true" || echo "false")

                if [[ "${bUpdateAvailable}" == "false" ]]; then
                    printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}No update found for ${c[red2]}opengist${c[end]}"
                else
                    printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Found update for ${c[green]}opengist${c[end]}"
                fi

                # #
                #   Abort > Both versions are the same
                # #

                if [[ "${pkgVerCurrent}" == "${pkgVersion}" ]]; then
                    echo -e
                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}No Update Found (Running Latest Version)${c[end]}"
                    printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[end]}Version of opengist you are running and the version available for download are the same.${c[end]}"
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Running${c[end]}" "${c[orange]}${pkgVerCurrent}${c[end]}"
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Latest${c[end]}" "${c[orange]}${pkgVersion}${c[end]}"
                    echo -e

                    if [ "${argForceUpdate}" = false ]; then
                        if [ "${argPrecheck}" = true ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Exiting because ${c[navy]}\$argPrecheck${c[grey1]} = ${c[navy]}${argPrecheck}${c[end]}"
                            fi
                            if [ "${argWorkflowEnabled}" = true ]; then
                                rm *.tar.gz* >> /dev/null 2>&1
                                echo "abort"
                            else
                                rm *.tar.gz* >> /dev/null 2>&1
                                exit 1
                            fi
                        else
                            rm *.tar.gz* >> /dev/null 2>&1
                            exit 1
                        fi
                    fi
                fi

                # #
                #   Abort > Current version higher than specified version using argument
                #       '-a, --current, --currentVer 1.X.X'
                # #

                if [[ "${bUpdateAvailable}" = false ]]; then
                    echo -e
                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}No Update Found (Higher than Available)${c[end]}"
                    printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[end]}Version of opengist you are running is higher than version available to download.${c[end]}"
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Running${c[end]}" "${c[orange]}${pkgVerCurrent}${c[end]}"
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Latest${c[end]}" "${c[orange]}${pkgVersion}${c[end]}"
                    echo -e

                    if [ "${argForceUpdate}" = false ]; then
                        if [ "${argPrecheck}" = true ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Exiting because ${c[navy]}\$argPrecheck${c[grey1]} = ${c[navy]}${argPrecheck}${c[end]}"
                            fi
                            if [ "${argWorkflowEnabled}" = true ]; then
                                rm *.tar.gz* >> /dev/null 2>&1
                                echo "abort"
                            else
                                rm *.tar.gz* >> /dev/null 2>&1
                                exit 1
                            fi
                        else
                            rm *.tar.gz* >> /dev/null 2>&1
                            exit 1
                        fi
                    fi
                fi

                # #
                #   Precheck for update. Go no further after this point
                #       '-p, --precheck'
                #
                #   @example    : ./update.sh --available 1.7.1 --precheck
                # #

                if [[ "${bUpdateAvailable}" = true ]]; then
                    echo -e
                    printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[green]}Update Found for Opengist${c[end]}"
                    printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[end]}You are running an outdated copy of this package. An update is available.${c[end]}"
                    if [[ "${argPrecheck}" = true ]]; then
                        printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[end]}To update, run this script again without ${c[grey2]}-p, --precheck${c[end]}"
                    else
                        printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[end]}${c[blink]}${c[yellow]}Starting Update ...${c[end]}"
                    fi
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Running${c[end]}" "${c[green2]}${pkgVerCurrent}${c[end]}"
                    printf '%-34s %-25s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}Latest${c[end]}" "${c[green2]}${pkgVersion}${c[end]}"
                    echo -e

                    if [ "${argForceUpdate}" = false ]; then
                        if [ "${argPrecheck}" = true ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Exiting because ${c[navy]}\$argPrecheck${c[grey1]} = ${c[navy]}${argPrecheck}${c[end]}"
                            fi

                            if [ "${argWorkflowEnabled}" = true ]; then
                                rm *.tar.gz* >> /dev/null 2>&1
                                echo "success"
                            else
                                rm *.tar.gz* >> /dev/null 2>&1
                                exit 0
                            fi
                        fi
                    fi
                fi
            fi

            if [ "${argPrecheck}" = true ]; then
                break
            fi

            # #
            #   Create /build/opengist-* folders
            # #

            if [ -f "${pkgArchive}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Found archive ${c[green]}${pkgArchive}${c[end]}"
                mkdir -p "build/${argPackageName}-${pkgArch}" | tar -xvzf "${pkgArchive}" -C "build/${argPackageName}-${pkgArch}" >> /dev/null 2>&1
                if [ -d "build/${argPackageName}-${pkgArch}" ]; then
                    printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created directory ${c[green]}"build/${argPackageName}-${pkgArch}"${c[end]}"
                fi
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Could not find archive file ${c[red2]}\"${pkgArchive}\"${c[end]} does not exist; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Delete the original .tar.gz files
            # #

            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Remove existing archive ${c[green]}${argPackageName}*.tar.gz${c[end]}"
            rm "${argPackageName}*.tar.gz" >> /dev/null 2>&1

            # #
            #   Create .deb structure folders
            #
            #   these should already be created within the github repo.
            # #

            app_dir_usr_share="src/$pkgFolder/usr"
            app_dir_debian="src/$pkgFolder/DEBIAN"
            app_dir_etc_opengist="src/$pkgFolder/etc/opengist"
            app_dir_lib_systemd_system="src/$pkgFolder/lib/systemd/system"
            app_dir_usr_bin="${app_dir_usr_share}/bin"
            app_dir_usr_share_applications="${app_dir_usr_share}/share/applications"
            app_dir_usr_share_doc_opengist_examples="${app_dir_usr_share}/share/doc/opengist/examples"
            app_dir_usr_share_icons_highcolor="${app_dir_usr_share}/share/icons/hicolor"
            app_dir_usr_share_lintian_overrides="${app_dir_usr_share}/share/lintian/overrides"
            app_dir_usr_share_man_man1="${app_dir_usr_share}/share/man/man1"
            app_dir_template_usr_share="template/usr/share"

            mkdir -p "${app_dir_debian}"
            if [ -d "${app_dir_debian}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_debian}\"${c[end]}"
            fi

            mkdir -p "${app_dir_etc_opengist}"
            if [ -d "${app_dir_etc_opengist}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_etc_opengist}\"${c[end]}"
            fi

            mkdir -p "${app_dir_lib_systemd_system}"
            if [ -d "${app_dir_lib_systemd_system}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_lib_systemd_system}\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_bin}"
            if [ -d "${app_dir_usr_bin}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_bin}\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_share_applications}"
            if [ -d "${app_dir_usr_share_applications}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_share_applications}\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_share_doc_opengist_examples}"
            if [ -d "${app_dir_usr_share_doc_opengist_examples}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_share_doc_opengist_examples}\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_share_icons_highcolor}"
            if [ -d "${app_dir_usr_share_icons_highcolor}/" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_share_icons_highcolor}/\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_share_lintian_overrides}"
            if [ -d "${app_dir_usr_share_lintian_overrides}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_share_lintian_overrides}/\"${c[end]}"
            fi

            mkdir -p "${app_dir_usr_share_man_man1}"
            if [ -d "${app_dir_usr_share_man_man1}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Created folder ${c[green]}\"${app_dir_usr_share_man_man1}/\"${c[end]}"
            fi

            # #
            #   Copy > Template files from template/usr/share/ to src/$pkgFolder/usr/share/
            #
            #   /usr/share/applications, docs, icons, lintian, man
            #
            #   the template files don't always have to be updated. After this copy process, the files will be updated later
            #   with the actual values needed for the release.
            # #

            if ! [ -d "${app_dir_template_usr_share}" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Git repo template folder ${c[red2]}\"${app_dir_template_usr_share}/\"${c[end]} does not exist; aborting${c[end]}"
                exit 1
            fi

            cp -r "${app_dir_template_usr_share}" "${app_dir_usr_share}/" >> /dev/null 2>&1

            if [ -d "${app_dir_usr_share}" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Copied repo template from ${c[green]}\"${app_dir_template_usr_share}/\"${c[end]} to ${c[green]}\"${app_dir_usr_share}/\"${c[end]}"
            fi

            # #
            #   Create DEBIAN/conffile
            # #

tee "${app_dir_debian}/conffiles" << EOF > /dev/null
/etc/opengist/config.yml
EOF

            if ! [ -f "${app_dir_debian}/conffiles" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"${app_dir_debian}/conffiles\"${c[end]}; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Create DEBIAN/control
            # #

tee "${app_dir_debian}/control" << EOF > /dev/null
Package: opengist
Version: ${pkgVersion}
Section: utils
Priority: optional
Architecture: ${pkgArchLabel}
Maintainer: Thomas Miceli <thomiceli@github.com>
Depends: adduser
Homepage: https://github.com/Aetherinox/opengist-debian
Description: Self-hosted pastebin powered by Git, open-source alternative to Github
 Gist. Opengist is a self-hosted pastebin powered by Git. All snippets are
 stored in a Git repository and can be read and/or modified using standard Git
 commands, or with the web interface. It is similar to GitHub Gist, but
 open-source and could be self-hosted.
EOF

            if ! [ -f "${app_dir_debian}/control" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"${app_dir_debian}/control\"${c[end]}; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Create /DEBIAN/postinst
            # #

tee "${app_dir_debian}/postinst" << 'EOF' > /dev/null
#!/bin/sh
set -e

# #
#   @author :           aetherinox
#   @script :           Opengist .deb Package
#   @when   :           2025-08-02 02:14:53
#   @url    :           https://github.com/Aetherinox/opengist-debian
#
# #

# #
#   install desktop shortcut
# #

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

# #
#   color chart
# #

declare -A c=(
    [bold]=$'\e[1m'
    [end]=$'\e[0m'
    [green]=$'\e[38;5;2m'
    [yellow]=$'\e[38;5;184m'
    [blue]=$'\e[38;5;033m'
    [magenta]=$'\e[38;5;5m'
    [grey1]=$'\e[38;5;240m'
    [grey2]=$'\e[38;5;244m'
    [grey3]=$'\e[38;5;250m'
    [fuchsia1]=$'\e[38;5;205m'
    [fuchsia2]=$'\e[38;5;198m'
)

# #
#   default vars
# #

OGIST_USER="opengist"
OGIST_HOME="/var/lib/opengist"
OGIST_SERV="/etc/systemd/system/opengist.service"
OGIST_CONF="/etc/opengist/config.yml"

if [ "$1" = "configure" ]; then

    # #
	#   add opengist user/group - will gracefully abort if the user already exists.
	#   homedir not created
    # #

	set +e
	adduser --system --home "${OGIST_HOME}" --no-create-home --group "${OGIST_USER}" 2>/dev/null
	set -e

    # #
	#   If the homedir does not already exist, create it with proper
	#   ownership and permissions.
    # #

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

printf '\n%-35s\n\n' "  ${c[bold]}${c[grey2]}OpenGist Installer${c[end]}"
printf '%-35s\n' "  ${c[bold]}${c[end]}Opengist has been installed. View the paths below to see where you can${c[end]}"
printf '%-35s\n\n' "  ${c[bold]}${c[end]}find certain files for configuring Opengist.${c[end]}"
printf '%-38s %-40s\n' "  ${c[end]}Database Location${c[end]}" "${c[bold]}${c[yellow]}${OGIST_HOME}${c[end]}"
printf '%-38s %-40s\n' "  ${c[end]}Config Location${c[end]}" "${c[bold]}${c[yellow]}${OGIST_CONF}${c[end]}"
printf '%-38s %-40s\n\n' "  ${c[end]}Service Location${c[end]}" "${c[bold]}${c[yellow]}${OGIST_SERV}${c[end]}"
printf '%-35s\n' "  ${c[end]}The ${c[bold]}${c[yellow]}opengist.service${c[end]} will be ran as user ${c[bold]}${c[yellow]}${OGIST_USER}${c[end]}."
printf '%-35s\n\n\n' "  ${c[end]}To change the user, edit the service file and modify ${c[bold]}${c[magenta]}USER=$OGIST_USER${c[end]}"
EOF

            if ! [ -f "${app_dir_debian}/postinst" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"${app_dir_debian}/postinst\"${c[end]}; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Copy opengist binary file
            #
            #       build/opengist-amd64/opengist/opengist > src/opengist1.10.0-linux-386/usr/bin/opengist
            #       build/opengist-amd64/opengist/opengist > src/opengist1.10.0-linux-amd64/usr/bin/opengist
            #       build/opengist-amd64/opengist/opengist > src/opengist1.10.0-linux-arm64/usr/bin/opengist
            # #

            if ! [ -f "build/${argPackageName}-${pkgArch}/opengist/opengist" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"build/${argPackageName}-${pkgArch}/opengist/opengist\"${c[end]}; aborting${c[end]}"
                exit 1
            fi

            cp "build/${argPackageName}-${pkgArch}/opengist/opengist" "${app_dir_usr_bin}/opengist" >> /dev/null 2>&1
            if [ -f "build/${argPackageName}-${pkgArch}/opengist/opengist" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Copied build binary from ${c[green]}\"build/${argPackageName}-${pkgArch}/opengist/opengist\"${c[end]} to ${c[green]}\"${app_dir_usr_bin}/opengist\"${c[end]}"
            fi

            # #
            #   Copy config yml
            #
            #       build/opengist-386/opengist/config.yml > src/opengist1.10.0-linux-386/etc/opengist/config.yml
            #       build/opengist-amd64/opengist/config.yml > src/opengist1.10.0-linux-amd64/etc/opengist/config.yml
            #       build/opengist-arm64/opengist/config.yml > src/opengist1.10.0-linux-arm64/etc/opengist/config.yml
            # #

            if ! [ -f "build/${argPackageName}-${pkgArch}/opengist/config.yml" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"build/${argPackageName}-${pkgArch}/opengist/config.yml\"${c[end]}; aborting${c[end]}"
                exit 1
            fi
            cp "build/${argPackageName}-${pkgArch}/opengist/config.yml" "${app_dir_etc_opengist}/config.yml" >> /dev/null 2>&1
            if [ -f "${app_dir_etc_opengist}/config.yml" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Copied config file from ${c[green]}\"build/${argPackageName}-${pkgArch}/opengist/config.yml\"${c[end]} to ${c[green]}\"${app_dir_etc_opengist}/config.yml\"${c[end]}"
            fi

            # #
            #   Copy config yml
            #
            #       build/opengist-386/opengist/config.yml > src/opengist1.10.0-linux-386/usr/share/doc/opengist/examples/config.yaml
            #       build/opengist-amd64/opengist/config.yml > src/opengist1.10.0-linux-amd64/usr/share/doc/opengist/examples/config.yaml
            #       build/opengist-arm64/opengist/config.yml > src/opengist1.10.0-linux-arm64/usr/share/doc/opengist/examples/config.yaml
            # #

            if ! [ -f "build/${argPackageName}-${pkgArch}/opengist/config.yml" ]; then
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to find file ${c[red2]}\"build/${argPackageName}-${pkgArch}/opengist/config.yml\"${c[end]}; aborting${c[end]}"
                exit 1
            fi
            cp "build/${argPackageName}-${pkgArch}/opengist/config.yml" "${app_dir_usr_share_doc_opengist_examples}/config.yaml" >> /dev/null 2>&1
            if [ -f "${app_dir_usr_share_doc_opengist_examples}/config.yaml" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Copied config file from ${c[green]}\"${app_dir_usr_share_doc_opengist_examples}/config.yaml\"${c[end]} to ${c[green]}\"${app_dir_usr_share_doc_opengist_examples}/config.yaml\"${c[end]}"
            fi

            # #
            #   open 'DEBIAN/control' and change version number
            # #

            sed -Ei "s/(Version:) .*/\1 ${pkgVersion}/" "${app_dir_debian}/control" >> /dev/null 2>&1
            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Write variable ${c[green]}Version: ${pkgVersion}${c[end]} to file ${c[green]}\"${app_dir_debian}/control\"${c[end]}"

            # #
            #   open 'usr/share/applications/opengist.desktop' and change version number
            # #

            # sed -Ei "s/(Version=).*/\1${pkgVersion}/" ${app_dir_usr_share_applications}opengist.desktop >> /dev/null 2>&1
            # echo -e "  ${c[end]}+w opengist.desktop:     ${c[blue]}${app_dir_usr_share_applications}opengist.desktop${c[end]}"

            # #
            #   Create /usr/share/applications/opengist.desktop
            # #

tee "${app_dir_usr_share_applications}/opengist.desktop" << EOF > /dev/null
[Desktop Entry]
Name=Opengist
GenericName=Opengist
Version=${pkgVersion}
Comment=Start Opengist server
Type=Application
Icon=opengist
Categories=Utility;
Exec=opengist --config "/etc/opengist/config.yml"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

            if [ -f "${app_dir_usr_share_applications}/opengist.desktop" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Generated opengist shortcut ile ${c[green]}\"${app_dir_usr_share_applications}/opengist.desktop\"${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to generate opengist shortcut file ${c[red2]}\"${app_dir_usr_share_applications}/opengist.desktop\"${c[end]} which does not exist; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Create /usr/share/lintian/overrides/opengist
            # #

tee "${app_dir_usr_share_lintian_overrides}/opengist" << 'EOF' > /dev/null
opengist: statically-linked-binary [usr/bin/opengist]
EOF

            if [ -f "${app_dir_usr_share_lintian_overrides}/opengist" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Wrote lintian override rules to file ${c[green]}\"${app_dir_usr_share_lintian_overrides}/opengist\"${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to write lintian override rules to file ${c[red2]}\"${app_dir_usr_share_lintian_overrides}/opengist\"${c[end]} which does not exist; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Create /lib/systemd/system/opengist.service
            # #

tee "${app_dir_lib_systemd_system}/opengist.service" << 'EOF' > /dev/null
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

            if [ -f "${app_dir_lib_systemd_system}/opengist.service" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Generated opengist service file at ${c[green]}\"${app_dir_lib_systemd_system}/opengist.service\"${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to generate opengist service file ${c[red2]}\"${app_dir_lib_systemd_system}/opengist.service\"${c[end]} which does not exist; aborting${c[end]}"
                exit 1
            fi

            # #
            #   Skip changelog
            #
            #   do not edit changelog if -s, --skipChangelog
            #   do not edit changelog if -p, --precheck
            # #

            if [ "${argSkipChangelog}" = false ] && [ "${argPrecheck}" = false ]; then

                # #
                #   changelog
                # #

                    # #
                    #   changelog > decompress
                    #
                    #   this requires that you already have a file called changelog.gz which will be extracted.
                    # #

                    gunzip "${app_dir_usr_share}/share/doc/opengist/changelog.gz" >> /dev/null 2>&1
                    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Unzipping ${c[yellow]}\"${app_dir_usr_share}/share/doc/opengist/changelog.gz\"${c[end]}"

                    # #
                    #   changelog > AMD64 > append to top of file
                    #       1i      : insert before line 1
                    #       .       : end inserting
                    #       wq      : save and quit
                    # #

ed "${app_dir_usr_share}/share/doc/opengist/changelog" << END_ED > /dev/null
1i
${argPackageName} (${pkgVersion}) stable; urgency=low

${CHANGELOG}

.
wq
END_ED

                    if [ -f "${app_dir_usr_share}/share/doc/opengist/changelog" ]; then
                        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Generated opengist changelog file at ${c[green]}\"${app_dir_usr_share}/share/doc/opengist/changelog\"${c[end]}"
                    else
                        printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to generate opengist changelog file ${c[red2]}\"${app_dir_usr_share}/share/doc/opengist/changelog\"${c[end]} which does not exist; aborting${c[end]}"
                        exit 1
                    fi

                    # #
                    #   changelog > compress
                    # #

                    gzip --best -n "${app_dir_usr_share}/share/doc/opengist/changelog"
                    if [ -f "${app_dir_usr_share}/share/doc/opengist/changelog.gz" ]; then
                        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Generated opengist compressed changelog file at ${c[green]}\"${app_dir_usr_share}/share/doc/opengist/changelog.gz\"${c[end]}"
                    else
                        printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to generate opengist compressed changelog file ${c[red2]}\"${app_dir_usr_share}/share/doc/opengist/changelog.gz\"${c[end]} which does not exist; aborting${c[end]}"
                        exit 1
                    fi
            fi

            # #
            #   set permissions
            # #

            sudo chmod 0775 "src/${pkgFolder}/DEBIAN/postinst"
            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Chmod 0755 ${c[yellow]}\"src/${pkgFolder}/DEBIAN/postinst\"${c[end]}"

            # #
            #   create .deb package
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Creating .deb file ${c[yellow]}\"src/${pkgFolder}\"${c[end]}"
            dpkg-deb --root-owner-group --build "src/${pkgFolder}" >> /dev/null 2>&1

            if [ -f "src/${pkgFolder}.deb" ]; then
                printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Successfully created .deb file ${c[green]}\"src/${pkgFolder}.deb\"${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to create opengist .deb file ${c[red2]}\"src/${pkgFolder}.deb\"${c[end]} which does not exist; aborting${c[end]}"
                exit 1
            fi

            # #
            #   run lintian
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Running lintian on folder ${c[yellow]}\"src/${pkgFolder}\"${c[end]}"
            lintian src/${pkgFolder}.deb --tag-display-limit 0 | grep executable-not-elf

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Cleaning up ${c[yellow]}build/${c[end]} folder${c[end]}"

            rm -rf "build" >> /dev/null 2>&1
            rm *.tar.gz* >> /dev/null 2>&1

            if [ -d "src/${pkgFolder}/" ]; then
                rm -rf "src/${pkgFolder}/"
                if ! [ -d "src/${pkgFolder}/" ]; then
                    printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Cleaned up folder ${c[green]}src/${pkgFolder}/${c[end]}"
                else
                    printf '%-29s %-65s\n' "  ${c[red2]}ERROR${c[end]}" "${c[end]}Failed to clean up folder ${c[red2]}src/${pkgFolder}/${c[end]}"
                fi
            fi

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Updating packages from ${c[yellow]}${pkgVerCurrent}${c[end]} to ${c[yellow]}${pkgVersion}${c[end]}"

            if [ "$pkgArchLabel" != "$pkgArch" ]; then
                # file is ok
                if grep -q i386 "src/${pkgFolder}.deb"; then
                    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "File ${c[yellow]}src/${pkgFolder}.deb${c[end]} already contains substring ${c[yellow]}${pkgArchLabel}${c[end]}"
                else
                    # file needs re-named
                    pkgFolderNew="${pkgFolder/-386/-i386}"
                    mv "src/${pkgFolder}.deb" "src/${pkgFolderNew}.deb"
                    printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Renamed ${c[green]}src/${pkgFolder}.deb${c[end]} to ${c[green]}src/${pkgFolderNew}.deb${c[end]}"
                fi
            fi

            # #
            #   The last line but be just the version number, this is used in the Github workflow
            # #

            echo ${pkgVersion}
        done
