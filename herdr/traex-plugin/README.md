# Herdr integration for TraeX

This local TraeX plugin reports lifecycle events to the owning Herdr pane.

The `traex` shell wrapper in `shell/functions.sh` reports `idle` before the TUI
starts and releases the pane after it exits. This covers the period before
TraeX emits its first lifecycle hook. The plugin owns turn-level transitions.

State mapping:

- session start and turn stop: `idle`
- prompt submission and tool activity: `working`
- permission request: `blocked`
- session end: release the pane's agent identity

TraeX does not emit `Stop` when a turn is interrupted. A detached watcher uses
Herdr's raw and spinner-stripped terminal titles to restore `idle` after an
interrupted turn. It never overrides `blocked` and exits after the turn settles.

The hook is a no-op outside Herdr and never blocks a TraeX turn when reporting
fails.

Install or refresh it with:

```sh
traecli plugin install --yes /data00/home/zhangxingrui/.config/dotfiles/herdr/traex-plugin
```
