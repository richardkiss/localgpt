# Building LocalGPT on Alpine Linux / Docker

## TL;DR

**LocalGPT now builds headless by default.** Just run `cargo build` - no special flags needed for Alpine or Docker!

The desktop GUI is opt-in via `--features desktop`.

## Previous Issue (Now Resolved)

Prior versions included a desktop GUI by default, which required X11/Wayland support via the `winit` crate. This caused compilation failures on headless Alpine systems.

**As of version 0.1.2+**, the default build is headless. No more winit errors on Alpine!

## Building

### Standard Build (Headless)

```bash
# Just works on Alpine and everywhere else
cargo build --release

# Or install from crates.io
cargo install localgpt
```

This gives you:
- ✅ Full CLI (`localgpt chat`, `localgpt ask`, etc.)
- ✅ HTTP daemon with API
- ✅ Web-based UI
- ✅ All memory, heartbeat, and agent features
- ❌ No native desktop window (use `--features desktop` if needed)

### With Desktop GUI (Optional)

```bash
# Enable desktop GUI feature
cargo build --release --features desktop

# Or install with GUI
cargo install localgpt --features desktop
```

This adds:
- ✅ All headless features above
- ✅ Native desktop window via eframe/egui
- ⚠️ Requires X11 or Wayland on Linux

## Docker Examples

### Minimal Alpine Dockerfile

```dockerfile
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev pkgconf

WORKDIR /build
COPY . .

# Just build - no special flags needed!
RUN cargo build --release

FROM alpine:latest
RUN apk add --no-cache ca-certificates libgcc

COPY --from=builder /build/target/release/localgpt /usr/local/bin/localgpt

ENTRYPOINT ["localgpt"]
CMD ["daemon", "start"]
```

See `Dockerfile.alpine` in the repo for the complete example.

### Using Docker Compose

```bash
# Start daemon
docker-compose up -d

# View logs
docker-compose logs -f

# Interactive chat
docker-compose run --rm localgpt chat
```

## What You Get in the Default Build

The standard headless build includes:

✅ **Full CLI functionality**
- `localgpt chat` - Interactive terminal chat
- `localgpt ask` - Single question queries
- `localgpt daemon` - Background daemon with HTTP API
- `localgpt memory` - Memory search and management
- `localgpt config` - Configuration management

✅ **HTTP API and Web UI**
- RESTful API endpoints
- WebSocket support
- Embedded web-based interface (no X11 needed)

✅ **All core features**
- Persistent markdown memory
- Autonomous heartbeat tasks
- Multiple LLM providers (Anthropic, OpenAI, Ollama, Claude CLI)
- Semantic search with local embeddings
- Session management

❌ **Optional: Desktop GUI**
- Add with `--features desktop` if you want a native window
- Requires X11 or Wayland on Linux

## Alpine-Specific Notes

### System Dependencies

For standard builds, you only need:

```bash
apk add --no-cache \
  musl-dev \
  pkgconf \
  openssl-dev \
  ca-certificates
```

### For Desktop GUI on Alpine

If you want the desktop GUI (`--features desktop`), also install:

```bash
apk add --no-cache \
  libx11-dev \
  libxcursor-dev \
  libxrandr-dev \
  libxi-dev \
  libxinerama-dev \
  libxkbcommon-dev
```

### Static Linking

For a fully static binary:

```bash
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
```

## CI/CD Example

For GitHub Actions or other CI systems:

```yaml
name: Build

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
        run: cargo build --release
      
      - name: Test
        run: cargo test
```

No `--no-default-features` needed!

## Testing Your Build

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

### Need the desktop GUI?

Enable it with the `desktop` feature:

```bash
cargo build --release --features desktop
```

Note: This requires X11 or Wayland dev packages on Linux (see above).

### Verify your build configuration

```bash
# Check if winit is in the dependency tree (default: should not be)
cargo tree -i winit

# Check with desktop feature (winit should appear)
cargo tree --features desktop -i winit
```

## Migration from Previous Versions

If you were using `--no-default-features` before:

**Old way:**
```bash
cargo build --no-default-features  # Required for headless
cargo build                         # Included desktop GUI
```

**New way (0.1.2+):**
```bash
cargo build                         # Headless by default
cargo build --features desktop      # Opt-in to GUI
```

## Summary

**LocalGPT now builds headless by default** - no special flags needed for Alpine, Docker, or any headless environment!

- Default: Headless (CLI + daemon + web UI)
- Opt-in: Desktop GUI via `--features desktop`

This makes Alpine and Docker deployments trivial while still supporting desktop GUI for users who want it.
