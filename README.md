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

Extract the tarball and run the installation script:

```bash
# Extract the tarball
tar -xJf miktex-<version>-<arch>.tar.xz
cd miktex-<version>-<arch>/

# Install with defaults (installs from ./miktex to /usr/local/miktex)
sudo ./install.sh

# Or customize installation paths
sudo ./install.sh --from ./miktex --to /opt/miktex --user-dir /var/lib/miktex
```

### Installation Options

- `--from DIR` - MiKTeX source directory to install from (default: `./miktex`)
- `--to DIR` - Installation target directory (default: `/usr/local/miktex`)
- `--user-dir DIR` - MiKTeX user data directory (default: `/var/lib/miktex`)
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