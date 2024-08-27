#!/bin/bash
# rethyxyz's Installation Script (RIS):
# A modular, automated Arch Linux installation script.

#
# TODOs
#
# TODO: Locale should be chosen through a language variable, plus 2 secondary
#       ones which are optional.
# TODO: I should actually route the directories that need to be cleanup()'d
#       through rb. This would be the safer way, plus I can to plus my stuff.
# TODO: Add the git repo clone to the variable definitions section. Amend the
#       $DESTS var as well.
# TODO: change_dwm_pulse_bind can be mitigated and removed by using pulsemixer
#       instead of pactl. 
# TODO: Iterate through length of array here in download repos function.
# TODO: Add a swap file. Just started using laptops around/under 4GB RAM.
# TODO: Install pup from aur.

#
# Variable Definitions
#
# As long as your dotfiles keeps the same hierarchy as they do in the home
# directory (i.e. "$HOME"/.config/qutebrowser, "$HOME"/.bash_aliases,
# "$HOME"/.vimrc), they should work flawlessly.
readonly DOTFILES_REPO=("https://github.com/rethyxyz/dotfiles/", "$HOME/dotfiles")
readonly DOTFILES_TO_GRAB=(".bash_aliases" ".bash_profile" ".bashrc" ".vimrc")
# Install Python module from pip.
readonly PIP_PROGS=("ueberzug" "yt-dlp" "gallery-dl")
# Possible options:
#   ThinkPad-E550/E550
#   ThinkPad-E570/E550
#   FX4100
#   Server (generic)
#   Desktop (generic)
#   Laptop (generic)
DEVICE="unset"
readonly DWM_REPO=("https://github.com/rethyxyz/dwm", "$HOME/dwm")
readonly DWM_BAR_REPO=("https://github.com/rethyxyz/dwmbar", "$HOME/dwmbar")
readonly ST_REPO=("https://github.com/rethyxyz/st-0.8.5", "$HOME/st")
readonly HOSTNAME="unset"
# Optional. For GitHub credentials.
readonly NAME="unset"
readonly GIT_EMAIL="unset"
# Example:
#   America/Kentucky/Louisville
#   Europe/Budapest
#
# You can find your zone in /usr/share/zoneinfo/.
readonly ZONE="Canada/Atlantic"
# Don't put partition; Just drive letter. This is IMPORANT. Don't mess this up.
readonly INSTALLATION_DRIVE="/dev/sda"
# You can add or remove pacman sourced programs here.
PACMAN_PROGS=(\
"adobe-source-han-sans-kr-fonts" "curl" "dmenu" "dunst" "feh" "firefox" "fuse"
"gvim" "imagemagick" "irssi" "libnotify" "lxappearance" "mpc" "mpd" "mpv"
"ncmpcpp" "newsboat" "nginx" "noto-fonts-emoji" "ntfs-3g" "pandoc" "php-fpm"
"picard" "picom" "pulseaudio" "pulsemixer" "python-adblock" "python-pip"
"python3" "qbittorrent" "qutebrowser" "ranger" "rsync" "scrot" "shellcheck"
"slock" "sshfs" "texlive-core" "ttf-dejavu" "ttf-hanazono" "unzip" "wget"
"xorg" "xorg-xinit" "xorg-xinput" "xorg-xset" "xorg-xsetroot" "zathura"
"zathura-cb" "zathura-pdf-poppler" "gource" "terminus-font" "jq" "wmctrl" \
)

#
# Functions
#
# Used for rethyxyz/dwmbar: The status bar.
install_emoji_support() { cd "$HOME"/libxft-bgra && makepkg -mi || return; }

# Soulseek is for royalty free music only, of course.
install_soulseek() { cd "$HOME/soulseekqt" || return; makepkg -si; }

install_from_pip() { [[ ! "${PIP_PROGS[@]}" ]] || return; sudo pip3 install "${PIP_PROGS[@]}"; }

# The newest version is needed for proper image previews with st. Ueberzug
# doesn't work with the version in the Arch standard repo.
compile_ranger() { cd "$HOME/ranger" || return; sudo make clean install; }

