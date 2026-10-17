FROM ubuntu:22.04

LABEL maintainer="FreeRTOS Build Team"
LABEL description="FreeRTOS multi-architecture build environment"

# Set non-interactive mode to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ===== INSTALL DEPENDENCIES =====
RUN apt-get update && apt-get install -y \
    # ARM cross-compilers
    gcc-arm-none-eabi \
    gcc-arm-linux-gnueabihf \
    binutils-arm-none-eabi \
    binutils-arm-linux-gnueabihf \
    \
    # Build tools
    cmake \
    build-essential \
    make \
    autoconf \
    automake \
    libtool \
    \
    # Development utilities
    git \
    curl \
    wget \
    ca-certificates \
    \
    # Diagnostics
    file \
    gdb-arm-none-eabi \
    \
    && rm -rf /var/lib/apt/lists/*

# ===== CREATE NON-ROOT USER =====
RUN useradd -m -s /bin/bash -u 1000 builder && \
    mkdir -p /home/builder/project && \
    chown -R builder:builder /home/builder

# ===== SETUP ENVIRONMENT =====
COPY freertos-env.sh /opt/
RUN chmod +x /opt/freertos-env.sh

# Set working directory
WORKDIR /home/builder/project

# Switch to non-root user
USER builder

# ===== DEFAULT COMMAND =====
CMD ["/bin/bash"]
