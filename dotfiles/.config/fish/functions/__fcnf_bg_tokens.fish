function __fcnf_bg_tokens --argument-names cmdline
    # Identifies command tokens in background jobs (terminated by a single '&').
    # These need to be silenced in fish_command_not_found, otherwise they
    # conflict with job control: read receives SIGTTIN, prompt dies with
    # "Operation cancelled", parallel output overlaps.
    #
    # Parse-time strategy (more reliable than checking PGRP at runtime, which
    # fails due to a race condition with the fg→bg transition):
    #   1. Protects '&&' (not a job separator).
    #   2. Split on ';' and single '&' preserving the terminator.
    #   3. Job that ends in '&' is background.
    #   4. Inside the bg job, extract each sub-command via split on |, &&, ||.
    set -l esc (printf '\001')
    set -l mark (printf '\037')
    set -l submark (printf '\036')
    set -l protected (string replace -ar '&&' $esc -- $cmdline)

    set -l marked (string replace -ar ';' ";$mark" -- $protected)
    set marked (string replace -ar '&' "&$mark" -- $marked)

    for job in (string split $mark -- $marked)
        set job (string trim -- $job)
        test -z "$job"; and continue
        string match -q '*&' -- $job; or continue
        set job (string sub -e -1 -- $job)
        set job (string replace -ar $esc '&&' -- $job)

        set -l subs (string split $submark -- (string replace -ar '\|\||&&|\|' $submark -- $job))
        for sub in $subs
            set sub (string trim -- $sub)
            test -z "$sub"; and continue
            set -l tok (string split -m 1 ' ' -- $sub)[1]
            test -z "$tok"; and continue
            if test "$tok" = sudo
                set tok (__fcnf_sudo_inner_cmd $sub)
                test -z "$tok"; and continue
            end
            echo $tok
        end
    end
end
