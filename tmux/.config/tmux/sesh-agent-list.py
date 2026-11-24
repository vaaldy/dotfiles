#!/usr/bin/env python3
import os
import re
import subprocess
import sys


def output(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL)


escape = re.compile(r'\x1b\[[0-9;]*m')


def work_preview(entry):
    icon, _, selected = escape.sub('', entry).partition(' ')
    if icon != '':
        return
    try:
        windows = output('tmux', 'list-windows', '-a', '-F', '#{session_name}\t#{window_index}\t#{@sesh_work}')
    except (subprocess.CalledProcessError, OSError):
        return
    groups = {}
    for row in windows.split('\n'):
        if not row:
            continue
        repo, index, text = row.split('\t', 2)
        label, _, note = ''.join(c for c in text if c.isprintable()).partition('|')
        if label.strip():
            groups.setdefault(label.strip(), []).append((repo, index, note.strip()))
    shown = False
    for label, tabs in groups.items():
        if not any(repo == selected for repo, _, _ in tabs):
            continue
        shown = True
        print(f'\x1b[1;34m{label}\x1b[0m')
        for repo, index, note in sorted(tabs, key=lambda tab: tab[0] != selected):
            print(f'  {repo}:{index}' + (f' · {note}' if note else ''))
        print()
    if not shown:
        print('No workstreams labeled.\nUse Ctrl-Space W on a tab to add one.')


if len(sys.argv) == 3 and sys.argv[1] == '--work-preview':
    work_preview(sys.argv[2])
    sys.exit()

entries = output('sesh', 'list', '--icons', *sys.argv[1:]).splitlines()
statuses = {}
try:
    processes = output('ps', '-A', '-o', 'pid=', '-o', 'tty=', '-o', 'comm=')
    pi_processes = {}
    for line in processes.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and os.path.basename(parts[2]) == 'pi':
            pi_processes.setdefault(os.path.basename(parts[1]), set()).add(parts[0])
    panes = output('tmux', 'list-panes', '-a', '-F', '#{session_name}\t#{pane_tty}\t#{@pi_sesh_status}')
    for line in panes.splitlines():
        name, tty, status = line.split('\t', 2)
        pids = pi_processes.get(os.path.basename(tty))
        if not pids:
            continue
        fields = status.split()
        rank = 2
        if len(fields) == 3 and fields[0] in pids and fields[1] in ('working', 'idle') and fields[2].isdecimal():
            rank = 0 if fields[1] == 'working' else 1
        statuses[name] = min(rank, statuses.get(name, 3))
except (subprocess.CalledProcessError, OSError):
    pass

rows = []
for entry in entries:
    icon, _, name = escape.sub('', entry).partition(' ')
    # Show the first field; accept the last field as the original sesh entry.
    rank = statuses.get(name, 3) if icon == '' else 3
    colors = (33, 32, 31)  # working, idle, status unavailable
    rows.append((rank, f'{entry} \x1b[{colors[rank]}m●\x1b[0m\t{entry}' if rank < 3 else entry))
for _, row in sorted(rows, key=lambda row: row[0]):
    print(row)
