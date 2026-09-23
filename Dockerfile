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

# Configure Flutter & pre-download Web engine artifacts
RUN flutter config --no-analytics \
    && dart --disable-analytics \
    && flutter precache --web

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

# ==========================================
# Stage 3: Web Application Release Builder
# ==========================================
FROM dev AS builder

ARG BASE_HREF="/"
RUN flutter build web --release --base-href ${BASE_HREF}

# ==========================================
# Stage 4: Production Nginx Web Server
# ==========================================
FROM nginx:1.27-alpine AS production

# Remove default nginx html
RUN rm -rf /usr/share/nginx/html/*

# Copy custom Nginx configuration optimized for Flutter SPA
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled web assets from builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose standard HTTP port
EXPOSE 80

# Health check to ensure service availability
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1:80/health || exit 1

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
