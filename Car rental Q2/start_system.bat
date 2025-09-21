@echo off
setlocal enabledelayedexpansion

REM Car Rental System Windows Startup Script
REM This script starts all components of the Car Rental System

set GRPC_PORT=9090
set REST_PORT=8080
set FRONTEND_PORT=8000
set BACKEND_DIR=backend
set FRONTEND_DIR=frontend

echo ========================================
echo   Car Rental System - Windows Startup
echo ========================================
echo.

REM Create necessary directories
if not exist logs mkdir logs
if not exist backups mkdir backups

REM Check for command line argument
if "%1"=="stop" goto stop_services
if "%1"=="status" goto show_status
if "%1"=="logs" goto show_logs
if "%1"=="test" goto run_tests
if "%1"=="clean" goto cleanup
if "%1"=="help" goto show_help
if "%1"=="-h" goto show_help
if "%1"=="--help" goto show_help

REM Default action is start
goto start_system

:start_system
echo [INFO] Starting Car Rental System...
echo.

REM Check prerequisites
echo [INFO] Checking prerequisites...
where bal >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Ballerina is not installed or not in PATH
    echo         Please install Ballerina Swan Lake from: https://ballerina.io/downloads/
    pause
    exit /b 1
)
echo [OK] Ballerina found

where python >nul 2>&1
if not errorlevel 1 (
    echo [OK] Python found for frontend server
    set PYTHON_CMD=python
) else (
    where python3 >nul 2>&1
    if not errorlevel 1 (
        echo [OK] Python3 found for frontend server
        set PYTHON_CMD=python3
    ) else (
        echo [WARN] Python not found - you'll need to serve frontend manually
        set PYTHON_CMD=
    )
)

REM Kill any existing processes on our ports
echo [INFO] Checking for existing processes on ports...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%GRPC_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Killing process on port %GRPC_PORT% (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%REST_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Killing process on port %REST_PORT% (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%FRONTEND_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Killing process on port %FRONTEND_PORT% (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)

echo.
echo [INFO] Starting gRPC Server on port %GRPC_PORT%...
cd %BACKEND_DIR%
start /b "" bal run car_rental_server.bal > ..\logs\grpc_server.log 2>&1
cd ..
timeout /t 3 /nobreak >nul
echo [OK] gRPC Server started

echo [INFO] Starting REST Gateway on port %REST_PORT%...
cd %BACKEND_DIR%
start /b "" bal run rest_gateway.bal > ..\logs\rest_gateway.log 2>&1
cd ..
timeout /t 3 /nobreak >nul

REM Wait for REST gateway to be ready
echo [INFO] Waiting for REST Gateway to be ready...
:wait_rest
timeout /t 1 /nobreak >nul
curl -s http://localhost:%REST_PORT%/api/health >nul 2>&1
if errorlevel 1 goto wait_rest
echo [OK] REST Gateway started

echo [INFO] Populating demo data...
cd %BACKEND_DIR%
bal run demo_data_generator.bal > ..\logs\demo_data.log 2>&1
if not errorlevel 1 (
    echo [OK] Demo data populated
) else (
    echo [WARN] Demo data population may have failed
)
cd ..

if defined PYTHON_CMD (
    echo [INFO] Starting Frontend Server on port %FRONTEND_PORT%...
    cd %FRONTEND_DIR%
    start /b "" %PYTHON_CMD% -m http.server %FRONTEND_PORT% > ..\logs\frontend.log 2>&1
    cd ..
    timeout /t 2 /nobreak >nul
    echo [OK] Frontend Server started
) else (
    echo [WARN] Frontend server not started - serve manually or install Python
)

echo.
echo ========================================
echo   System Status
echo ========================================
netstat -an | find ":%GRPC_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] gRPC Server running on port %GRPC_PORT%
) else (
    echo [ERROR] gRPC Server not running
)

netstat -an | find ":%REST_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] REST Gateway running on port %REST_PORT%
) else (
    echo [ERROR] REST Gateway not running
)

