#!/usr/bin/env python3
"""
Kitty kitten for 0.46: toggle zoom (stack layout) and write state file.

Bind in kitty.conf:
    map ctrl+z>z @kitten zoom_indicator

Requires allow_remote_control yes (already set in kitty.conf).
"""
import os
import subprocess
import json

STATE_FILE = os.path.join(
    os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache')),
    'kitty_zoom_status',
)


def _write_state(zoomed: bool) -> None:
    try:
        with open(STATE_FILE, 'w') as f:
            f.write('1' if zoomed else '0')
    except Exception:
        pass


def _get_active_layout() -> str | None:
    """Return the layout name of the active tab via `kitty @ ls`."""
    try:
        result = subprocess.run(
            ['kitty', '@', 'ls'],
            capture_output=True, text=True, timeout=2,
        )
        if result.returncode != 0:
            return None
        data = json.loads(result.stdout)
        for os_window in data:
            for tab in os_window.get('tabs', []):
                if tab.get('is_active', False):
                    return tab.get('layout', '').lower()
    except Exception:
        pass
    return None


def main(args: list[str]) -> str:
    # Check layout BEFORE toggle to avoid race condition
    layout = _get_active_layout()
    if layout is None:
        # Can't detect layout, fall back to just toggling without state update
        subprocess.run(
            ['kitty', '@', 'action', 'toggle_layout', 'stack'],
            capture_output=True, timeout=2,
        )
        return ''

    zoomed = layout == 'stack'

    # Toggle: if stack -> previous, if not stack -> stack
    toggle_result = subprocess.run(
        ['kitty', '@', 'action', 'toggle_layout', 'stack'],
        capture_output=True, timeout=2,
    )

    # Only write state if toggle succeeded
    if toggle_result.returncode == 0:
        _write_state(not zoomed)
    return ''
