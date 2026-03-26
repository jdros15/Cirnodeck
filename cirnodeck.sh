#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║              CirnoDeck – Package Manager                 ║
# ║         webkit2gtk-4.1 installer / uninstaller           ║
# ╚══════════════════════════════════════════════════════════╝

set -euo pipefail

PACKAGE="webkit2gtk-4.1"
APP_NAME="CirnoDeck"
ERR_FILE=$(mktemp /tmp/cirnodeck_err.XXXXXX)

# ── Graphical askpass helper ──────────────────────────────────────────
# Writes a tiny script that zenity uses to prompt for the sudo password.
# sudo -A calls this instead of trying to read from a terminal.
ASKPASS_SCRIPT=$(mktemp /tmp/cirnodeck_askpass.XXXXXX)
cat > "$ASKPASS_SCRIPT" <<'ASKEOF'
#!/bin/bash
zenity --password --title="CirnoDeck · Authentication" --width=360 2>/dev/null
ASKEOF
chmod +x "$ASKPASS_SCRIPT"
export SUDO_ASKPASS="$ASKPASS_SCRIPT"

trap 'rm -f "$ERR_FILE" "$ASKPASS_SCRIPT"' EXIT

# ── Colors / markup helpers ───────────────────────────────────────────
title_markup()   { echo "<span font='14' weight='bold'>$1</span>"; }
package_markup() { echo "<tt><b>$PACKAGE</b></tt>"; }
dim()            { echo "<span alpha='70%'>$1</span>"; }

# ── Ensure zenity is available ────────────────────────────────────────
if ! command -v zenity &>/dev/null; then
    # No GUI yet, fall back to terminal sudo for this one bootstrap step
    echo "[$APP_NAME] zenity not found – installing..."
    sudo steamos-readonly disable
    if ! sudo pacman -Sy --noconfirm zenity; then
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
        sudo pacman-key --populate holo
        sudo pacman -Sy --noconfirm zenity
    fi
    sudo steamos-readonly enable
fi

# ── Password check ───────────────────────────────────────────────────
# On a fresh Steam Deck the deck user has no password, so sudo will fail
# even with an askpass helper. Detect this and prompt them to set one.
has_password() {
    # passwd -S shows the account status without needing sudo.
    # The second field is 'P' (password set), 'L' (locked), or 'NP' (no password).
    local status
    status=$(passwd -S 2>/dev/null | awk '{print $2}')
    [[ "$status" == "P" ]]
}

ensure_password_set() {
    if has_password; then return 0; fi

    zenity --info \
        --title="$APP_NAME  ·  Setup Required" \
        --text="$(title_markup 'No password set')\n\nYour Steam Deck user has no password yet.\n$APP_NAME needs one to run sudo commands.\n\n$(dim 'A terminal will open for you to set a password.\nType your new password twice when prompted.')" \
        --ok-label="  Open Terminal  " \
        --width=440 --height=180 2>/dev/null || exit 0

    # Launch a terminal with passwd; konsole is available on SteamOS
    if command -v konsole &>/dev/null; then
        konsole --hold -e bash -c 'passwd; echo; echo "You can close this window now."'
    elif command -v xterm &>/dev/null; then
        xterm -hold -e bash -c 'passwd; echo; echo "You can close this window now."'
    else
        zenity --error \
            --title="$APP_NAME  ·  No Terminal Found" \
            --text="Could not find a terminal emulator.\n\nPlease open a terminal manually and run: $(dim 'passwd')" \
            --width=400 2>/dev/null
        exit 1
    fi

    # Re-check after they set it
    if ! has_password; then
        zenity --error \
            --title="$APP_NAME  ·  Still No Password" \
            --text="A password still doesn't appear to be set.\nPlease try running the script again after setting one with $(dim 'passwd') in a terminal." \
            --width=440 2>/dev/null
        exit 1
    fi
}

ensure_password_set

# ── Package status check ──────────────────────────────────────────────
is_installed() { pacman -Q "$PACKAGE" &>/dev/null; }

# ── Piped progress dialog ─────────────────────────────────────────────
# Runs a shell function in a subshell, pipes its stdout into zenity
# --progress so each line updates the visible label. Returns the
# function's real exit code via a temp file.
STATUS_FILE=$(mktemp /tmp/cirnodeck_status.XXXXXX)
trap 'rm -f "$ERR_FILE" "$ASKPASS_SCRIPT" "$STATUS_FILE"' EXIT

with_progress() {
    local dialog_title="$1"
    local intro_msg="$2"
    local fn="$3"

    (
        export SUDO_ASKPASS="$ASKPASS_SCRIPT"
        "$fn"
        echo $? > "$STATUS_FILE"
    ) 2>"$ERR_FILE" | {
        # Prefix each pacman output line with # so zenity treats it as
        # a label update, and prepend a percentage to keep pulsate happy
        echo "0"
        echo "# $intro_msg"
        while IFS= read -r line; do
            # Strip ANSI color codes pacman sometimes emits
            clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
            [[ -n "$clean" ]] && echo "# $clean"
        done
        echo "100"
    } | zenity --progress \
        --title="$APP_NAME  ·  $dialog_title" \
        --text="$intro_msg" \
        --pulsate \
        --auto-close \
        --no-cancel \
        --width=520 \
        --height=140 \
        2>/dev/null

    return "$(cat "$STATUS_FILE" 2>/dev/null || echo 1)"
}