netstat -an | find ":%FRONTEND_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] Frontend Server running on port %FRONTEND_PORT%
) else (
    echo [WARN] Frontend Server not running
)

echo.
echo Access URLs:
echo   Frontend:    http://localhost:%FRONTEND_PORT%
echo   REST API:    http://localhost:%REST_PORT%/api
echo   gRPC Server: http://localhost:%GRPC_PORT%
echo.
echo Log files available in: logs\
echo.

set /p OPEN_BROWSER="Open browser automatically? (y/n): "
if /i "%OPEN_BROWSER%"=="y" start http://localhost:%FRONTEND_PORT%

echo [INFO] Car Rental System is now running!
echo [INFO] Press Ctrl+C to stop or run: %~nx0 stop
echo.
goto end

:stop_services
echo [INFO] Stopping all services...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%GRPC_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Stopping gRPC Server (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%REST_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Stopping REST Gateway (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%FRONTEND_PORT%" ^| find "LISTENING"') do (
    echo [INFO] Stopping Frontend Server (PID: %%a)
    taskkill /PID %%a /F >nul 2>&1
)
echo [OK] All services stopped
goto end

:show_status
echo ========================================
echo   System Status
echo ========================================
netstat -an | find ":%GRPC_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] gRPC Server running on port %GRPC_PORT%
) else (
    echo [ERROR] gRPC Server not running
)

netstat -an | find ":%REST_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] REST Gateway running on port %REST_PORT%
) else (
    echo [ERROR] REST Gateway not running
)

netstat -an | find ":%FRONTEND_PORT%" | find "LISTENING" >nul
if not errorlevel 1 (
    echo [OK] Frontend Server running on port %FRONTEND_PORT%
) else (
    echo [ERROR] Frontend Server not running
)
echo.
goto end

:show_logs
if "%2"=="" (
    echo [INFO] Showing all logs...
    for %%f in (logs\*.log) do (
        echo.
        echo ========================================
        echo   %%f
        echo ========================================
        type "%%f" 2>nul | more
    )
) else (
    if exist "logs\%2.log" (
        echo [INFO] Showing %2 logs...
        type "logs\%2.log" | more
    ) else (
        echo [ERROR] Log file logs\%2.log not found
    )
)
goto end

:run_tests
echo [INFO] Running tests...
cd %BACKEND_DIR%
bal run test_client.bal > ..\logs\test_results.log 2>&1
if not errorlevel 1 (
    echo [OK] Tests completed successfully
) else (
    echo [ERROR] Some tests failed
)
echo [INFO] Test results saved to logs\test_results.log
type ..\logs\test_results.log | more
cd ..
goto end

:cleanup
echo [INFO] Cleaning up...
del /q logs\*.log >nul 2>&1
del /q logs\*.pid >nul 2>&1
del /q *.tmp >nul 2>&1
del /q nohup.out >nul 2>&1
echo [OK] Cleanup completed
goto end

:show_help
echo Car Rental System - Windows Startup Script
echo.
echo Usage: %~nx0 [COMMAND]
echo.
echo Commands:
echo   start    Start all services (default)
echo   stop     Stop all services
echo   status   Show system status
echo   logs     Show all logs
echo   test     Run test suite
echo   clean    Clean logs and temporary files
echo   help     Show this help
echo.
echo Examples:
echo   %~nx0           Start the system
echo   %~nx0 stop      Stop all services
echo   %~nx0 status    Check status
echo   %~nx0 logs      Show logs
echo.
echo System Requirements:
echo   - Ballerina Swan Lake (2201.8.0+)
echo   - Python (for frontend server)
echo   - curl (for health checks)
echo.
echo Ports Used:
echo   - %GRPC_PORT% - gRPC Server
echo   - %REST_PORT% - REST API Gateway
echo   - %FRONTEND_PORT% - Frontend Web Server
echo.
goto end

:end
echo.
pause