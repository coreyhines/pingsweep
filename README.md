# pingsweep

A fast, concurrent network ping sweep tool that supports multiple output formats (text, JSON, YAML).

## Features
- Concurrent host scanning for speed
- DNS resolution for discovered hosts
- Multiple output formats (text, JSON, YAML)
- Color-coded output in text mode
- Support for CIDR notation

## Requirements

- `prips` - IP address expansion tool ([installation instructions](#installing-prips))
- `ping` - Network ping utility
- `dig` - DNS lookup utility

## Installation
This tool is designed to be used as a function in a zsh shell environment.

### Automatic Installation

Use the provided installation script:

```bash
# Clone the repository
git clone https://github.com/coreyhines/pingsweep.git
cd pingsweep

# Run the installation script
./install_pingsweep.sh
```

The script will check if the function already exists in your `.zshrc` file and append it if not present.

### Manual Installation

You can manually add the function to your shell configuration:

1. Copy the function from the pingsweep file directly into your `.zshrc` file:

   ```bash
   # Add this to your .zshrc file
   function pingsweep() {
     # Paste the entire function here from the pingsweep file
   }
   ```

2. Restart your shell or run `source ~/.zshrc`

Alternatively, you can source the script in your configuration:

```bash
# In your .zshrc file
source /path/to/pingsweep
```

## Usage

When sourced as a function:

```zsh
pingsweep [options] <CIDR subnet>
```

If not sourced, you can run it directly with bash:

```bash
bash /path/to/pingsweep [options] <CIDR subnet>
```

### Options

  -f, --format FORMAT    Output format: text (default), json, or yaml
  -h, --help            Show this help message

### Examples

# As a zsh function

 ~ » pingsweep 192.168.1.0/24
 ~ » pingsweep -f json 192.168.1.0/24
 ~ » pingsweep -f yaml 192.168.1.0/24
  
# Direct bash execution

  bash /path/to/pingsweep 192.168.1.0/24
  bash /path/to/pingsweep -f yaml 10.0.0.0/24

## Installing prips

### macOS

```bash
brew install prips
```

### Debian/Ubuntu (APT-based)

```bash
sudo apt-get update
sudo apt-get install prips
```

### RHEL/CentOS/Fedora (RPM-based)

```bash
# For Fedora
sudo dnf install prips

# For RHEL/CentOS
sudo yum install epel-release
sudo yum install prips
```
