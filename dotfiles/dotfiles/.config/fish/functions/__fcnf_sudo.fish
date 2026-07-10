function __fcnf_sudo
    # Belt and braces: if something inherits this function in a non-interactive context
    # (subshell, command substitution, script running inside an interactive shell),
    # leaks directly to the system sudo.
    if not status is-interactive
        command sudo $argv
        return
    end

    # Same parser as preexec uses, so that both see the same
    # "internal command" when facing exotic sudo flags.
    set -l cmd (__fcnf_sudo_inner_cmd "sudo $argv")

    # preexec already handled this command in this fish_preexec (installed or cancelled)
    # → suppress entirely. Without this, fish would run 'sudo missing_cmd' and
    # the system sudo would ask for a password before failing with 'command not found'.
    if set -q __fcnf_handled; and contains -- "$cmd" $__fcnf_handled
        return 0
    end

    # No command detected, or command already exists → direct sudo.
    if test -z "$cmd"; or type -q "$cmd"
        command sudo $argv
        return
    end

    # No pkgfile cache, we have no way to suggest → direct sudo.
    if not command -q pkgfile; or not test -f /var/cache/pkgfile/.db_version
        command sudo $argv
        return
    end

    set -l matches (pkgfile -b "$cmd" 2>/dev/null)
    if test (count $matches) -eq 0
        command sudo $argv
        return
    end

    set -l parts (string split "/" $matches[1])
    set -l repo $parts[1]
    set -l pkg $parts[2]
    set -l layout compact
    test -n "$fcnf_layout"; and set layout $fcnf_layout

    __fcnf_print $layout $cmd $repo $pkg $matches

    # No TTY (pipe/script), no way to ask → direct sudo.
    if not test -t 0
        command sudo $argv
        return
    end

    set -l confirm
    read -n 1 -P (__fcnf_prompt $layout $pkg) confirm
    or begin
        echo ""
        echo (__fcnf_i18n op_cancelled)
        return
    end
    echo ""

    switch (string lower -- $confirm)
        case '' i
            __fcnf_install $pkg
        case e r
            __fcnf_install $pkg
            and command sudo $argv
        case '*'
            echo (__fcnf_i18n op_cancelled)
    end
end
