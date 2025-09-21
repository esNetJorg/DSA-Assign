#!/bin/bash

# Car Rental System Startup Script
# This script starts all components of the Car Rental System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GRPC_PORT=9090
REST_PORT=8080
FRONTEND_PORT=8000
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_color $CYAN "=================================="
    print_color $CYAN "$1"
    print_color $CYAN "=================================="
    echo
}

print_step() {
    print_color $BLUE "🔹 $1"
}

print_success() {
    print_color $GREEN "✅ $1"
}

print_error() {
    print_color $RED "❌ $1"
}

print_warning() {
    print_color $YELLOW "⚠️  $1"
}

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 1
    else
        return 0
    fi
}

# Function to kill process on port
kill_port() {
    local port=$1
    local pids=$(lsof -ti:$port)
    if [ ! -z "$pids" ]; then
        print_warning "Killing processes on port $port: $pids"
        echo $pids | xargs kill -9
        sleep 2
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    print_step "Waiting for $name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "$name failed to start within $max_attempts seconds"
    return 1
}

# Function to start gRPC server
start_grpc_server() {
    print_step "Starting gRPC Server on port $GRPC_PORT..."
    
    if ! check_port $GRPC_PORT; then
        print_warning "Port $GRPC_PORT is already in use"
        kill_port $GRPC_PORT
    fi
    
    cd $BACKEND_DIR
    
    # Check if Ballerina is installed
    if ! command -v bal &> /dev/null; then
        print_error "Ballerina is not installed or not in PATH"
        print_color $YELLOW "Please install Ballerina Swan Lake from: https://ballerina.io/downloads/"
        exit 1
    fi
    
    # Start gRPC server in background
    nohup bal run car_rental_server.bal > ../logs/grpc_server.log 2>&1 &
    echo $! > ../logs/grpc_server.pid
    
    cd ..
    
    # Wait a moment for server to start
    sleep 3
    print_success "gRPC Server started (PID: $(cat logs/grpc_server.pid))"
}

# Function to start REST gateway
start_rest_gateway() {
    print_step "Starting REST Gateway on port $REST_PORT..."
    
    if ! check_port $REST_PORT; then
        print_warning "Port $REST_PORT is already in use"
        kill_port $REST_PORT
    fi
    
    cd $BACKEND_DIR
    
    # Start REST gateway in background
    nohup bal run rest_gateway.bal > ../logs/rest_gateway.log 2>&1 &
    echo $! > ../logs/rest_gateway.pid
    
    cd ..
    
    # Wait for REST gateway to be ready
    if wait_for_service "http://localhost:$REST_PORT/api/health" "REST Gateway"; then
        print_success "REST Gateway started (PID: $(cat logs/rest_gateway.pid))"
    else
        print_error "REST Gateway failed to start"
        exit 1
    fi
}

# Function to populate demo data
populate_demo_data() {
    print_step "Populating system with demo data..."
    
    cd $BACKEND_DIR
    
    # Run demo data generator
    if bal run demo_data_generator.bal > ../logs/demo_data.log 2>&1; then
        print_success "Demo data populated successfully"
    else
        print_warning "Demo data population failed (check logs/demo_data.log)"
    fi
    
    cd ..
}

# Function to start frontend server
start_frontend() {
    print_step "Starting Frontend Server on port $FRONTEND_PORT..."
    
    if ! check_port $FRONTEND_PORT; then
        print_warning "Port $FRONTEND_PORT is already in use"
        kill_port $FRONTEND_PORT
    fi
    
    # Try different methods to serve frontend
    if command -v python3 &> /dev/null; then
        print_step "Using Python3 HTTP server..."
        cd $FRONTEND_DIR
        nohup python3 -m http.server $FRONTEND_PORT > ../logs/frontend.log 2>&1 &
        echo $! > ../logs/frontend.pid
        cd ..
    elif command -v python &> /dev/null; then
        print_step "Using Python2 HTTP server..."
        cd $FRONTEND_DIR
        nohup python -m SimpleHTTPServer $FRONTEND_PORT > ../logs/frontend.log 2>&1 &
        echo $! > ../logs/frontend.pid
        cd ..
    elif command -v npx &> /dev/null; then
        print_step "Using Node.js HTTP server..."
        cd $FRONTEND_DIR
        nohup npx http-server -p $FRONTEND_PORT > ../logs/frontend.log 2>&1 &
        echo $! > ../logs/frontend.pid
        cd ..
    else
        print_warning "No suitable HTTP server found (Python/Node.js)"
        print_warning "Please serve the frontend manually or install Python/Node.js"
        return 1
    fi
    
    # Wait for frontend to be ready
    sleep 2
    if wait_for_service "http://localhost:$FRONTEND_PORT" "Frontend Server"; then
        print_success "Frontend Server started (PID: $(cat logs/frontend.pid))"
    else
        print_error "Frontend Server failed to start"
        return 1
    fi
}

