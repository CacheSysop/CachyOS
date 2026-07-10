function __fcnf_install
    # Wraps `sudo pacman -S --needed $argv` with raw-mode safe TTY handling
    # and consistent success/failure reporting. Returns pacman's exit status.
    set -l pacman_args -S --needed
    # Listener in conf.d only validates true|false — keep the same contract here.
    test "$fcnf_pacman_noconfirm" = true; and set -a pacman_args --noconfirm

    set -l stty_state (stty -g 2>/dev/null)
    stty sane 2>/dev/null
    sudo pacman $pacman_args $argv
    set -l rc $status
    test -n "$stty_state"; and stty $stty_state 2>/dev/null

    echo ""
    if test $rc -eq 0
        echo "  "(set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n install_success)
    else
        echo "  "(set_color --bold red)"✗"(set_color normal)" "(__fcnf_i18n install_failed)
    end
    echo ""
    return $rc
end