set_home_perms() { sudo chown "$USER":wheel -R "$HOME"; }

set_hostname() { sudo su root -c "printf \"%s\" $HOSTNAME > /etc/hostname"; }

enable_services() { sudo systemctl enable mpd pulseaudio NetworkManager; }

compile_dwm() {
    cd ${DWM_REPO[1]} \
        && sudo make clean install \
        || printf "Failed to compile dwm\n"
}

compile_st() {
    cd ${ST_REPO[1]} \
        && sudo make clean install \
        || printf "Failed to compile st\n"
}

configure_pacman() {
    sudo su root -c \
        "sed -e s/#Color/Color/g -e s/#ParallelDownloads\ =\ 5/ParallelDownloads\ =\ 5/g -i /etc/pacman.conf"
}

configure_git() {
    if [[ ! "$NAME" = "unset" ]] && [[ ! "$GIT_EMAIL" = "unset" ]]; then
        git config --global user.email "$GIT_EMAIL"
        git config --global user.name "$NAME"
    fi
}

clean_up() {
    # They typically aren't installed, but it's good to make sure they stay
    # that way.
    sudo pacman -R nano youtube-dl 2> /dev/null

    rm -rf \
        "$HOME"/mpv-youtube-quality \
        "$HOME"/vim \
        "$HOME"/soulseekqt \
        "$HOME"/ranger \
        "$HOME"/tor-browser \
        "$HOME"/RIS \
        "$HOME"/ttf-ms-fonts \
        "$HOME"/libxft-bgra
}

install_4chan_x() {
    wget -P "${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey" https://www.4chan-x.net/builds/4chan-X.user.js
}

install_grub() {
    sudo su root -c "grub-install $INSTALLATION_DRIVE"
    sudo su root -c "grub-mkconfig -o /boot/grub/grub.cfg"
}

set_locale() {
    # Enable English locale.
    sudo su root -c "sed 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' -i /etc/locale.gen"
    sudo su root -c "sed 's/#en_US ISO-8859-1/en_US ISO-8859-1/g' -i /etc/locale.gen"

    # Enable Japanese locale.
    sudo su root -c "sed 's/#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/g' -i /etc/locale.gen"

    # Enable Korean locale.
    sudo su root -c "sed 's/#ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/g' -i /etc/locale.gen"

    # Set main system locale.
    sudo su root -c "echo \"LANG=en_US.UTF-8\" > /etc/locale.conf"
    sudo su root -c "locale-gen"
}

install_mpv_youtube_quality() {
    cd "$HOME"/mpv-youtube-quality || return

    cp youtube-quality.lua "$HOME"/.config/mpv/scripts/youtube-quality.lua

    cp youtube-quality.conf "$HOME"/.config/mpv/script-opts/youtube-quality.conf
}

install_vim_plug() {
    curl -fLo "$HOME"/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_vim_py3() {
    cd "$HOME"/vim || return

    ./configure \
        --enable-perlinterp \
        --enable-python3interp \
        --enable-rubyinterp \
        --enable-cscope \
        --enable-gui=auto \
        --enable-gtk2-check \
        --enable-gnome-check \
        --with-features=huge \
        --enable-multibyte \
        --with-x \
        --with-compiledby='xorpd' \
        --with-python3-config-dir=/usr/lib/python3.4/config-3.4m-x86_64-linux-gnu \
        --prefix=/opt/vim74

    make && sudo make install
    sudo ln -s /opt/vim74/bin/vim vim-py3
}

install_via_pacman() {
    # No need for Nvidia drivers if on a laptop, or light (brightness
    # controller) if on a desktop.
    case "$DEVICE" in
        laptop | e550 | e570) PACMAN_PROGS+=(light) ;;
        fx4100) PACMAN_PROGS+=(nvidia) ;;

        # Using a different set of programs for servers.
        server)
			sudo pacman -Syu curl fuse imagemagick nginx ntfs-3g php-fpm ranger rsync sshfs unzip wget
            return
        ;;
    esac

    sudo pacman -Syu "${PACMAN_PROGS[@]}"
}

