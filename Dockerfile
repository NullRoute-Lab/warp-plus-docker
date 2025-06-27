# Use a lightweight Debian image as the base
FROM debian:buster

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Download and extract the warp-plus binary
RUN curl -L -o warp-plus.zip https://github.com/bepass-org/warp-plus/releases/download/v1.2.6/warp-plus_linux-amd64.zip \
    && unzip warp-plus.zip \
    && rm warp-plus.zip

# Make the binary executable
RUN chmod +x warp-plus

# Expose the default SOCKS5 proxy port
EXPOSE 8086

# Entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["--verbose"]
