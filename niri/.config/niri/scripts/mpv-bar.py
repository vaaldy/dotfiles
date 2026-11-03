#!/usr/bin/env python3
import json
import subprocess


# Match the outer and inter-column gaps in cfg/layout.kdl.
GAP = 16


def query(name):
    return json.loads(subprocess.check_output(["niri", "msg", "--json", name]))


def action(name, window_id, *args):
    subprocess.run(
        ["niri", "msg", "action", name, "--id", str(window_id), *args],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def fit_movie(windows, focused, workspaces, outputs, movies, split):
    selected = windows.get(focused)
    if not selected:
        return
    workspace = workspaces.get(selected["workspace_id"], {})
    output = outputs.get(workspace.get("output"), {})
    screen_width = output.get("logical", {}).get("width")
    if not screen_width:
        return

    if selected["app_id"] == "mpv" and not selected["is_floating"]:
        if focused in split:
            action("maximize-window-to-edges", focused)
            split.pop(focused)
        elif selected["layout"]["tile_size"][0] >= screen_width - 2 * GAP:
            movies.add(focused)
        else:
            movies.discard(focused)
        return

    for movie_id in movies.copy():
        movie = windows.get(movie_id)
        if not movie:
            movies.discard(movie_id)
            split.pop(movie_id, None)
            continue
        if movie["workspace_id"] != selected["workspace_id"] or movie["is_floating"]:
            continue
        if selected["is_floating"]:
            if movie_id in split:
                action("maximize-window-to-edges", movie_id)
                split.pop(movie_id)
            continue

        movie_pos = movie["layout"]["pos_in_scrolling_layout"]
        selected_pos = selected["layout"]["pos_in_scrolling_layout"]
        if not movie_pos or not selected_pos or abs(movie_pos[0] - selected_pos[0]) != 1:
            continue
        width = round(screen_width - selected["layout"]["tile_size"][0] - 3 * GAP)
        if width < 200:
            continue
        if split.get(movie_id) != width:
            action("set-window-width", movie_id, str(width))
            split[movie_id] = width


def main():
    outputs = query("outputs")
    workspaces = {}
    windows = {}
    movies = set()
    split = {}
    focused = None
    hidden = None
    with subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE,
        text=True,
    ) as events:
        for line in events.stdout:
            event = json.loads(line)
            previous = focused
            initial = False
            if "WorkspacesChanged" in event:
                workspaces = {
                    w["id"]: w for w in event["WorkspacesChanged"]["workspaces"]
                }
                continue
            if "WindowsChanged" in event:
                windows = {w["id"]: w for w in event["WindowsChanged"]["windows"]}
                focused = next(
                    (w["id"] for w in windows.values() if w["is_focused"]), None
                )
                initial = True
            elif "WindowOpenedOrChanged" in event:
                window = event["WindowOpenedOrChanged"]["window"]
                windows[window["id"]] = window
                if window["is_focused"]:
                    focused = window["id"]
            elif "WindowLayoutsChanged" in event:
                for window_id, layout in event["WindowLayoutsChanged"]["changes"]:
                    if window_id in windows:
                        windows[window_id]["layout"] = layout
            elif "WindowFocusChanged" in event:
                focused = event["WindowFocusChanged"]["id"]
            elif "WindowClosed" in event:
                window_id = event["WindowClosed"]["id"]
                windows.pop(window_id, None)
                movies.discard(window_id)
                split.pop(window_id, None)
            else:
                continue

            if initial or focused != previous:
                if windows.get(previous, {}).get("app_id") == "mpv" and previous not in split:
                    fit_movie(windows, previous, workspaces, outputs, movies, split)
            fit_movie(windows, focused, workspaces, outputs, movies, split)

            hide = windows.get(focused, {}).get("app_id") == "mpv"
            if hide != hidden:
                result = subprocess.run(
                    ["noctalia", "msg", "bar-hide" if hide else "bar-show"],
                    stdout=subprocess.DEVNULL,
                )
                if result.returncode == 0:
                    hidden = hide


if __name__ == "__main__":
    main()
