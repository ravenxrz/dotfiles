#!/usr/bin/env python3
"""Report TraeX hook events to the Herdr pane that owns this process."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from typing import Any


SOURCE = "traex:hooks"
AGENT = "traex"

WORKING_EVENTS = {
    "userpromptsubmit",
    "pretooluse",
    "posttooluse",
    "posttoolusefailure",
}


def normalized(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return "".join(character for character in value.lower() if character.isalnum())


def read_payload() -> dict[str, Any]:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return {}
    return payload if isinstance(payload, dict) else {}


def event_state(payload: dict[str, Any]) -> tuple[str, str | None]:
    event = normalized(payload.get("hook_event_name") or payload.get("event_type"))

    if event == "sessionstart" or event == "stop":
        return "idle", None
    if event in WORKING_EVENTS:
        return "working", None
    if event == "permissionrequest":
        tool_name = payload.get("tool_name")
        message = f"TraeX requests permission for {tool_name}" if tool_name else "TraeX requests permission"
        return "blocked", message
    if event == "notification":
        notification_type = normalized(payload.get("notification_type"))
        if notification_type == "permissionprompt":
            return "blocked", str(payload.get("message") or "TraeX requests permission")
        if notification_type == "idleprompt":
            return "idle", None
    if event == "sessionend":
        return "release", None
    return "", None


def herdr_context() -> tuple[str, str] | None:
    if os.environ.get("HERDR_ENV") != "1":
        return None
    herdr = os.environ.get("HERDR_BIN_PATH")
    pane_id = os.environ.get("HERDR_PANE_ID")
    if not herdr or not pane_id:
        return None
    return herdr, pane_id


def run_quietly(command: list[str]) -> None:
    try:
        subprocess.run(
            command,
            check=False,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1,
        )
    except (OSError, subprocess.SubprocessError):
        # Herdr is optional; a reporting failure must never break a TraeX turn.
        pass


def report_state(
    herdr: str,
    pane_id: str,
    state: str,
    *,
    message: str | None = None,
    session_id: str | None = None,
) -> None:
    command = [
        herdr,
        "pane",
        "report-agent",
        pane_id,
        "--source",
        SOURCE,
        "--agent",
        AGENT,
        "--state",
        state,
        "--seq",
        str(time.time_ns()),
    ]
    if message:
        command.extend(("--message", message))
    if session_id:
        command.extend(("--agent-session-id", session_id))
    run_quietly(command)


def spawn_title_watcher() -> None:
    try:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--watch-title"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
    except OSError:
        pass


def watch_title() -> None:
    context = herdr_context()
    if context is None:
        return
    herdr, pane_id = context

    saw_spinner = False
    idle_since: float | None = None
    started_at = time.monotonic()
    failures = 0

    while time.monotonic() - started_at < 86_400:
        try:
            result = subprocess.run(
                [herdr, "pane", "get", pane_id],
                check=False,
                stdin=subprocess.DEVNULL,
                capture_output=True,
                text=True,
                timeout=1,
            )
            response = json.loads(result.stdout)
            pane = response.get("result", {}).get("pane", {})
            failures = 0
        except (OSError, subprocess.SubprocessError, json.JSONDecodeError, AttributeError):
            failures += 1
            if failures >= 20:
                return
            time.sleep(0.25)
            continue

        agent_status = pane.get("agent_status")
        if agent_status in {"idle", "done", "unknown"}:
            return

        title = pane.get("terminal_title")
        stripped_title = pane.get("terminal_title_stripped")
        has_spinner = (
            isinstance(title, str)
            and isinstance(stripped_title, str)
            and title != stripped_title
            and title.endswith(stripped_title)
        )

        if has_spinner:
            saw_spinner = True
            idle_since = None
        elif saw_spinner and agent_status == "working":
            if idle_since is None:
                idle_since = time.monotonic()
            elif time.monotonic() - idle_since >= 0.75:
                report_state(herdr, pane_id, "idle")
                return
        else:
            idle_since = None

        # A title spinner normally appears immediately after prompt submission.
        if not saw_spinner and time.monotonic() - started_at >= 30:
            return
        time.sleep(0.25)


def report(payload: dict[str, Any]) -> None:
    context = herdr_context()
    if context is None:
        return
    herdr, pane_id = context

    state, message = event_state(payload)
    if not state:
        return

    if state == "release":
        run_quietly([
            herdr,
            "pane",
            "release-agent",
            pane_id,
            "--source",
            SOURCE,
            "--agent",
            AGENT,
            "--seq",
            str(time.time_ns()),
        ])
        return

    session_id = payload.get("session_id")
    report_state(
        herdr,
        pane_id,
        state,
        message=message,
        session_id=session_id if isinstance(session_id, str) else None,
    )
    if normalized(payload.get("hook_event_name") or payload.get("event_type")) == "userpromptsubmit":
        spawn_title_watcher()


def main() -> int:
    if sys.argv[1:] == ["--watch-title"]:
        watch_title()
        return 0
    report(read_payload())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
