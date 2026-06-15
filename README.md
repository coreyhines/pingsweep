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
      --v6               Parallel aligned IPv6 probes and DNS alignment checks
      --v6-map FILE      IPv4-CIDR to IPv6-/64 map file (see README)
  -v, --version          Show version
  -h, --help             Show help
```

## IPv6 follow-up (`--v6`)

IPv4 sweeps stay the same; `--v6` adds **parallel** ICMPv6 probes for every address in the range — no waiting for IPv4 to return first.

For each IPv4 target `10.0.2.4`, pingsweep also pings an **aligned** address `{local-/64}::4`, using a derived global IPv6 `/64` for the scanned VLAN. The host-id is the **last IPv4 octet** (decimal). The VLAN is encoded in the **last digit** of the fourth hextet (`b502` = VLAN 2, `b508` = VLAN 8); for VLAN ≥ 10 the ones digit is dropped (`10.0.10.x` → `…b501::N`, not `…b510::N`).

When reverse/forward DNS is available (`dig`), pingsweep checks whether the `AAAA` matches that aligned address and flags **mismatch** (e.g. `A` → `.4` but `AAAA` → `::feed`). Non-aligned `AAAA` targets are pinged as well so DHCP-registered v6-only names can still be found.

**Requirements for `--v6`:**

- Run from a host with **both** IPv4 and a global IPv6 `/64` on the VLAN/subnet you are scanning.
- `dig` is strongly recommended for alignment checks (optional for ping-only).

**Limitations (read before relying on this):**

- Assumes your site aligns v4 last-octet with v6 host-id (`::N`). Most networks do **not** — expect many `down` / `mismatch` results elsewhere.
- Prefix delegation (e.g. ISP PD) changes over time; orientation always comes from **this host’s current** addresses, not a configured prefix.
- SLAAC, privacy addresses, and NAT64 break the simple `::N` model.
- IPv6-only responders appear even when IPv4 is filtered; IPv4-only hosts still appear as today.

**Example:**

```bash
pingsweep --v6 10.0.2.0/24
# 10.0.2.2   v4:up   v6:up(::2)   pi.hole
# 10.0.2.5   v4:up   v6:down(::5)   host5.example.com  AAAA 2601:…::feed (expected ::5)
```

Text mode drops the old `dns:` column; alignment issues appear as a yellow trailing note only when `A`/`AAAA` disagree with the aligned model. JSON/YAML/CSV still include `dns_alignment` and record fields for scripting.

On macOS, `ping6` has no per-probe timeout flag (unlike `ping`); aligned probes use `ping6 -c1` with the OS default wait. `-t` still applies to IPv4 ping and `dig`. Cross-VLAN IPv6 probes use system routing (not interface bind); same-/64 scans may use `-I` when the outbound interface matches.

Dry-run shows aligned targets:

```bash
pingsweep -n --v6 10.0.2.0/29
```

### IPv6 map (non-standard subnets)

Auto `--v6` mode derives the IPv6 `/64` from **this host’s** addresses and assumes IPv4 subnets look like `10.0.VLAN.0/CIDR`, where the VLAN digit is encoded in the fourth IPv6 hextet (`b502` = VLAN 2, `b508` = VLAN 8).

Some sites have **exceptions** — for example VLAN 1 on `192.168.1.0/24` with IPv6 `2601:441:8483:b500::/64` instead of `10.0.1.0/24`. Add a user-space map so `--v6` still aligns `::N` from the last IPv4 octet.

**Map file format** (whitespace-separated, `#` comments):

```
192.168.1.0/24  2601:441:8483:b500
```

**Lookup order:**

1. `--v6-map /path/to/file`
2. `$PINGSWEEP_IPV6_MAP`
3. `$XDG_CONFIG_HOME/pingsweep/ipv6-map`
4. `~/.config/pingsweep/ipv6-map`

Copy `examples/ipv6-map.example` as a starting point:

```bash
mkdir -p ~/.config/pingsweep
cp examples/ipv6-map.example ~/.config/pingsweep/ipv6-map
# edit entries for your site
pingsweep --v6 192.168.1.0/24
```

Host-id alignment is unchanged: `192.168.1.4` probes `2601:441:8483:b500::4`. Wrappers that translate VLAN numbers to CIDR (e.g. `sweep 1 --v6` → `192.168.1.0/24`) work once the map entry exists.

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