change_dwm_pulse_bind() {
    case "$DEVICE" in
        laptop | e550 | e570) FIND=1; CHANGE_TO=0 ;;
        desktop | fx4100) FIND=0; CHANGE_TO=1 ;;
    esac

    # Disgusting, but it works, and works well.
    sed "s/\"pactl\",\ \"set-sink-volume\",\ \"$FIND\",\ \"-1%\",\ NULL/\"pactl\",\ \"set-sink-volume\",\ \"$CHANGE_TO\",\ \"-1%\",\ NULL/g" -i "$HOME/Documents/Repositories/$DWM_REPO/config.h"

    sed "s/\"pactl\",\ \"set-sink-volume\",\ \"$FIND\",\ \"+1%\",\ NULL/\"pactl\",\ \"set-sink-volume\",\ \"$CHANGE_TO\",\ \"+1%\",\ NULL/g" -i "$HOME/Documents/Repositories/$DWM_REPO/config.h"

    sed "s/\"pactl\",\ \"set-sink-mute\",\ \"$FIND\",\ \"toggle\",\ NULL/\"pactl\",\ \"set-sink-mute\",\ \"$CHANGE_TO\",\ \"toggle\",\ NULL/g" -i "$HOME/Documents/Repositories/$DWM_REPO/config.h"
}

# There's this weird audio click issue caused by Intel's bad audio management
# stuff. I mitigate this by always having the audio channel on on laptops.
disable_pulse_idle() {
    case "$DEVICE" in
        laptop | e550 | e570)
            sudo su root -c "sed \"s/load-module\ module-suspend-on-idle/#load-module\ module-suspend-on-idle/g\" -i /etc/pulse/default.pa"
        ;;
    esac
}

download_repos() {
    local INDEX_COUNTER=0

    SRCS=(\
        "https://github.com/jgreco/mpv-youtube-quality"
        "https://aur.archlinux.org/tor-browser.git"
        "https://github.com/vim/vim"
        "https://aur.archlinux.org/soulseekqt.git"
        "https://github.com/ranger/ranger"
        "https://aur.archlinux.org/ttf-ms-fonts.git"
        "https://aur.archlinux.org/libxft-bgra.git"\
    )

    DESTS=(\
        "$HOME/mpv-youtube-quality"
        "$HOME/tor-browser"
        "$HOME/vim"
        "$HOME/soulseekqt"
        "$HOME/ranger"
        "$HOME/ttf-ms-fonts"
        "$HOME/libxft-bgra"\
    )

    git clone ${DWM_REPO[0]} ${DWM_REPO[1]}
    git clone ${DOTFILES_REPO[0]} "$HOME"/${DOTFILES_REPO[1]}
    git clone ${ST_REPO[0]} ${ST_REPO[1]}
    git clone ${DWM_BAR_REPO[0]} ${DWM_BAR_REPO[1]}
    git clone ${SCRIPS_REPO[0]} ${SCRIPTS_REPO[1]}
    git clone https://github.com/rethyxyz/RIS "$HOME/RIS"
    git clone https://github.com/rethyxyz/futascrap $HOME/futascrap
    git clone ${RB_REPO[0]} ${RB_REPO[1]}
    git clone ${YT2RSS_REPO[0]} ${YT2RSS_REPO[1]}
    #git clone git@rethy.xyz:/srv/git/ba2rc "$HOME/Documents/Repositories/ba2rc"
    #git clone git@rethy.xyz:/srv/git/wallpapers "$HOME/Documents/Repositories/wallpapers"
    #git clone git@rethy.xyz:/srv/git/rethy.xyz "$HOME/Documents/Repositories/rethy.xyz"

    while [ "$INDEX_COUNTER" -lt 7 ]; do
        git clone \
            "${SRCS[$INDEX_COUNTER]}" \
            "${DESTS[$INDEX_COUNTER]}"

        INDEX_COUNTER=$((INDEX_COUNTER+1))
    done
}

install_ms_fonts() {
    cd "$HOME"/ttf-ms-fonts || return
    makepkg -si
}

