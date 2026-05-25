function __fcnf_prompt --argument-names layout pkg
    switch $layout
        case minimal
            echo (set_color --bold blue)"::"(set_color normal)" "(set_color --bold)(__fcnf_i18n prompt_minimal)(set_color normal)
        case '*'
            echo (set_color --bold blue)"::"(set_color normal)" "(set_color --bold)(__fcnf_i18n prompt_single)(set_color normal)
    end
end
