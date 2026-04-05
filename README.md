# MiKTeX for containers

This fork of [MiKTeX](https://github.com/MiKTeX/miktex) builds opinionated binaries for integration into container images. There are two important features: 

1. Lightweight: our opinions allow lightweight builds; i.e., CLI only, for Ubuntu only.
2. Cross-platform: we support both amd64 and arm64. 

## Build

We provide a dev container that includes the required system prerequisites for build. To build, run:

```bash
./build.sh
```

This will:
- Configure and build MiKTeX
- Create a distribution tarball at `out/miktex-<version>-<arch>.tar.xz`

The tarball contains:
- `miktex/` - MiKTeX binaries and libraries
- `install.sh` - Installation script
- `test.sh` - Test suite
- `test/` - Test files

## Install

Install the latest release with a single command (requires `curl`, `tar`, `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/recap-org/miktex/dev/install.sh | bash
```

Pin a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/recap-org/miktex/dev/install.sh | bash -s -- --version 26.2
```

Or install from a local build:

```bash
./install.sh --from ./out/miktex
```

### Installation Options

- `--version VER` - MiKTeX version to install (default: latest release)
- `--from DIR` - Install from a local directory instead of downloading
- `--to DIR` - Installation target directory (default: `/usr/local/miktex`)
- `--user-dir DIR` - MiKTeX user data directory (default: `~/.miktex`)
- `-h, --help` - Show help message

## Test

Run the test suite to verify the installation:

```bash
./test.sh
```

This will:
- Run comprehensive tests for pdflatex, xelatex, and lualatex
- Test basic compilation, bibliography, graphics, and TikZ
- Store test outputs (PDFs and logs) in `test-output/`
- Display a summary of passed/failed tests

Test artifacts are organized by category in `test-output/{basic,bibliography,graphics,tikz}/`.