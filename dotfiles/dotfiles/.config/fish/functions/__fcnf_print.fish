function __fcnf_print --argument-names layout cmd repo pkg
    set -l matches $argv[5..]

    set -l info (expac -S --timefmt='%d/%m/%Y' '%u\t%m\t%v\t%b\t%p\t%d\t%k' $pkg 2>/dev/null)
    set -l fields (string split \t -- $info)
    set -l pkg_url $fields[1]
    set -l pkg_size_bytes $fields[2]
    set -l pkg_version $fields[3]
    set -l pkg_builddate $fields[4]
    set -l pkg_packager $fields[5]
    set -l pkg_description $fields[6]
    set -l pkg_dlsize_bytes $fields[7]

    set -l ESC (printf '\033')
    set -l repo_url ""
    switch $repo
        case core extra multilib
            set repo_url "https://archlinux.org/packages/$repo/x86_64/$pkg/"
    end
    set -l repo_display "$repo/$pkg"
    if test -n "$repo_url"
        set repo_display "$ESC]8;;$repo_url$ESC\\$repo/$pkg$ESC]8;;$ESC\\"
    end

    set -l pkg_size ""
    if test -n "$pkg_size_bytes"; and test "$pkg_size_bytes" -gt 0 2>/dev/null
        set pkg_size (numfmt --to=iec --suffix=B $pkg_size_bytes)
    end

    set -l pkg_dlsize ""
    if test -n "$pkg_dlsize_bytes"; and test "$pkg_dlsize_bytes" -gt 0 2>/dev/null
        set pkg_dlsize (numfmt --to=iec --suffix=B $pkg_dlsize_bytes)
    end

    set -l alts_formatted
    if test (count $matches) -gt 1
        for alt in $matches[2..]
            set -l alt_pkg (string split "/" $alt)[2]
            set -l alt_ver (expac -S '%v' $alt_pkg 2>/dev/null | head -1)
            if test -n "$alt_ver"
                set -a alts_formatted "$alt (v$alt_ver)"
            else
                set -a alts_formatted $alt
            end
        end
    end

    switch $layout
        case classic
            set -l w 15
            set -l _installed (__fcnf_i18n lbl_installed)
            set -l _download (__fcnf_i18n lbl_download)

            echo (set_color --bold blue)":: "(set_color normal)(__fcnf_i18n hdr_pkg)" "(set_color --bold red)"$cmd"(set_color normal)" "(__fcnf_i18n not_installed)
            echo ""
            echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_repo))(set_color normal)(set_color blue)"$repo_display"(set_color normal)
            if test (count $alts_formatted) -gt 0
                echo "  "(string pad -rw $w "")(set_color --dim)"("(__fcnf_i18n also_in)" "(string join ", " $alts_formatted)")"(set_color normal)
            end
            test -n "$pkg_version"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_version))(set_color normal)(set_color magenta)"$pkg_version"(set_color normal)
            test -n "$pkg_description"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_desc))(set_color normal)"$pkg_description"

            set -l size_line ""
            if test -n "$pkg_size"
                set size_line "$pkg_size $_installed"
                test -n "$pkg_dlsize"; and set size_line "$size_line "(set_color --dim)"($pkg_dlsize $_download)"(set_color normal)
            else if test -n "$pkg_dlsize"
                set size_line "$pkg_dlsize $_download"
            end
            test -n "$size_line"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_size))(set_color normal)(set_color yellow)"$size_line"(set_color normal)

            test -n "$pkg_builddate"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_build))(set_color normal)"$pkg_builddate"
            test -n "$pkg_packager"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_packager))(set_color normal)"$pkg_packager"
            test -n "$pkg_url"; and echo "  "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_site))(set_color normal)(set_color cyan)"$pkg_url"(set_color normal)
            echo ""

        case minimal
            echo (set_color --bold blue)":: "(set_color normal)(__fcnf_i18n hdr_cmd)" "(set_color --bold red)"$cmd"(set_color normal)" "(__fcnf_i18n not_found)

            set -l detail ""
            test -n "$pkg_version"; and set detail "v$pkg_version"
            if test -n "$pkg_size"
                if test -n "$detail"
                    set detail "$detail, $pkg_size"
                else
                    set detail "$pkg_size"
                end
            end

            set -l line (set_color --bold blue)":: "(set_color normal)(__fcnf_i18n belongs_to)" "(set_color blue)"$repo_display"(set_color normal)
            test -n "$detail"; and set line "$line ($detail)"
            set line "$line."
            echo $line

        case '*'
            set -l w 8
            set -l pkg_line (set_color blue)"$repo_display"(set_color normal)
            test -n "$pkg_version"; and set pkg_line "$pkg_line "(set_color --dim)"(v$pkg_version)"(set_color normal)
            test -n "$pkg_size"; and set pkg_line "$pkg_line "(set_color yellow)"[$pkg_size]"(set_color normal)

            set -l build_line ""
            test -n "$pkg_builddate"; and set build_line "$pkg_builddate"
            if test -n "$pkg_packager"
                if test -n "$build_line"
                    set build_line "$build_line "(set_color --dim)"($pkg_packager)"(set_color normal)
                else
                    set build_line "$pkg_packager"
                end
            end

            echo (set_color --bold blue)":: "(set_color normal)(__fcnf_i18n hdr_cmd)" "(set_color --bold red)"$cmd"(set_color normal)" "(__fcnf_i18n not_installed)
            echo "   "(set_color --bold cyan)"↳"(set_color normal)" "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_pkg_compact))(set_color normal)"$pkg_line"
            if test (count $alts_formatted) -gt 0
                echo "     "(set_color --dim)(__fcnf_i18n also_in)" "(string join ", " $alts_formatted)(set_color normal)
            end
            test -n "$build_line"; and echo "   "(set_color --bold cyan)"↳"(set_color normal)" "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_build_compact))(set_color normal)"$build_line"
            test -n "$pkg_url"; and echo "   "(set_color --bold cyan)"↳"(set_color normal)" "(set_color --bold)(string pad -rw $w (__fcnf_i18n lbl_site_compact))(set_color normal)(set_color cyan)"$pkg_url"(set_color normal)
    end
end
