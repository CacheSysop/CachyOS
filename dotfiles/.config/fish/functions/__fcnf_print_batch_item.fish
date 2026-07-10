function __fcnf_print_batch_item --argument-names idx cmd repo pkg w_cmd w_pkg ver size_bytes desc
    set -l size ""
    if test -n "$size_bytes"; and test "$size_bytes" -gt 0 2>/dev/null
        set size (numfmt --to=iec --suffix=B $size_bytes)
    end

    set -l ver_pad 12
    set -l col_idx (string pad -w 2 -- $idx)
    set -l col_cmd (string pad -rw $w_cmd -- $cmd)
    set -l col_pkg (string pad -rw $w_pkg "$repo/$pkg")
    set -l col_ver (string pad -rw $ver_pad "v$ver")

    echo "   "$col_idx"  "(set_color --bold red)$col_cmd(set_color normal)" "(set_color --bold cyan)"→"(set_color normal)"  "(set_color blue)$col_pkg(set_color normal)"  "(set_color magenta)$col_ver(set_color normal)"  "(set_color yellow)$size(set_color normal)

    if test -n "$desc"
        echo "       "(set_color brblack)"└─ "(string sub -l 70 -- $desc)(set_color normal)
    end
end
