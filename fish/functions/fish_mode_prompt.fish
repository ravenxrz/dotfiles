function fish_mode_prompt --description 'Suppress the default vi mode indicator'
    # The ys-style prompt (fish_prompt) shows no vi-mode text, matching the zsh
    # ys theme. Leaving this empty keeps the leading blank line clean under
    # fish_vi_key_bindings. Cursor shape still changes per mode.
end
