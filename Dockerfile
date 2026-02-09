# LocalGPT Dockerfile (Debian-based, Headless)
# Builds headless by default - no X11/Wayland dependencies needed!
# More compatible but larger than Alpine variant

FROM rust:1-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Copy source code
COPY src ./src
COPY config.example.toml ./

# Build (headless by default - no special flags needed!)
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /build/target/release/localgpt /usr/local/bin/localgpt

# Create workspace directory
RUN mkdir -p /root/.localgpt/workspace

# Expose HTTP server port (default: 31327)
EXPOSE 31327

# Set working directory
WORKDIR /root/.localgpt

# Default command: start daemon with HTTP server
ENTRYPOINT ["localgpt"]
CMD ["daemon", "start"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD localgpt daemon status || exit 1

# Usage examples:
# 
# Build:
#   docker build -t localgpt .
#
# Run daemon (mount config and workspace):
#   docker run -d \
#     -v ~/.localgpt:/root/.localgpt \
#     -p 31327:31327 \
#     --name localgpt \
#     localgpt
#
# Run interactive chat:
#   docker run -it --rm \
#     -v ~/.localgpt:/root/.localgpt \
#     localgpt chat
#
# One-off query:
#   docker run --rm \
#     -v ~/.localgpt:/root/.localgpt \
#     localgpt ask "What is Rust?"
