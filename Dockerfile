# ==========================================
# Stage 1: Flutter SDK Base Environment
# ==========================================
FROM debian:bookworm-slim AS flutter-base

ARG FLUTTER_CHANNEL=stable
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Install minimal system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libglu1-mesa \
    libsqlite3-dev \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK with depth 1
RUN git clone --depth 1 --branch ${FLUTTER_CHANNEL} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME}

# Configure Flutter
RUN flutter config --no-analytics \
    && dart --disable-analytics

# ==========================================
# Stage 2: Development & CI/Testing Target
# ==========================================
FROM flutter-base AS dev

WORKDIR /app
RUN git config --global --add safe.directory /app

# Cache dependencies layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application source
COPY . .

# Default command runs test suite
CMD ["flutter", "test"]