# Function to open browser
open_browser() {
    local url="http://localhost:$FRONTEND_PORT"
    
    print_step "Opening browser..."
    
    # Detect OS and open browser
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$url"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v xdg-open &> /dev/null; then
            xdg-open "$url"
        elif command -v gnome-open &> /dev/null; then
            gnome-open "$url"
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows
        start "$url"
    fi
    
    print_success "Browser should open automatically to $url"
}

# Function to display system status
display_status() {
    print_header "🎯 SYSTEM STATUS"
    
    echo "📊 Service Status:"
    if check_port $GRPC_PORT; then
        print_color $RED "   ❌ gRPC Server (Port $GRPC_PORT): NOT RUNNING"
    else
        print_color $GREEN "   ✅ gRPC Server (Port $GRPC_PORT): RUNNING"
    fi
    
    if check_port $REST_PORT; then
        print_color $RED "   ❌ REST Gateway (Port $REST_PORT): NOT RUNNING"
    else
        print_color $GREEN "   ✅ REST Gateway (Port $REST_PORT): RUNNING"
    fi
    
    if check_port $FRONTEND_PORT; then
        print_color $RED "   ❌ Frontend Server (Port $FRONTEND_PORT): NOT RUNNING"
    else
        print_color $GREEN "   ✅ Frontend Server (Port $FRONTEND_PORT): RUNNING"
    fi
    
    echo
    echo "🌐 Access URLs:"
    print_color $CYAN "   🖥️  Frontend:    http://localhost:$FRONTEND_PORT"
    print_color $CYAN "   🔌 REST API:    http://localhost:$REST_PORT/api"
    print_color $CYAN "   ⚡ gRPC Server: http://localhost:$GRPC_PORT"
    
    echo
    echo "📝 Log Files:"
    echo "   📄 gRPC Server: logs/grpc_server.log"
    echo "   📄 REST Gateway: logs/rest_gateway.log"
    echo "   📄 Frontend: logs/frontend.log"
    echo "   📄 Demo Data: logs/demo_data.log"
}

# Function to stop all services
stop_services() {
    print_header "🛑 STOPPING ALL SERVICES"
    
    # Stop frontend
    if [ -f "logs/frontend.pid" ]; then
        local pid=$(cat logs/frontend.pid)
        if ps -p $pid > /dev/null; then
            print_step "Stopping Frontend Server (PID: $pid)..."
            kill $pid
            rm -f logs/frontend.pid
        fi
    fi
    
    # Stop REST gateway
    if [ -f "logs/rest_gateway.pid" ]; then
        local pid=$(cat logs/rest_gateway.pid)
        if ps -p $pid > /dev/null; then
            print_step "Stopping REST Gateway (PID: $pid)..."
            kill $pid
            rm -f logs/rest_gateway.pid
        fi
    fi
    
    # Stop gRPC server
    if [ -f "logs/grpc_server.pid" ]; then
        local pid=$(cat logs/grpc_server.pid)
        if ps -p $pid > /dev/null; then
            print_step "Stopping gRPC Server (PID: $pid)..."
            kill $pid
            rm -f logs/grpc_server.pid
        fi
    fi
    
    # Force kill any remaining processes on our ports
    kill_port $GRPC_PORT
    kill_port $REST_PORT
    kill_port $FRONTEND_PORT
    
    print_success "All services stopped"
}

# Function to show logs
show_logs() {
    local service=$1
    
    case $service in
        "grpc"|"server")
            if [ -f "