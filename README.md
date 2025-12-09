# organize

A fast CLI tool for flattening directory structures in Unix-like systems.

[![CI](https://github.com/thatjuan/organize/actions/workflows/ci.yml/badge.svg)](https://github.com/thatjuan/organize/actions/workflows/ci.yml)
[![Release](https://github.com/thatjuan/organize/actions/workflows/release.yml/badge.svg)](https://github.com/thatjuan/organize/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What it does

`organize` takes a nested directory structure and flattens it by moving all files to the root level. It handles filename conflicts automatically and can optionally clean up empty directories.

**Before:**
```
photos/
├── vacation/
│   ├── day1/
│   │   └── img001.jpg
│   └── img002.jpg
└── birthday/
    └── cake.jpg
```

**After `organize flatten photos --delete`:**
```
photos/
├── img001.jpg
├── img002.jpg
└── cake.jpg
```

## Installation

### Quick Install (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/thatjuan/organize/main/install.sh | sh
```

### From Source

Requires [Rust](https://rustup.rs/) 1.70+:

```bash
git clone https://github.com/thatjuan/organize.git
cd organize
cargo build --release
sudo cp target/release/organize /usr/local/bin/
```

### From Releases

Download the latest binary for your platform from [Releases](https://github.com/thatjuan/organize/releases).

## Usage

```bash
# Basic flatten - move all nested files to root
organize flatten /path/to/directory

# Flatten with rename - prepend parent folder name to avoid conflicts
organize flatten /path/to/directory --rename

# Flatten and delete empty directories
organize flatten /path/to/directory --delete

# Combine both options
organize flatten /path/to/directory --rename --delete
```

### Options

| Option | Description |
|--------|-------------|
| `--rename` | Prepend the immediate parent folder name to each file (e.g., `vacation/img.jpg` becomes `vacation_img.jpg`) |
| `--delete` | Remove empty directories after flattening |

### Conflict Handling

When files with the same name exist, `organize` automatically adds numeric suffixes:

```
file.txt      # Original at root
file_1.txt    # First conflict
file_2.txt    # Second conflict
```

## Examples

### Flatten a downloads folder

```bash
organize flatten ~/Downloads --delete
```

### Organize photos with folder prefixes

```bash
organize flatten ~/Photos/2024 --rename --delete
```

This turns `2024/January/img.jpg` into `January_img.jpg`.

### Preview what would happen

Currently, `organize` operates directly on files. Make a backup or test on a copy first:

```bash
cp -r mydir mydir-backup
organize flatten mydir --delete
```

## Building

```bash
# Debug build
cargo build

# Release build (optimized)
cargo build --release

# Run tests
cargo test

# Format code
cargo fmt

# Lint
cargo clippy
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
