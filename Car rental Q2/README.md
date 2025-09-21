Car rental management system built with **gRPC**, **Ballerina**, and modern **HTML/CSS/JavaScript** frontend.

![Car Rental System](https://img.shields.io/badge/Car_Rental-System-blue?style=for-the-badge&logo=car)
![Ballerina](https://img.shields.io/badge/Ballerina-2201.8.0-green?style=for-the-badge)
![gRPC](https://img.shields.io/badge/gRPC-Protocol-orange?style=for-the-badge)
![HTML5](https://img.shields.io/badge/HTML5-Frontend-red?style=for-the-badge&logo=html5)

## 🌟 Features

### 👨‍💼 **Admin Features**
- **Car Inventory Management**: Add, edit, delete, and update car details
- **User Management**: Create and manage customer and admin accounts
- **Reservation Overview**: View all bookings with filtering options
- **System Analytics**: Real-time dashboard with statistics and metrics
- **Bulk Operations**: Batch user creation and inventory management

### 👤 **Customer Features**
- **Car Browsing**: Search and filter available vehicles
- **Smart Cart**: Add multiple cars with different rental periods
- **Reservation System**: Convert cart items to confirmed bookings
- **Booking History**: Track current and past reservations
- **Price Calculator**: Dynamic pricing based on rental duration

### 🎨 **Modern UI/UX**
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile
- **Role-Based Interface**: Dynamic navigation and features based on user role
- **Real-Time Updates**: Auto-refresh data every 30 seconds
- **Interactive Components**: Modals, notifications, and smooth animations
- **Accessibility**: WCAG compliant with keyboard navigation support

## 🏗️ **System Architecture**

```
┌─────────────────────────────────┐
│    Frontend (HTML/CSS/JS)       │
│    Port: 8000                   │
└─────────────┬───────────────────┘
              │ HTTP/REST
              ▼
┌─────────────────────────────────┐
│    REST API Gateway             │
│    Port: 8080                   │
└─────────────┬───────────────────┘
              │ gRPC/Protocol Buffers
              ▼
┌─────────────────────────────────┐
│    gRPC Server                  │
│    Port: 9090                   │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│    In-Memory Data Store         │
│    (Cars, Users, Reservations)  │
└─────────────────────────────────┘
```

## 🚀 **Quick Start**

### Prerequisites
- **Ballerina Swan Lake** (2201.8.0+) - [Download](https://ballerina.io/downloads/)
- **Python 3** or **Node.js** (for frontend server)
- **curl** (for API health checks)

### Installation

1. **Clone or download the project:**
```bash
# Create project structure
mkdir car_rental_system
cd car_rental_system
```

2. **Setup project files:**
```
car_rental_system/
├── backend/
│   ├── Ballerina.toml
│   ├── car_rental.proto
│   ├── car_rental_server.bal
│   ├── rest_gateway.bal
│   ├── server_utils.bal
│   ├── test_client.bal
│   └── demo_data_generator.bal
├── frontend/
│   ├── index.html
│   ├── styles.css
│   └── script.js
├── start_system.sh (Linux/Mac)
├── start_system.bat (Windows)
└── README.md
```

3. **Start the system:**

**Linux/Mac:**
```bash
chmod +x start_system.sh
./start_system.sh
```

**Windows:**
```cmd
start_system.bat
```

4. **Access the application:**
- **🖥️ Frontend**: http://localhost:8000
- **🔌 REST API**: http://localhost:8080/api
- **⚡ gRPC Server**: http://localhost:9090

## 📋 **Available Commands**

### Linux/Mac (start_system.sh)
```bash
./start_system.sh start      # Start all services
./start_system.sh stop       # Stop all services
./start_system.sh status     # Show system status
./start_system.sh logs       # Show all logs
./start_system.sh test       # Run test suite
./start_system.sh clean      # Clean temporary files
./start_system.sh help       # Show help
```

### Windows (start_system.bat)
```cmd
start_system.bat start       # Start all services
start_system.bat stop        # Stop all services
start_system.bat status      # Show system status
start_system.bat logs        # Show all logs
start_system.bat test        # Run test suite
start_system.bat clean       # Clean temporary files
start_system.bat help        # Show help
```

## 🧪 **Testing**

The system includes comprehensive testing:

```bash
# Run all tests
./start_system.sh test

# Manual testing checklist:
# ✅ Switch between Admin/Customer roles
# ✅ Add, edit, delete cars (Admin)
# ✅ Browse and search cars (Customer)
# ✅ Add cars to cart and place reservations
# ✅ View reservations and statistics
# ✅ Test responsive design on mobile
```

## 📊 **Sample Data**

The system comes with pre-populated demo data:

**🚗 Cars (22 vehicles):**
- Economy: Toyota Corolla, Honda Civic, Nissan Sentra
- Mid-Size: Toyota Camry, Honda Accord, Mazda6
- SUVs: Toyota RAV4, Honda CR-V, Ford Explorer
- Luxury: BMW 320i, Mercedes C-Class, Audi A4
- Sports: Ford Mustang, Chevrolet Camaro
- Electric: Tesla Model 3, Tesla Model Y, Nissan Leaf

**👥 Users:**
- **Admins**: admin1 (Alice Johnson), admin2 (Bob Manager)
- **Customers**: customer1-5 (John, Jane, Mike, Sarah, David)

**📅 Sample Reservations:**
- Multiple confirmed bookings with different date ranges
- Revenue tracking and statistics

## 🔧 **Configuration**

### Port Configuration
```javascript
// In script.js
const API_BASE = 'http://localhost:8080/api';

// In startup scripts
GRPC_PORT=9090      # gRPC Server
REST_PORT=8080      # REST Gateway
FRONTEND_PORT=8000  # Web Server
```

### Backend Configuration
```toml
# Ballerina.toml
[package]
org = "carrental"
name = "car_rental_system"
version = "0.1.0"
distribution = "2201.8.0"
```

## 📁 **File Structure Details**

### Backend Files
- **`car_rental.proto`**: Protocol Buffer definitions
- **`car_rental_server.bal`**: Main gRPC server implementation
- **`rest_gateway.bal`**: HTTP-to-gRPC bridge
- **`server_utils.bal`**: Utility functions and helpers
- **`test_client.bal`**: Comprehensive test suite
- **`demo_data_generator.bal`**: Sample data population

### Frontend Files
- **`index.html`**: Main application structure
- **`styles.css`**: Modern responsive styling
- **`script.js`**: Complete application logic

### Configuration Files
- **`Ballerina.toml`**: Project dependencies and settings
- **`start_system.sh/.bat`**: Cross-platform startup scripts

## 🛠️ **Development**

### Adding New Features

1. **Backend (gRPC):**
   - Update `car_rental.proto` with new messages/services
   - Implement in `car_rental_server.bal`
   - Add REST endpoints in `rest_gateway.bal`

2. **Frontend:**
   - Add UI components in `index.html`
   - Style with `styles.css`
   - Implement logic in `script.js`

### Database Integration
Currently uses in-memory storage. To add database:

```ballerina
// Replace in-memory maps with database calls
map<Car> cars = {};  // → Database queries
map<User> users = {};
map<Reservation> reservations = {};
```

## 🚨 **Troubleshooting**

### Common Issues

**1. Port Already in Use**
```bash
# Linux/Mac
lsof -ti:9090 | xargs kill -9

# Windows
netstat -ano | findstr :9090
taskkill /PID <PID> /F
```

**2. Ballerina Not Found**
```bash
# Verify installation
bal version

# Download from: https://ballerina.io/downloads/
```

**3. Frontend Not Loading**
```bash
# Serve manually with Python
cd frontend
python3 -m http.server 8000

# Or with Node.js
npx http-server -p 8000
```

**4. CORS Issues**
- Ensure `rest_gateway.bal` includes your domain in `allowOrigins`
- Use proper HTTP server (not file:// protocol)

### Log Files
Check logs for debugging:
- `logs/grpc_server.log` - gRPC server logs
- `logs/rest_gateway.log` - REST API logs  
- `logs/frontend.log` - Web server logs
- `logs/demo_data.log` - Data population logs
- `logs/test_results.log` - Test execution results

## 🎯 **API Documentation**

### REST Endpoints

**Cars:**
- `GET /api/cars` - List available cars
- `POST /api/admin/cars` - Add new car
- `PUT /api/admin/cars/{plate}` - Update car
- `DELETE /api/admin/cars/{plate}` - Delete car

**Users:**
- `POST /api/admin/users` - Create users

**Reservations:**
- `GET /api/admin/reservations` - List reservations
- `POST /api/customers/{id}/cart` - Add to cart
- `POST /api/customers/{id}/reservations` - Place reservation

**System:**
- `GET /api/health` - Health check
- `GET /api/admin/stats` - System statistics

### gRPC Services
- `AddCar` - Register new vehicle
- `CreateUsers` - Batch user creation
- `ListAvailableCars` - Stream available cars
- `AddToCart` - Add rental to cart
- `PlaceReservation` - Confirm booking
- And more... (see `car_rental.proto`)

## 🏆 **Production Deployment**

### Performance Optimization
- Enable gzip compression
- Implement caching strategies
- Use connection pooling
- Add monitoring and logging

### Security Enhancements
- Add authentication (JWT tokens)
- Implement rate limiting
- Use HTTPS in production
- Validate and sanitize inputs

### Scalability
- Replace in-memory storage with database
- Add load balancing
- Implement microservices architecture
- Use container orchestration (Docker/K8s)

## 🙏 **Acknowledgments**

- **Ballerina** - For the excellent gRPC and HTTP support
- **Font Awesome** - For the beautiful icons
- **gRPC** - For efficient client-server communication
- **Protocol Buffers** - For structured data serialization

---

