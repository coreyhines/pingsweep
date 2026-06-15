# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**pingsweep** is a standalone bash script that performs concurrent network ping sweeps across CIDR subnets. Single-file project (`pingsweep`) with no external dependencies beyond `ping`, `date`, and optionally `dig` for DNS resolution.

## File Structure

- `pingsweep` - The entire application (standalone bash script, ~440 lines)
- `install_pingsweep.sh` - Installer that copies the script to `~/.local/bin/` and creates a zsh wrapper function in `~/.zshfunc`
- `README.md` - Usage docs

## Architecture

The script follows a linear pipeline with inline parallelism:

1. **Arg parsing** (`check_requirements` → arg parse loop): Validates deps, parses flags (`-f/-j/-t/-q/-n/-s/-h`)
2. **IP generation** (`generate_ips`, `prips` if available): Produces newline-separated IPs from CIDR into a temp file
3. **Concurrent scan loop** (`while read ... done < ips_file`): Fires `ping -c1 -W{timeout} {ip}` in background (`&`); optional `dig -x` only after a successful ping, batch-waits every `max_jobs` (default 255)
4. **Results formatting**: Reads sorted temp file, applies filter (`-s` substring/wildcard/regex), formats as text/JSON/YAML/CSV

Key design decisions:
- Uses inline blocks (`{ ... } &`) instead of functions for background jobs to avoid subshell overhead
- Colors auto-disable when stdout is not a terminal (`[ -t 1 ]`)
- When invoked from zsh, the wrapper (in `.zshfunc`) calls the bash script to bypass zsh job table limitations
- Progress spinner triggers only for subnets >256 IPs and text format with `--quiet` disabled

## Usage During Development

```bash
# Run directly from repo (no install needed)
./pingsweep 192.168.1.0/24

# Dry-run to preview IPs without scanning
./pingsweep -n 192.168.1.0/24

# JSON output for scripting
./pingsweep -f json -q 192.168.1.0/24

# Install to ~/.local/bin with zsh integration
./install_pingsweep.sh
```

## Making Changes

- All logic lives in `pingsweep` — edit that file directly
- After changes, reinstall for testing: `cp pingsweep ~/.local/bin/pingsweep` (or re-run `./install_pingsweep.sh`)
- Test edge cases around CIDR boundaries (/32, /0), large subnets (/16, /20), invalid input, and piped vs terminal output
- The script is self-contained bash — no test framework or linter configured. Validate with `bash -n pingsweep` for syntax checks
