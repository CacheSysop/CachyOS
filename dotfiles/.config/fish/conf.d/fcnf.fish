function __fcnf_preexec --on-event fish_preexec
    # Reset to empty global so set -a appends globally for this run.
    set -g __fcnf_handled

    # Master kill-switch: entire plugin out of the way.
    set -q fcnf_enabled; and test "$fcnf_enabled" = false; and return

    command -q pkgfile; or return
    test -f /var/cache/pkgfile/.db_version; or return

    set -l cmdline $argv[1]
    test -z "$cmdline"; and return

    set -l sep (printf '\037')
    set -l segments (string split $sep -- (string replace -ar '[|&;]+' $sep -- $cmdline))

    set -l keywords if else for while function begin end switch case not and or command builtin exec time set status return break continue test true false read echo printf

    # Phase 1 — pure in-memory filtering. No I/O.
    set -l seen
    set -l local_miss
    set -l sudo_disabled_present 0

    for seg in $segments
        set -l seg_trim (string trim -- $seg)
        set -l tok (string split -m 1 ' ' -- $seg_trim)[1]
        test -z "$tok"; and continue

        # sudo is a transparent prefix: descend to the real command so that
        # `sudo missing_cmd; missing_other` triggers batch mode too.
        if test "$tok" = sudo
            # Wrapper disabled: total kill-switch. Marks the line as
            # "off-limits" — any absence in other segments will also
            # be suppressed in fish_command_not_found, avoiding a hybrid UX
            # where half the line is handled and the other half fails natively.
            if set -q fcnf_sudo_wrapper; and test "$fcnf_sudo_wrapper" = false
                set sudo_disabled_present 1
                continue
            end
            set tok (__fcnf_sudo_inner_cmd $seg_trim)
            test -z "$tok"; and continue
        end

        string match -qr '^[A-Za-z_][A-Za-z0-9_+.-]*$' -- $tok; or continue
        contains -- $tok $keywords; and continue
        contains -- $tok $seen; and continue
        set -a seen $tok
        type -q $tok; and continue
        set -a local_miss $tok
    end

    set -l n_miss (count $local_miss)
    set -l n_total (count $seen)

    # Nothing missing → nothing to do.
    test $n_miss -eq 0; and return

    # Bg tokens are only silenced in the degenerate case of a solo bg command
    # ('nyancat &'). Cannot prompt (SIGTTIN), so it stays quiet. In a
    # multi-command line, the batch runs in preexec (foreground) — safe to prompt.
    set -l bg_set (__fcnf_bg_tokens $cmdline)
    if test $n_miss -eq 1; and test $n_total -eq 1; and contains -- $local_miss[1] $bg_set
        set -a __fcnf_handled $local_miss[1]
        return
    end

    # Line contains sudo with wrapper disabled → suppress everything.
    # Marks missing tokens as already handled so that fish_command_not_found
    # also stays quiet; native sudo will take care of its own message.
    if test $sudo_disabled_present -eq 1
        set -a __fcnf_handled $local_miss
        return
    end

    # Batch mode opt-out: multi-command line silences everything (no "machine gun"
    # of single prompts). Solo command falls into the normal single flow.
    if set -q fcnf_batch_mode; and test "$fcnf_batch_mode" = false
        test $n_total -ge 2; and set -a __fcnf_handled $local_miss
        return
    end

    # Solo command with 1 missing → fish_command_not_found handles it (single mode).
    # Multi-command line enters batch even with only 1 missing — the single
    # prompt would be intrusive in the middle of a pipeline.
    test $n_total -eq 1; and return

    # Phase 2 — I/O. Resolve only the locally-missing tokens via pkgfile.
    set -l miss_cmds
    set -l miss_pkgs
    set -l miss_repos
    set -l no_pkg_cmds

    for tok in $local_miss
        set -l matches (pkgfile -b $tok 2>/dev/null)
        if test (count $matches) -eq 0
            set -a no_pkg_cmds $tok
            continue
        end
        set -l parts (string split "/" $matches[1])
        set -a miss_cmds $tok
        set -a miss_repos $parts[1]
        set -a miss_pkgs $parts[2]
    end

    set -l n (count $miss_cmds)
    set -l warn_path (test (count $no_pkg_cmds) -gt 0; and echo 1; or echo 0)

    # Nothing installable → nothing to show (pure warn_path is left to
    # the native fish_command_not_found to handle case by case).
    test $n -eq 0; and return

    # Warning block — shown before the package list.
    if test $warn_path -eq 1
        echo (set_color --bold yellow)"::"(set_color normal)" "(set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n batch_warn_cmds)
        for cmd in $no_pkg_cmds
            echo "     "(set_color --bold red)$cmd(set_color normal)
        end
        echo ""
    end

    # List header — same visual structure on both paths, only the message changes.
    set -l header_msg (test $warn_path -eq 1; and __fcnf_i18n batch_available $n; or __fcnf_i18n batch_summary $n)
    echo (set_color --bold blue)"::"(set_color normal)" "(set_color --bold)$header_msg(set_color normal)
    echo ""

    set -l w_cmd 0
    set -l w_pkg 0
    for i in (seq $n)
        set -l lc (string length -- $miss_cmds[$i])
        set -l lp (string length -- "$miss_repos[$i]/$miss_pkgs[$i]")
        test $lc -gt $w_cmd; and set w_cmd $lc
        test $lp -gt $w_pkg; and set w_pkg $lp
    end

    # A single expac call for all packages — avoids N forks in the render loop.
    # We index by name because expac skips unresolved packages, which would break positional order.
    set -l meta_lines (expac -S '%n\t%v\t%m\t%d' $miss_pkgs 2>/dev/null)
    for i in (seq $n)
        set -l ver ""
        set -l size_bytes ""
        set -l desc ""
        for ml in $meta_lines
            set -l f (string split \t -- $ml)
            if test "$f[1]" = "$miss_pkgs[$i]"
                set ver $f[2]
                set size_bytes $f[3]
                set desc $f[4]
                break
            end
        end
        __fcnf_print_batch_item $i $miss_cmds[$i] $miss_repos[$i] $miss_pkgs[$i] $w_cmd $w_pkg $ver $size_bytes $desc
    end
    echo ""

    if test $warn_path -eq 1
        echo (set_color --bold yellow)"::"(set_color normal)" "(__fcnf_i18n batch_warn_fail)
        echo ""
    end

    set -l prompt_msg (test $warn_path -eq 1; and __fcnf_i18n batch_prompt_warn; or __fcnf_i18n batch_prompt)
    set -l choice
    read -P (set_color --bold blue)"::"(set_color normal)" "(set_color --bold)$prompt_msg(set_color normal) choice
    or begin
        echo ""
        echo (__fcnf_i18n op_cancelled)
        set -a __fcnf_handled $miss_cmds
        return
    end
    set choice (string trim -- $choice)

    # Cancel conditions: explicit 'c', or empty on warning path.
    if string match -qri '^c$' -- $choice; or begin test $warn_path -eq 1; and test -z "$choice"; end
        echo (__fcnf_i18n op_cancelled)
        set -a __fcnf_handled $miss_cmds
        return
    end

    # Install-all path: empty on happy path, or 't'/'a' on warning path. Early return.
    if test -z "$choice"; or string match -qri '^[ta]$' -- $choice
        __fcnf_install $miss_pkgs
        or set -a __fcnf_handled $miss_cmds
        return
    end

    # Manual selection — parse "1 2 3", "1,2,3", "1-3", or any combination.
    set -l selected
    for tok in (string split ' ' -- (string replace -ar '[, ]+' ' ' -- $choice))
        test -z "$tok"; and continue
        if string match -qr '^[0-9]+-[0-9]+$' -- $tok
            set -l range (string split '-' -- $tok)
            for i in (seq $range[1] $range[2])
                test $i -ge 1 -a $i -le $n; and set -a selected $i
            end
        else if string match -qr '^[0-9]+$' -- $tok
            test $tok -ge 1 -a $tok -le $n; and set -a selected $tok
        end
    end

    if test (count $selected) -eq 0
        echo (__fcnf_i18n op_cancelled)
        set -a __fcnf_handled $miss_cmds
        return
    end

    set -l to_install
    for i in (seq $n)
        if contains $i $selected
            set -a to_install $miss_pkgs[$i]
        else
            set -a __fcnf_handled $miss_cmds[$i]
        end
    end

    test (count $to_install) -eq 0; and return

    __fcnf_install $to_install
    or set -a __fcnf_handled $miss_cmds
