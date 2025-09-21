# Car Rental System - Docker Configuration
FROM ballerina/ballerina:2201.8.0

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy project files
COPY backend/ ./backend/
COPY frontend/ ./frontend/
COPY start_system.sh ./
COPY README.md ./

# Create necessary directories
RUN mkdir -p logs backups

# Set permissions
RUN chmod +x start_system.sh

# Switch to ballerina user
USER ballerina

# Build the Ballerina project
WORKDIR /app/backend
RUN bal build

# Expose ports
EXPOSE 8000 8080 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

# Set working directory back to app root
WORKDIR /app

# Start the system
CMD ["./start_system.sh"]