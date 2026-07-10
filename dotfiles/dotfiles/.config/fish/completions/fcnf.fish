function __fcnf_complete_layout_legacy
    set -l tokens (commandline -opc)
    contains -- fcnf_layout $tokens
end

# fcnf — main entry point
function __fcnf_no_subcommand
    set -l cmd (commandline -opc)
    test (count $cmd) -le 1
end

function __fcnf_feature_is
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2; and test "$cmd[2]" = $argv[1]
end

function __fcnf_complete_lang
    string match -q 'pt*' -- "$LANG$LC_MESSAGES"; and echo pt; or echo en
end

function __fcnf_complete_layout_values
    switch (__fcnf_complete_lang)
        case pt
            printf 'compact\tLayout compacto (default)\n'
            printf 'classic\tUma linha por campo\n'
            printf 'minimal\tEstilo pacman\n'
            printf 'default\tResetar layout\n'
        case '*'
            printf 'compact\tCompact layout (default)\n'
            printf 'classic\tOne line per field\n'
            printf 'minimal\tPacman-style output\n'
            printf 'default\tReset layout\n'
    end
end

function __fcnf_complete_pacman_values
    switch (__fcnf_complete_lang)
        case pt
            printf 'auto\tUsar --noconfirm\n'
            printf 'manual\tConfirmar no pacman\n'
            printf 'default\tResetar pacman\n'
        case '*'
            printf 'auto\tUse --noconfirm\n'
            printf 'manual\tConfirm in pacman\n'
            printf 'default\tReset pacman\n'
    end
end

function __fcnf_complete_batch_values
    switch (__fcnf_complete_lang)
        case pt
            printf 'on\tAtivar batch\n'
            printf 'off\tDesativar batch\n'
            printf 'default\tResetar batch\n'
        case '*'
            printf 'on\tEnable batch mode\n'
            printf 'off\tDisable batch mode\n'
            printf 'default\tReset batch mode\n'
    end
end

function __fcnf_complete_sudo_values
    switch (__fcnf_complete_lang)
        case pt
            printf 'on\tAtivar wrapper sudo\n'
            printf 'off\tDesativar wrapper sudo\n'
            printf 'default\tResetar sudo\n'
        case '*'
            printf 'on\tEnable sudo wrapper\n'
            printf 'off\tDisable sudo wrapper\n'
            printf 'default\tReset sudo wrapper\n'
    end
end

function __fcnf_complete_top_values
    switch (__fcnf_complete_lang)
        case pt
            printf 'on\tAtivar plugin\n'
            printf 'off\tDesativar plugin (kill-switch)\n'
            printf 'default\tResetar chave principal\n'
            printf 'status\tMostrar configuração atual\n'
            printf 'preview\tMostrar os três layouts\n'
            printf 'help\tMostrar ajuda\n'
            printf 'layout\tLayout de saída\n'
            printf 'pacman\tFlag noconfirm do pacman\n'
            printf 'batch\tModo batch para pipelines\n'
            printf 'sudo\tWrapper shadow de sudo\n'
        case '*'
            printf 'on\tEnable plugin\n'
            printf 'off\tDisable plugin (kill-switch)\n'
            printf 'default\tReset master switch\n'
            printf 'status\tShow current configuration\n'
            printf 'preview\tShow all three layouts\n'
            printf 'help\tShow help\n'
            printf 'layout\tOutput layout\n'
            printf 'pacman\tPacman noconfirm flag\n'
            printf 'batch\tBatch mode for pipelines\n'
            printf 'sudo\tShadow sudo wrapper\n'
    end
end

complete -c set -n __fcnf_complete_layout_legacy -xa '(__fcnf_complete_layout_values)'

complete -c fcnf -f

# Top-level commands
complete -c fcnf -n __fcnf_no_subcommand -xa '(__fcnf_complete_top_values)'

# Per-feature values
complete -c fcnf -n '__fcnf_feature_is layout' -xa '(__fcnf_complete_layout_values)'
complete -c fcnf -n '__fcnf_feature_is pacman' -xa '(__fcnf_complete_pacman_values)'
complete -c fcnf -n '__fcnf_feature_is batch'  -xa '(__fcnf_complete_batch_values)'
complete -c fcnf -n '__fcnf_feature_is sudo'   -xa '(__fcnf_complete_sudo_values)'