# ── Install logic ─────────────────────────────────────────────────────
do_install() {
    echo "Disabling read-only filesystem..."
    sudo -A steamos-readonly disable || return 1

    echo "Syncing package database..."
    if ! sudo -A pacman -Sy --noconfirm "$PACKAGE"; then
        echo "Key issue detected – reinitialising keyring..."
        sudo -A pacman-key --init            || true
        sudo -A pacman-key --populate archlinux || true
        sudo -A pacman-key --populate holo   || true
        echo "Retrying installation..."
        sudo -A pacman -Sy --noconfirm "$PACKAGE" || {
            sudo -A steamos-readonly enable
            return 1
        }
    fi

    echo "Re-enabling read-only filesystem..."
    sudo -A steamos-readonly enable
    return 0
}

# ── Uninstall logic ───────────────────────────────────────────────────
do_uninstall() {
    echo "Disabling read-only filesystem..."
    sudo -A steamos-readonly disable || return 1

    echo "Removing package and dependencies..."
    if ! sudo -A pacman -Rns --noconfirm "$PACKAGE"; then
        sudo -A steamos-readonly enable
        return 1
    fi

    echo "Re-enabling read-only filesystem..."
    sudo -A steamos-readonly enable
    return 0
}

# ── UI helpers ────────────────────────────────────────────────────────
show_info() {
    zenity --info \
        --title="$APP_NAME" \
        --text="$1" \
        --width=400 --height=100
}

show_error() {
    zenity --error \
        --title="$APP_NAME  ·  Error" \
        --text="$1" \
        --width=460 --height=160
}

# ── Main loop ─────────────────────────────────────────────────────────
while true; do

    # Build status line shown in the menu
    if is_installed; then
        STATUS_LINE="$(dim 'Status:')  ✅ $(dim 'installed')"
        INSTALL_LABEL="🔄   Reinstall    $PACKAGE"
        UNINSTALL_LABEL="🗑️    Uninstall   $PACKAGE"
    else
        STATUS_LINE="$(dim 'Status:')  ⚪ $(dim 'not installed')"
        INSTALL_LABEL="🔧   Install      $PACKAGE"
        UNINSTALL_LABEL="🗑️    Uninstall   $PACKAGE  (not installed)"
    fi

    CHOICE=$(zenity --list \
        --title="$APP_NAME" \
        --text="$(title_markup "$APP_NAME")\n$(package_markup) package manager for Steam Deck\n\n$STATUS_LINE\n" \
        --column="option" \
        "$INSTALL_LABEL" \
        "$UNINSTALL_LABEL" \
        --hide-header \
        --ok-label="  Run  " \
        --cancel-label="  Exit  " \
        --width=520 --height=280 \
        2>/dev/null) || break   # Exit on Cancel / window close

    # Nothing selected, loop back silently
    [[ -z "$CHOICE" ]] && continue

    # ── Install branch ────────────────────────────────────────────────
    if [[ "$CHOICE" == *"Install"* ]]; then

        if is_installed; then
            zenity --question \
                --title="$APP_NAME  ·  Reinstall?" \
                --text="$(package_markup) is already installed.\n\nForce a reinstall anyway?" \
                --ok-label="  Yes, Reinstall  " \
                --cancel-label="  Cancel  " \
                --width=420 --height=120 2>/dev/null || continue
        fi

        if with_progress "Installing" \
            "Installing $(package_markup)..." \
            do_install; then
            show_info "✅  $(package_markup) installed successfully."
        else
            ERR=$(cat "$ERR_FILE")
            show_error "❌  Installation failed.\n\n$(dim "$ERR")"
        fi

    # ── Uninstall branch ──────────────────────────────────────────────
    elif [[ "$CHOICE" == *"Uninstall"* ]]; then

        if ! is_installed; then
            show_info "$(package_markup) is not currently installed.\nNothing to remove."
            continue
        fi

        zenity --question \
            --title="$APP_NAME  ·  Confirm Removal" \
            --text="Remove $(package_markup) from this system?\n\n$(dim 'Dependent packages will also be removed.')" \
            --ok-label="  Yes, Remove  " \
            --cancel-label="  Cancel  " \
            --width=420 --height=120 2>/dev/null || continue

        if with_progress "Uninstalling" \
            "Removing $(package_markup)..." \
            do_uninstall; then
            show_info "✅  $(package_markup) removed successfully."
        else
            ERR=$(cat "$ERR_FILE")
            show_error "❌  Uninstall failed.\n\n$(dim "$ERR")"
        fi

    fi

done

echo "[$APP_NAME] Bye!"