set_time() {
    # Sync time with Network Time Protocol.
    sudo timedatectl set-ntp 1
    sudo su root -c "ln -sf /usr/share/zoneinfo/$ZONE /etc/localtime"
}

setup_root_files() {
    sudo chmod 777 /etc/inputrc
    sudo chown -R "$USER":wheel /etc/inputrc
    sudo touch /etc/modprobe.d/nobeep.conf
}

create_dirs() {
    mkdir -p \
        "$HOME"/Music \
        "$HOME"/Videos \
        "$HOME"/.Trash \
        "$HOME"/Pictures/Wallpapers \
        "$HOME"/Pictures/Screenshots \
        "$HOME"/Pictures/Assorted \
        "$HOME"/Downloads \
        "$HOME"/.vim/undodir \
        "$HOME"/.config/mpd/playlists \
        "$HOME"/.config/mpv/scripts \
        "$HOME"/.config/mpv/script-opts \
        "$HOME"/Documents/Repositories \
        "$HOME"/Documents/Notes \
        "$HOME"/Documents/Books

    # No other directories needed for ThinkPads.
    [ "$DEVICE" = "fx4100" ] && mkdir -p "$HOME"/Backup0 "$HOME"/Backup1
}

replicate_files() {
    for FILE in ${DOTFILES_TO_GRAB[@]}; do
        cp ${DOTFILES_REPO[1]}/$FILE "$HOME"/$FILE
    done
}

