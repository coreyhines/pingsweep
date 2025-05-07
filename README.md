# pingsweep

A fast, concurrent network ping sweep tool that supports multiple output formats (text, JSON, YAML).

## Features
- Concurrent host scanning for speed
- DNS resolution for discovered hosts
- Multiple output formats (text, JSON, YAML)
- Color-coded output in text mode
- Support for CIDR notation

## Requirements
- `prips` - IP address expansion tool
- `ping` - Network ping utility
- `dig` - DNS lookup utility

## Installation
1. Clone this repository
2. Source the script or add it to your shell configuration

## Usage
```bash
pingsweep [options] <CIDR subnet>

Options:
  -f, --format FORMAT    Output format: text (default), json, or yaml
  -h, --help            Show this help message

Examples:
  pingsweep 192.168.1.0/24
  pingsweep -f json 192.168.1.0/24
```
