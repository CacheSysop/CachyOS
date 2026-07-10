function __fcnf_sudo_inner_cmd --argument-names seg
    # Receives a pipeline segment whose first token is "sudo" and returns
    # the actual command (first non-flag arg), or nothing if there isn't one.
    # Shared between __fcnf_preexec (batch) and the sudo wrapper function.
    set -l tokens (string split ' ' -- (string replace -ar ' +' ' ' -- (string trim -- $seg)))
    set -l skip_next 0
    # Skip tokens[1] = "sudo" (caller has already validated).
    for i in (seq 2 (count $tokens))
        set -l arg $tokens[$i]
        test -z "$arg"; and continue
        if test $skip_next -eq 1
            set skip_next 0
            continue
        end
        if string match -q -- '-*' $arg
            # Short flags that consume the next arg: -C -D -g -p -r -t -T -u
            string match -qr '^-[CDgprtTu]$' -- $arg; and set skip_next 1
            continue
        end
        echo $arg
        return
    end
end
