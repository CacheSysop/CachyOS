function fcnf --description 'fish-pkg-suggest-arch control'
    set -l n (count $argv)

    if test $n -eq 0
        __fcnf_help
        return
    end

    if test $n -eq 1
        switch $argv[1]
            case on
                __fcnf_apply enabled true
            case off
                __fcnf_apply enabled false
            case default
                __fcnf_apply enabled ''
            case status
                __fcnf_status
            case preview
                __fcnf_preview_layouts
            case help -h --help
                __fcnf_help
            case '*'
                echo "fcnf: unknown command '$argv[1]'" >&2
                __fcnf_help >&2
                return 1
        end
        return
    end

    if test $n -eq 2
        set -l feature $argv[1]
        set -l value $argv[2]
        switch $feature
            case layout
                switch $value
                    case compact classic minimal
                        __fcnf_apply layout $value
                    case default
                        __fcnf_apply layout ''
                    case '*'
                        echo "fcnf layout: invalid value '$value'. Use compact, classic, minimal, or default" >&2
                        return 1
                end
            case pacman
                switch $value
                    case auto
                        __fcnf_apply pacman_noconfirm true
                    case manual
                        __fcnf_apply pacman_noconfirm false
                    case default
                        __fcnf_apply pacman_noconfirm ''
                    case '*'
                        echo "fcnf pacman: invalid value '$value'. Use auto, manual, or default" >&2
                        return 1
                end
            case batch
                switch $value
                    case on
                        __fcnf_apply batch_mode true
                    case off
                        __fcnf_apply batch_mode false
                    case default
                        __fcnf_apply batch_mode ''
                    case '*'
                        echo "fcnf batch: invalid value '$value'. Use on, off, or default" >&2
                        return 1
                end
            case sudo
                switch $value
                    case on
                        __fcnf_apply sudo_wrapper true
                    case off
                        __fcnf_apply sudo_wrapper false
                    case default
                        __fcnf_apply sudo_wrapper ''
                    case '*'
                        echo "fcnf sudo: invalid value '$value'. Use on, off, or default" >&2
                        return 1
                end
            case '*'
                echo "fcnf: unknown feature '$feature'" >&2
                __fcnf_help >&2
                return 1
        end
        return
    end

    echo "fcnf: too many arguments" >&2
    __fcnf_help >&2
    return 1
end

function __fcnf_apply --argument-names var val
    # Sentinel BEFORE the var: handlers only echo in the origin session.
    set -U __fcnf_origin_pid $fish_pid
    if test -z "$val"
        set -e -U fcnf_$var
    else
        set -U fcnf_$var $val
    end
end

function __fcnf_help
    echo "Usage:"
    echo "  fcnf on | off | default       Master kill-switch"
    echo "  fcnf status                   Show current configuration"
    echo "  fcnf preview                  Show all three layouts"
    echo "  fcnf help                     Show this message"
    echo ""
    echo "  fcnf layout compact|classic|minimal|default"
    echo "  fcnf pacman auto|manual|default"
    echo "  fcnf batch  on|off|default"
    echo "  fcnf sudo   on|off|default"
end

function __fcnf_status
    set -l fmt "  %-8s %s\n"
    printf $fmt enabled (__fcnf_status_bool fcnf_enabled            on    off    on)
    printf $fmt layout  (__fcnf_status_layout)
    printf $fmt pacman  (__fcnf_status_bool fcnf_pacman_noconfirm   auto  manual manual)
    printf $fmt batch   (__fcnf_status_bool fcnf_batch_mode         on    off    on)
    printf $fmt sudo    (__fcnf_status_bool fcnf_sudo_wrapper       on    off    on)
end

function __fcnf_status_bool --argument-names name trueval falseval defval
    if not set -q $name
        echo "$defval (default)"
        return
    end
    switch $$name
        case true
            echo $trueval
        case false
            echo $falseval
        case '*'
            echo "$$name (invalid)"
    end
end

function __fcnf_status_layout
    if not set -q fcnf_layout
        echo "compact (default)"
        return
    end
    switch $fcnf_layout
        case compact classic minimal
            echo $fcnf_layout
        case '*'
            echo "$fcnf_layout (invalid)"
    end
end

function __fcnf_preview_layouts
    if not command -q expac
        echo (__fcnf_i18n expac_missing)
        return 1
    end

    set -l demo_cmd pacman
    set -l demo_repo core
    set -l demo_pkg pacman

    for layout in compact classic minimal
        echo (set_color --bold)"─── Layout: $layout ───"(set_color normal)
        echo ""
        __fcnf_print $layout $demo_cmd $demo_repo $demo_pkg "$demo_repo/$demo_pkg"
        echo (__fcnf_prompt $layout $demo_pkg)
        echo ""
        echo ""
    end

    echo (__fcnf_i18n preview_choose)" "(set_color --bold)"fcnf layout <compact|classic|minimal>"(set_color normal)
end
