# pingsweep

A fast, concurrent network ping sweep tool that supports multiple output formats (text, JSON, YAML).

## Features
- Concurrent host scanning for speed
- DNS resolution for discovered hosts
- Multiple output formats (text, JSON, YAML, CSV)
- Color-coded output in text mode (auto-disabled when piped)
- Support for CIDR notation
- Built-in IP range generation (no external dependencies)
- Search/filter results with substring, wildcards, or regex
- Quiet mode for scripting and non-interactive use
- Dry-run mode to preview IP ranges
- Configurable timeouts and concurrency

## Requirements

- `ping` - Network ping utility (required)
- `dig` - DNS lookup utility (optional - DNS resolution skipped if not available)
- `date` - Date utility (required for timing)

## Performance Notes

- **Concurrency**: Default is 255 concurrent jobs for optimal performance
- **Shell compatibility**: When used as a zsh function, automatically calls the standalone bash script to avoid zsh's job table limitations
- **Performance**: Typical /24 subnet scans complete in ~1.5-2 seconds, /20 subnets in ~30 seconds
- **Tuning**: Use `-j` flag to adjust concurrency for your environment

## Installation

### Automatic Installation (Recommended)

Use the provided installation script:

```bash
# Clone the repository
git clone https://github.com/coreyhines/pingsweep.git
cd pingsweep

# Run the installation script
./install_pingsweep.sh
```

The installer will:
1. Install the standalone bash script to `~/.local/bin/pingsweep`
2. Create a lightweight zsh wrapper function in `~/.zshfunc`
3. Update your `.zshrc` to source the function (with guards to prevent duplicate sourcing)
4. Back up your `.zshrc` before making changes

This approach ensures optimal performance by running the script in bash (avoiding zsh job table limitations) while maintaining seamless zsh integration.

### Manual Installation

You can install manually if needed:

1. Copy the script to your local bin directory:
   ```bash
   mkdir -p ~/.local/bin
   cp pingsweep ~/.local/bin/pingsweep
   chmod +x ~/.local/bin/pingsweep
   ```

2. Add the wrapper function to your `~/.zshrc`:
   ```bash
   pingsweep() {
     "$HOME/.local/bin/pingsweep" "$@"
   }
   ```

3. Ensure `~/.local/bin` is in your PATH:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

4. Restart your shell or run `source ~/.zshrc`

## Usage

```bash
pingsweep [options] <CIDR subnet>
```

### Options

```
  -f, --format FORMAT    Output format: text (default), json, yaml, or csv
  -j, --jobs JOBS        Max concurrent jobs (default: 255)
  -t, --timeout SECONDS  Timeout for ping/DNS queries (default: 1)
  -q, --quiet            Quiet mode - suppress progress output
  -n, --dry-run          Show IPs that would be scanned without scanning
  -s, --search SEARCH    Search/filter output (supports substring, wildcards, or regex with re: prefix)
  -h, --help             Show this help message
```

### Examples

#### Text Output (Default)

```bash
~ » pingsweep 192.168.1.0/24
Scanning 192.168.1.0/24...
192.168.1.1      up          router.local
192.168.1.5      up          laptop.local
192.168.1.10     up          desktop.local
192.168.1.20     down        printer.local
192.168.1.25     up          
Found 5 hosts in 3s
```

#### JSON Output

```bash
~ » pingsweep -f json 192.168.1.0/24
Scanning 192.168.1.0/24...
{
  "results": [
    {"ip": "192.168.1.1", "status": "up", "hostname": "router.local"},
    {"ip": "192.168.1.5", "status": "up", "hostname": "laptop.local"},
    {"ip": "192.168.1.10", "status": "up", "hostname": "desktop.local"},
    {"ip": "192.168.1.20", "status": "down", "hostname": "printer.local"},
    {"ip": "192.168.1.25", "status": "up"}
  ],
  "stats": {
    "total_hosts": 5,
    "scan_time_seconds": 3
  }
}
```

#### YAML Output

```bash
~ » pingsweep -f yaml 192.168.1.0/24
Scanning 192.168.1.0/24...
results:
  - ip: 192.168.1.1
    status: up
    hostname: router.local
  - ip: 192.168.1.5
    status: up
    hostname: laptop.local
  - ip: 192.168.1.10
    status: up
    hostname: desktop.local
  - ip: 192.168.1.20
    status: down
    hostname: printer.local
  - ip: 192.168.1.25
    status: up
stats:
  total_hosts: 5
  scan_time_seconds: 3
```

#### CSV Output

```bash
~ » pingsweep -f csv 192.168.1.0/24
IP,Status,Hostname
192.168.1.1,up,"router.local"
192.168.1.5,up,"laptop.local"
192.168.1.10,up,"desktop.local"
192.168.1.20,down,"printer.local"
192.168.1.25,up,
```

#### Filtering Output

Filter results using the `--search` or `-s` option with substring, wildcard, or regex:

```bash
# Substring match
~ » pingsweep -s 'router' 192.168.1.0/24

# Wildcard match
~ » pingsweep -s 'router*' 192.168.1.0/24

# Regex match (prefix with 're:')
~ » pingsweep --search 're:^192\\.168\\.1\\.[0-9]+ up' 192.168.1.0/24
```

#### Quiet Mode for Scripting

```bash
# Suppress progress messages and summary
~ » pingsweep -q 192.168.1.0/24
192.168.1.1      up          router.local
192.168.1.5      up          laptop.local

# Perfect for piping to other tools
~ » pingsweep -q -f json 192.168.1.0/24 | jq '.results[] | select(.status=="up")'
```

#### Dry Run

```bash
# Preview IPs without scanning
~ » pingsweep -n 192.168.1.0/29
Dry-run mode: IPs that would be scanned:
192.168.1.0
192.168.1.1
192.168.1.2
192.168.1.3
192.168.1.4
192.168.1.5
192.168.1.6
192.168.1.7

Total: 8 IPs
```

#### Custom Timeout and Concurrency

```bash
# Faster scan with shorter timeout
~ » pingsweep -t 0.5 -j 500 192.168.1.0/24

# More conservative for slower networks
~ » pingsweep -t 3 -j 50 192.168.1.0/24
```
