# Building LocalGPT on Alpine Linux / Docker

This guide addresses the common compilation issue when building LocalGPT on headless Alpine Linux or in Docker containers.

## The Problem

By default, LocalGPT includes a `desktop` feature that enables a GUI via the `eframe` crate, which depends on `winit`. The `winit` crate requires either X11 or Wayland windowing support, which may not be available on headless Alpine Linux systems.

You may encounter this error:

```
error: The platform you're compiling for is not supported by winit
  --> /root/.cargo/registry/.../winit-0.30.12/src/platform_impl/mod.rs:78:1
   |
78 | compile_error!("The platform you're compiling for is not supported by winit");
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## The Solution

LocalGPT can be built **without GUI dependencies** by disabling the default features. This is the recommended approach for:

- Headless servers
- Docker containers
- Alpine Linux
- CI/CD pipelines
- Any environment without X11/Wayland

## Building Without GUI

### Using cargo install

```bash
# Headless build (no desktop GUI)
cargo install localgpt --no-default-features
```

### Using cargo build

```bash
# Clone the repository
git clone https://github.com/localgpt-app/localgpt.git
cd localgpt

# Build without default features
cargo build --release --no-default-features

# The binary will be at target/release/localgpt
```

### Verifying No GUI Dependencies

To confirm that `winit` is not included in the build:

```bash
# This should return an error indicating winit is not in the dependency tree
cargo tree --no-default-features -i winit
```

Expected output:
```
error: package ID specification `winit` did not match any packages
```

## Docker Example

Here's a minimal Dockerfile for Alpine:

```dockerfile
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev pkgconf

WORKDIR /build
COPY . .

# Build without GUI features
RUN cargo build --release --no-default-features

FROM alpine:latest
RUN apk add --no-cache ca-certificates

COPY --from=builder /build/target/release/localgpt /usr/local/bin/localgpt

# Create workspace directory
RUN mkdir -p /root/.localgpt/workspace

ENTRYPOINT ["localgpt"]
CMD ["daemon", "start"]
```

### Build and run:

```bash
# Build the image
docker build -t localgpt .

# Run daemon mode
docker run -v ~/.localgpt:/root/.localgpt -p 31327:31327 localgpt

# Or run interactive chat
docker run -it -v ~/.localgpt:/root/.localgpt localgpt chat
```

## What You Get Without the Desktop Feature

When built with `--no-default-features`, LocalGPT still includes:

✅ **Full CLI functionality**
- `localgpt chat` - Interactive terminal chat
- `localgpt ask` - Single question queries
- `localgpt daemon` - Background daemon with HTTP API
- `localgpt memory` - Memory search and management
- `localgpt config` - Configuration management

✅ **HTTP API and Web UI**
- RESTful API endpoints
- WebSocket support
- Embedded web-based interface (no desktop GUI needed)

✅ **All core features**
- Persistent markdown memory
- Autonomous heartbeat tasks
- Multiple LLM providers (Anthropic, OpenAI, Ollama, Claude CLI)
- Semantic search with local embeddings
- Session management

❌ **What's excluded**
- Desktop GUI window (eframe/egui)
- X11/Wayland dependencies

## Alpine-Specific Notes

### System Dependencies

Even without GUI dependencies, you may need these packages for building:

```bash
apk add --no-cache \
  musl-dev \
  pkgconf \
  openssl-dev \
  ca-certificates
```

### Static Linking

For a fully static binary that runs anywhere (including scratch containers):

```bash
# Install musl target
rustup target add x86_64-unknown-linux-musl

# Build static binary
cargo build --release --no-default-features --target x86_64-unknown-linux-musl
```

## CI/CD Example

For GitHub Actions or other CI systems:

```yaml
name: Build Headless

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    container: rust:alpine
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: apk add --no-cache musl-dev pkgconf
      
      - name: Build
        run: cargo build --release --no-default-features
      
      - name: Test
        run: cargo test --no-default-features
```

## Testing Your Headless Build

After building, verify all features work:

```bash
# Check version
./target/release/localgpt --version

# Initialize config
./target/release/localgpt config init

# Test memory search
./target/release/localgpt memory stats

# Test single query (requires API key in config)
./target/release/localgpt ask "Hello"

# Start daemon
./target/release/localgpt daemon start
```

## Troubleshooting

### Still seeing winit errors?

Make sure you're using `--no-default-features`:

```bash
cargo clean
cargo build --release --no-default-features
```

### Want to confirm features?

List enabled features:

```bash
cargo tree --no-default-features -e features | head -20
```

### Need the desktop GUI?

If you DO need the desktop GUI on Linux, install the required development packages:

```bash
# For X11 support
apk add \
  libx11-dev \
  libxcursor-dev \
  libxrandr-dev \
  libxi-dev \
  libxinerama-dev \
  libxkbcommon-dev \
  pkgconf

# Then build with default features
cargo build --release
```

## Summary

The key takeaway: **Use `--no-default-features` for headless/server deployments.**

This completely removes the GUI and windowing dependencies while preserving all CLI, daemon, and API functionality.

For more information, see:
- [Main README](../README.md)
- [Architecture Documentation](./architecture.md)
