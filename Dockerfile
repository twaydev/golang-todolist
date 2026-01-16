# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Copy go mod files
COPY go.mod go.sum ./
ENV GOTOOLCHAIN=auto
RUN go mod download

# Copy source code
COPY . .

# Update go.mod and build binary
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o api app/cmd/api/main.go

# Runtime stage
FROM alpine:3.19

# Add ca-certificates, tzdata, and postgresql-client for migrations
RUN apk --no-cache add ca-certificates tzdata postgresql-client && \
    adduser -D -g '' appuser

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/api .

# Copy migrations
COPY --from=builder /build/app/migrations ./migrations/

# Copy entrypoint script
COPY --from=builder /build/scripts/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Use non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Entrypoint runs migrations, then starts the app
ENTRYPOINT ["./entrypoint.sh"]
CMD ["./api"]