end

function __fcnf_origin_is_self
    # Universal vars trigger handlers in every session. `fcnf set` saves
    # __fcnf_origin_pid before the var; only the origin session echoes feedback.
    set -q __fcnf_origin_pid; and test "$__fcnf_origin_pid" = "$fish_pid"
end

function __fcnf_on_noconfirm_change --on-variable fcnf_pacman_noconfirm
    __fcnf_origin_is_self; or return
    if not set -q fcnf_pacman_noconfirm
        echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n noconfirm_off)
        return
    end
    switch $fcnf_pacman_noconfirm
        case true
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n noconfirm_on)
        case false
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n noconfirm_off)
        case '*'
            echo (set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n noconfirm_invalid)
    end
end

function __fcnf_setup_sudo_wrapper
    # Circuit breaker: mounts or destroys the shadow `sudo` function in memory.
    # Master `fcnf_enabled=false` wins over `fcnf_sudo_wrapper`.
    # Since the autoloaded file is named __fcnf_sudo.fish, the name `sudo`
    # is never claimed by the plugin at the file level — it only exists if we
    # create it here. Erase is definitive within the session.
    if set -q fcnf_enabled; and test "$fcnf_enabled" = false
        functions --erase sudo 2>/dev/null
        return
    end
    if set -q fcnf_sudo_wrapper; and test "$fcnf_sudo_wrapper" != true
        functions --erase sudo 2>/dev/null
        return
    end
    function sudo --wraps sudo
        __fcnf_sudo $argv
    end
