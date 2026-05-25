function fish_command_not_found
    # Master kill-switch: replicates the snippet from /usr/share/doc/pkgfile/
    # command-not-found.fish (package suggestion without prompt) and falls back
    # to fish default when there is no match. Equivalent behavior to an Arch
    # without our plugin, but with the pkgfile snippet sourced.
    if set -q fcnf_enabled; and test "$fcnf_enabled" = false
        set -l pkgs (pkgfile -bv -- "$argv[1]" 2>/dev/null)
        if test (count $pkgs) -gt 0
            printf '%s may be found in the following packages:\n' "$argv[1]"
            printf '  %s\n' $pkgs
            return
        end
        __fish_default_command_not_found_handler $argv
        return
    end

    if set -q __fcnf_handled; and contains -- $argv[1] $__fcnf_handled
        # preexec already prompted/installed/cancelled this — don't re-ask.
        # Cleanup is automatic on next preexec; leaving the list intact lets
        # other skipped commands in the same pipeline find themselves here too.
        return 127
    end

    if not command -q pkgfile
        echo (__fcnf_i18n cmd_not_found)": $argv[1]"
        echo (__fcnf_i18n pkgfile_hint)
        return
    end

    if not test -f /var/cache/pkgfile/.db_version
        echo (__fcnf_i18n cmd_not_found)": $argv[1]"
        echo ""
        echo "  "(set_color yellow)"⚠"(set_color normal)" "(__fcnf_i18n cache_not_init)
        echo "    "(__fcnf_i18n cache_init_cmd)" "(set_color --bold)"sudo pkgfile -u"(set_color normal)
        echo "    "(__fcnf_i18n cache_keep_updated)" "(set_color --bold)"sudo systemctl enable --now pkgfile-update.timer"(set_color normal)
        return
    end

    set -l matches (pkgfile -b $argv[1] 2>/dev/null)
    if test (count $matches) -eq 0
        echo (__fcnf_i18n cmd_not_found)": $argv[1]"
        return
    end

    set -l parts (string split "/" $matches[1])
    set -l repo $parts[1]
    set -l pkg $parts[2]

    set -l layout compact
    test -n "$fcnf_layout"; and set layout $fcnf_layout

    __fcnf_print $layout $argv[1] $repo $pkg $matches

    # Don't block / steal stdin if invoked inside a pipe.
    test -t 0; or return 127

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
            and $argv
        case '*'
            echo (__fcnf_i18n op_cancelled)
    end
end
