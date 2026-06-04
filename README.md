# pingsweep

Concurrent ping sweep for IPv4 CIDR subnets. A single bash script with no build step.

## What it reports

For each address in the subnet, pingsweep pings once; responding hosts optionally get reverse DNS (`dig -x`).

- **Up** — host responded to ping (listed, with reverse DNS when available)
- **Silent** — no ping response (omitted from output; no reverse DNS lookup)

Results are sorted by IP. Use `-s` to filter the output lines by substring, wildcard (`*`, `?`), or regex (`re:pattern`).

## Quick start

Run directly from the repo — no install required:

```bash
./pingsweep 192.168.1.0/24
./pingsweep -f json -q 192.168.1.0/24
```

## Install

macOS and most Linux desktops default to zsh. The installer sets up a zsh function that calls the bash script (zsh's job table limits concurrent background jobs; the scan itself runs in bash).

```bash
git clone https://github.com/coreyhines/pingsweep.git
cd pingsweep
./install_pingsweep.sh
```

This copies the script to `~/.local/bin/pingsweep`, adds a wrapper to `~/.zshfunc`, and updates your zsh config (with a backup). Restart the shell or run `source ~/.zshrc`.

**Manual install:** copy `pingsweep` to a directory on your `PATH`, make it executable, and call it directly. Bash users do not need the zsh wrapper.

## Options

```
  -f, --format FORMAT    Output format: text (default), json, yaml, or csv
  -j, --jobs JOBS        Max concurrent jobs (default: 255)
  -t, --timeout SECONDS  Timeout for ping and DNS queries (default: 1)
  -q, --quiet            Suppress progress and summary (text mode)
  -n, --dry-run          List IPs without scanning
  -s, --search PATTERN   Filter output (substring, wildcards, or re:regex)
  -v, --version          Show version
  -h, --help             Show help
```

## Examples

**Text output** (progress banner and summary go to stderr; colors when stdout is a TTY):

```bash
pingsweep 192.168.1.0/24
# 192.168.1.1      up          router.local
# Found 12 hosts in 2s
```

**Scripting with JSON:**

```bash
pingsweep -q -f json 192.168.1.0/24 | jq '.results[] | select(.status=="up")'
```

**Filter and dry-run:**

```bash
pingsweep -s 'router*' 192.168.1.0/24
pingsweep -n 192.168.1.0/29          # preview IP list, no pings
```

## Requirements

| Command | Required | Purpose |
|---------|----------|---------|
| `ping`  | yes      | Host reachability |
| `date`  | yes      | Scan timing |
| `dig`   | no       | Reverse DNS (skipped if absent) |
| `prips` | no       | Faster IP list generation (built-in fallback) |

Subnets larger than 65,536 addresses print a warning before scanning.

## Notes

- Tune `-j` (concurrency) and `-t` (timeout) for your network; defaults suit typical LAN scans.
- Progress spinner appears in text mode for subnets over 256 IPs when not using `-q`.
- JSON/YAML `stats.total_hosts` counts result rows after filtering (responding hosts only).

## License

MIT — see [LICENSE](LICENSE).