end

__fcnf_setup_sudo_wrapper

function __fcnf_on_sudo_wrapper_change --on-variable fcnf_sudo_wrapper
    # State mutation runs in every session; only the echo is gated.
    __fcnf_setup_sudo_wrapper
    __fcnf_origin_is_self; or return
    if not set -q fcnf_sudo_wrapper
        echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n sudo_wrapper_on)
        return
    end
    switch $fcnf_sudo_wrapper
        case true
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n sudo_wrapper_on)
        case false
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n sudo_wrapper_off)
        case '*'
            echo (set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n sudo_wrapper_invalid)
    end
end

function __fcnf_on_enabled_change --on-variable fcnf_enabled
    # Master kill-switch reacted — rebuilds the sudo function state immediately.
    __fcnf_setup_sudo_wrapper
    __fcnf_origin_is_self; or return
    if not set -q fcnf_enabled
        echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n plugin_enabled)
        return
    end
    switch $fcnf_enabled
        case true
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n plugin_enabled)
        case false
            echo (set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n plugin_disabled)
        case '*'
            echo (set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n plugin_invalid)
    end
end

function __fcnf_on_batch_mode_change --on-variable fcnf_batch_mode
    __fcnf_origin_is_self; or return
    if not set -q fcnf_batch_mode
        echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n batch_mode_on)
        return
    end
    switch $fcnf_batch_mode
        case true
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n batch_mode_on)
        case false
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n batch_mode_off)
        case '*'
            echo (set_color --bold yellow)"⚠"(set_color normal)" "(__fcnf_i18n batch_mode_invalid)
    end
end

function __fcnf_on_layout_change --on-variable fcnf_layout
    __fcnf_origin_is_self; or return
    set -q fcnf_layout; or return
    switch $fcnf_layout
        case compact classic minimal
            echo (set_color --bold green)"✓"(set_color normal)" "(__fcnf_i18n layout_changed)" "(set_color --bold)"$fcnf_layout"(set_color normal)"."
        case '*'
            echo (set_color --bold yellow)"⚠"(set_color normal)" Layout '"(set_color --bold)"$fcnf_layout"(set_color normal)"' "(__fcnf_i18n layout_invalid)
    end
end