replicate_dirs() {
    cp -R ${DOTFILES_REPO[1]}/.config/* "$HOME"/.config/
    cp -R ${DOTFILES_REPO[1]}/.newsboat/ "$HOME"/
    cp -R ${DOTFILES_REPO[1]}/.fonts/ "$HOME"/
}

# This function, quite simply, generates a proper xinitrc for you. Overall,
# easier than having to manage even more files in my dotfiles repository.
generate_xinitrc() {
    {
    printf "#!/bin/sh\n"
    printf "#++++++++++#\n"
    printf "# Settings #\n"
    printf "#++++++++++#\n\n"

    printf "setxkbmap -option caps:escape &\n"
    } > "$HOME"/.xinitrc

    # Disable TrackBad if laptop. Disable mouse acceleration if desktop.
    case "$DEVICE" in
        desktop)
            printf "xinput --set-prop 'SINOWEALTH Wired Gaming Mouse' 'libinput Accel Speed' -1 &\n" >> "$HOME/.xinitrc"
        ;;

        fx4100)
            {
            printf "xinput --set-prop 'SINOWEALTH Wired Gaming Mouse' 'libinput Accel Speed' -1 &\n"
            printf "xrandr --output HDMI-0 --primary &\n"
            } >> "$HOME/.xinitrc"
        ;;

        laptop)
            printf "st -e own_bright.sh &\n" >> "$HOME/.xinitrc"
        ;;

        e550)
            {
            printf "st -e own_bright.sh &\n"
            printf "xinput disable \"AlpsPS/2 ALPS DualPoint TouchPad\" &\n"
            } >> "$HOME/.xinitrc"
        ;;

        e570)
            {
            printf "st -e own_bright.sh &\n"
            printf "xinput --disable \"SynPS/2 Synaptics TouchPad\" &\n"
            printf "xinput --set-prop \"TPPS/2 IBM TrackPoint\" \"libinput Accel Speed\" -0.7 &\n"
            } >> "$HOME/.xinitrc"
        ;;
    esac

    {
    printf "{ \"\$HOME\"/.fehbg && picom; } &\n"
    printf "xset r rate 200 50 &\n\n"

    printf "#+++++++++#\n"
    printf "# Daemons #\n"
    printf "#+++++++++#\n\n"

    printf "mpd &\n"
    printf "dunst &\n"
    printf "picom &\n"
    printf "dwmbar &\n\n"

    printf "#++++++++++#\n"
    printf "# Programs #\n"
    printf "#++++++++++#\n\n"

    printf "firefox &\n"
    printf "st -e ncmpcpp &\n"
    printf "st -e newsboat &\n"
    printf "st -t irssi -e irssi &\n"
    printf "tor-browser &\n"
    printf "discord &\n\n"

    printf "exec dwm\n"
    } >> "$HOME"/.xinitrc

    printf "set show-mode-in-prompt on\n" >> /etc/inputrc
}

enable_pulseaudio() {
    sudo pulseaudio --daemonize
}

generate_nobeep() {
    # nobeep.conf.
    #
    # Disables annoying motherboard speaker. This is only really needed for
    # laptops, but I'm doing it on all devices, just in case.
    sudo su root -c "printf 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf"
}

install_tor_browser() {
    cd "$HOME"/tor-browser || return
    gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
    makepkg -si
}

#
# Main
#
# If root, alert and quit. This is the POSIX way to check for root.
[[ "$(id -u)" -eq 0 ]] && {
    printf "Installation cannot be conducted by root user\n";
    printf "Change to non-root user, and rerun %s.\n" "$0";
    exit 1;
}

# If $HOSTNAME unset, alert and quit.
[[ "$HOSTNAME" = "unset" ]] && {
    printf "HOSTNAME variable unset (value \"%s\").\n" "$HOSTNAME";
    printf "Set \$HOSTNAME variable and rerun %s.\n" "$0";
    exit 1;
}

# If no drive file, alert and quit.
[[ ! -e "$INSTALLATION_DRIVE" ]] && {
    printf "Drive \"%s\" doesn't exist\n" "$INSTALLATION_DRIVE";
    printf "Fix \$INSTALLATION_DRIVE variable and rerun %s.\n" "$0";
    exit 1;
}

[[ "$INSTALLATION_DRIVE" = "unset" ]] || [[ ! "$INSTALLATION_DRIVE" ]] && {
    printf "\$INSTALLATION_DRIVE is set to \"%s\".\n" "$INSTALLATION_DRIVE"
    printf "Fix \$INSTALLATION_DRIVE variable and rerun.\n"
}

# If dotfiles repo exists, remove.
[ -d "$HOME/Documents/Repositories/$DOTFILES_REPO" ] && {
    rm -rf "$HOME"/Documents/Repositories/"$DOTFILES_REPO"_REPO || sudo !!;
}

# If DEVICE var not equal to something other than laptop or desktop, quit.
case "${DEVICE,,}" in
    laptop) DEVICE="laptop" ;;
    server) DEVICE="server" ;;
    desktop) DEVICE="desktop" ;;
    thinkpad-e550 | e550) DEVICE="e550" ;;
    thinkpad-e570 | e570) DEVICE="e570" ;;
    fx4100) DEVICE="fx4100" ;;
    *)
        printf "\"%s\" is not a valid device.\n" "$DEVICE"
        printf "Set \$DEVICE variable and rerun %s.\n" "$0"
        exit 1
    ;;
esac

#
# Here, you can add or remove functions where you see fit.
#
# Note, this $DEVICE thing to exclude and include functions is redundant, but
# I'll fix it in the future.

install_grub

set_locale
set_hostname
set_time

configure_git
configure_pacman
create_dirs
download_repos
set_home_perms
setup_root_files

[ ! "$DEVICE" = "server" ] && { \
generate_xinitrc
enable_pulseaudio
generate_nobeep
}

replicate_files
replicate_dirs

install_via_pacman
[ ! "$DEVICE" = "server" ] && { \
install_4chan_x
install_emoji_support
install_mpv_youtube_quality
install_ms_fonts
install_soulseek
install_tor_browser
install_from_pip
install_vim_plug
install_vim_py3

change_dwm_pulse_bind
}

clean_up

enable_services

set_home_perms

[ ! "$DEVICE" = "server" ] && { \
compile_ranger
compile_dwm
compile_st

disable_pulse_idle
}

# Generate (ranger) ~/.config/ranger/rc.conf from .bash_aliases.
"$HOME"/Documents/Repositories/ba2rc/ba2rc > "$HOME"/.config/ranger/rc.conf

exit 0