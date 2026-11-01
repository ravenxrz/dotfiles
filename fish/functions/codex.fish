function codex
    set -l cwd (pwd)
    sudo -u zhangxingrui.leo env \
        CODEX_ORIG_CWD="$cwd" \
        https_proxy="http://sys-proxy-rd-relay.byted.org:8118" \
        http_proxy="http://sys-proxy-rd-relay.byted.org:8118" \
        no_proxy="byted.org,.byted.org,*.byted.org,bytedance.net,.bytedance.net,*.bytedance.net,10.*.*.*,127.*.*.*" \
        zsh -lc 'cd -- "$CODEX_ORIG_CWD" && exec /home/zhangxingrui.leo/.local/bin/codex "$@"' _ $argv
end
