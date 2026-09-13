source /usr/share/cachyos-fish-config/cachyos-config.fish

if command -q zoxide
    zoxide init fish | source
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
