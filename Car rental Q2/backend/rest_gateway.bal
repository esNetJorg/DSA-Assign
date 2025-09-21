import ballerina/http;
import ballerina/log;
import ballerina/time;

// Simple gRPC client simulation (in real implementation, use generated gRPC client)
type CarRentalServiceClient client object {
    public function init(string url) returns error? {
        // Initialize gRPC client connection
    }
    
    remote function AddCar(AddCarRequest request) returns AddCarResponse|error {
        // Simulate gRPC call - in real implementation, this would be actual gRPC
        return simulateAddCar(request);
    }
    
    remote function CreateUsers(CreateUsersRequest request) returns CreateUsersResponse|error {
        return simulateCreateUsers(request);
    }
    
    remote function UpdateCar(UpdateCarRequest request) returns UpdateCarResponse|error {
        return simulateUpdateCar(request);
    }
    
    remote function RemoveCar(RemoveCarRequest request) returns RemoveCarResponse|error {
        return simulateRemoveCar(request);
    }
    
    remote function ListReservations(ListReservationsRequest request) returns stream<Reservation, error?>|error {
        return simulateListReservations(request);
    }
    
    remote function ListAvailableCars(ListAvailableCarsRequest request) returns stream<Car, error?>|error {
        return simulateListAvailableCars(request);
    }
    
    remote function SearchCar(SearchCarRequest request) returns SearchCarResponse|error {
        return simulateSearchCar(request);
    }
    
    remote function AddToCart(AddToCartRequest request) returns AddToCartResponse|error {
        return simulateAddToCart(request);
    }
    
    remote function PlaceReservation(PlaceReservationRequest request) returns PlaceReservationResponse|error {
        return simulatePlaceReservation(request);
    }
};

// Simulated in-memory storage for REST gateway
map<Car> restCars = {};
map<User> restUsers = {};
map<CartItem[]> restCustomerCarts = {};
map<Reservation> restReservations = {};

// Initialize with some demo data
function initializeDemoData() {
    // Add demo cars
    restCars["TOY001"] = {
        plate: "TOY001",
        make: "Toyota",
        model: "Corolla",
        year: 2023,
        daily_price: 45.0,
        mileage: 12000,
        status: AVAILABLE,
        created_at: time:utcToString(time:utcNow())
    };
    
    restCars["HON001"] = {
        plate: "HON001",
        make: "Honda",
        model: "Civic",
        year: 2023,
        daily_price: 48.0,
        mileage: 15000,
        status: AVAILABLE,
        created_at: time:utcToString(time:utcNow())
    };
    
    restCars["BMW001"] = {
        plate: "BMW001",
        make: "BMW",
        model: "320i",
        year: 2024,
        daily_price: 120.0,
        mileage: 3000,
        status: AVAILABLE,
        created_at: time:utcToString(time:utcNow())
    };
    
    // Add demo users
    restUsers["admin1"] = {
        user_id: "admin1",
        name: "Admin User",
        email: "admin@carrental.com",
        role: ADMIN,
        created_at: time:utcToString(time:utcNow())
    };
    
    restUsers["customer1"] = {
        user_id: "customer1",
        name: "John Doe",
        email: "john@example.com",
        role: CUSTOMER,
        created_at: time:utcToString(time:utcNow())
    };
    
    // Initialize empty carts
    restCustomerCarts["customer1"] = [];
}

// Simulation functions
function simulateAddCar(AddCarRequest request) returns AddCarResponse|error {
    if restCars.hasKey(request.plate) {
        return {
            success: false,
            message: "Car with plate " + request.plate + " already exists",
            car_id: ""
        };
    }
    
    Car newCar = {
        plate: request.plate,
        make: request.make,
        model: request.model,
        year: request.year,
        daily_price: request.daily_price,
        mileage: request.mileage,
        status: request.status,
        created_at: time:utcToString(time:utcNow())
    };
    
    restCars[request.plate] = newCar;
    
    return {
        success: true,
        message: "Car added successfully",
        car_id: request.plate
    };
}

function simulateCreateUsers(CreateUsersRequest request) returns CreateUsersResponse|error {
    int created_count = 0;
    
    foreach User user in request.users {
        if !restUsers.hasKey(user.user_id) {
            User newUser = {
                user_id: user.user_id,
                name: user.name,
                email: user.email,
                role: user.role,
                created_at: time:utcToString(time:utcNow())
            };
            restUsers[user.user_id] = newUser;
            restCustomerCarts[user.user_id] = [];
            created_count += 1;
        }
    }
    
    return {
        success: true,
        message: created_count.toString() + " users created successfully",
        users_created: created_count
    };
}

function simulateUpdateCar(UpdateCarRequest request) returns UpdateCarResponse|error {
    if !restCars.hasKey(request.plate) {
        return {
            success: false,
            message: "Car with plate " + request.plate + " not found",
            updated_car: {
                plate: "",
                make: "",
                model: "",
                year: 0,
                daily_price: 0.0,
                mileage: 0,
                status: AVAILABLE,
                created_at: ""
            }
        };
    }
    
    Car existingCar = restCars.get(request.plate);
    Car updatedCar = {
        plate: existingCar.plate,
        make: request.make ?: existingCar.make,
        model: request.model ?: existingCar.model,
        year: request.year ?: existingCar.year,
        daily_price: request.daily_price ?: existingCar.daily_price,
        mileage: request.mileage ?: existingCar.mileage,
        status: request.status ?: existingCar.status,
        created_at: existingCar.created_at
    };
    
    restCars[request.plate] = updatedCar;
    
    return {
        success: true,
        message: "Car updated successfully",
        updated_car: updatedCar
    };
}

function simulateRemoveCar(RemoveCarRequest request) returns RemoveCarResponse|error {
    if !restCars.hasKey(request.plate) {
        return {
            success: false,
            message: "Car with plate " + request.plate + " not found",
            remaining_cars: restCars.values()
        };
    }
    
    _ = restCars.remove(request.plate);
    
    return {
        success: true,
        message: "Car removed successfully",
        remaining_cars: restCars.values()
    };
}

function simulateListReservations(ListReservationsRequest request) returns stream<Reservation, error?>|error {
    Reservation[] filtered_reservations = [];
    
    foreach Reservation reservation in restReservations.values() {
        if request.customer_id is () || reservation.customer_id == request.customer_id {
            filtered_reservations.push(reservation);
        }
    }
    
    return filtered_reservations.toStream();
}

function simulateListAvailableCars(ListAvailableCarsRequest request) returns stream<Car, error?>|error {
    Car[] available_cars = [];
    
    foreach Car car in restCars.values() {
        if car.status == AVAILABLE {
            boolean include = true;
            
            if request.filter_text is string {
                string filter = request.filter_text.toLowerAscii();
                string carInfo = (car.make + " " + car.model).toLowerAscii();
                include = carInfo.includes(filter);
            }
            
            if request.year_filter is int && car.year != request.year_filter {
                include = false;
            }
            
            if include {
                available_cars.push(car);
            }
        }
    }
    
    return available_cars.toStream();
}

function simulateSearchCar(SearchCarRequest request) returns SearchCarResponse|error {
    if !restCars.hasKey(request.plate) {
        return {
            found: false,
            car: {
                plate: "",
                make: "",
                model: "",
                year: 0,
                daily_price: 0.0,
                mileage: 0,
                status: AVAILABLE,
                created_at: ""
            },
            message: "Car with plate " + request.plate + " not found"
        };
    }
    
    Car car = restCars.get(request.plate);
    if car.status != AVAILABLE {
        return {
            success: false,
            message: "Car is not available",
            cart_item: {
                plate: "",
                start_date: "",
                end_date: "",
                estimated_price: 0.0
            }
        };
    }
    
    // Simple date validation
    if request.start_date.length() != 10 || request.end_date.length() != 10 {
        return {
            success: false,
            message: "Invalid date format",
            cart_item: {
                plate: "",
                start_date: "",
                end_date: "",
                estimated_price: 0.0
            }
        };
    }
    
    // Calculate estimated price (simplified)
    int days = 3; // Simplified calculation
    float estimated_price = <float>days * car.daily_price;
    
    CartItem cartItem = {
        plate: request.plate,
        start_date: request.start_date,
        end_date: request.end_date,
        estimated_price: estimated_price
    };
    
    // Add to customer's cart
    CartItem[] cart = restCustomerCarts.get(request.customer_id);
    cart.push(cartItem);
    restCustomerCarts[request.customer_id] = cart;
    
    return {
        success: true,
        message: "Car added to cart successfully",
        cart_item: cartItem
    };
}

function simulatePlaceReservation(PlaceReservationRequest request) returns PlaceReservationResponse|error {
    if !restUsers.hasKey(request.customer_id) {
        return {
            success: false,
            message: "Customer not found",
            reservations: [],
            total_amount: 0.0
        };
    }
    
    CartItem[] cart = restCustomerCarts.get(request.customer_id);
    if cart.length() == 0 {
        return {
            success: false,
            message: "Cart is empty",
            reservations: [],
            total_amount: 0.0
        };
    }
    
    Reservation[] new_reservations = [];
    float total_amount = 0.0;
    
    // Process each item in cart
    foreach CartItem item in cart {
        string reservation_id = "RES-" + time:utcToString(time:utcNow()).substring(0, 10);
        Reservation reservation = {
            reservation_id: reservation_id,
            customer_id: request.customer_id,
            plate: item.plate,
            start_date: item.start_date,
            end_date: item.end_date,
            total_price: item.estimated_price,
            status: "CONFIRMED",
            created_at: time:utcToString(time:utcNow())
        };
        
        restReservations[reservation_id] = reservation;
        new_reservations.push(reservation);
        total_amount += item.estimated_price;
    }
    
    // Clear the cart
    restCustomerCarts[request.customer_id] = [];
    
    return {
        success: true,
        message: "Reservations placed successfully",
        reservations: new_reservations,
        total_amount: total_amount
    };
}

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5500", "*"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}
service /api on new http:Listener(8080) {

    function init() {
        initializeDemoData();
        log:printInfo("REST Gateway initialized with demo data");
    }

    // Health check endpoint
    resource function get health() returns json {
        return {
            status: "UP",
            service: "Car Rental REST Gateway",
            timestamp: time:utcToString(time:utcNow())
        };
    }

    // Admin: Add car
    resource function post admin/cars(@http:Payload json carData) returns json|error {
        AddCarRequest request = {
            make: check carData.make,
            model: check carData.model,
            year: check carData.year,
            daily_price: check carData.daily_price,
            mileage: check carData.mileage,
            plate: check carData.plate,
            status: AVAILABLE
        };
        
        AddCarResponse response = check simulateAddCar(request);
        
        return {
            success: response.success,
            message: response.message,
            data: {
                car_id: response.car_id
            }
        };
    }

    // Admin: Create users
    resource function post admin/users(@http:Payload json userData) returns json|error {
        json[] usersJson = check userData.users;
        User[] users = [];
        
        foreach json userJson in usersJson {
            User user = {
                user_id: check userJson.user_id,
                name: check userJson.name,
                email: check userJson.email,
                role: check userJson.role == "ADMIN" ? ADMIN : CUSTOMER,
                created_at: ""
            };
            users.push(user);
        }
        
        CreateUsersRequest request = {users: users};
        CreateUsersResponse response = check simulateCreateUsers(request);
        
        return {
            success: response.success,
            message: response.message,
            data: {
                users_created: response.users_created
            }
        };
    }

    // Admin: Update car
    resource function put admin/cars/[string plate](@http:Payload json updateData) returns json|error {
        UpdateCarRequest request = {
            plate: plate,
            make: updateData.make is json ? check updateData.make : (),
            model: updateData.model is json ? check updateData.model : (),
            year: updateData.year is json ? check updateData.year : (),
            daily_price: updateData.daily_price is json ? check updateData.daily_price : (),
            mileage: updateData.mileage is json ? check updateData.mileage : (),
            status: updateData.status is json ? AVAILABLE : ()
        };
        
        UpdateCarResponse response = check simulateUpdateCar(request);
        
        return {
            success: response.success,
            message: response.message,
            data: response.updated_car
        };
    }

    // Admin: Remove car
    resource function delete admin/cars/[string plate]() returns json|error {
        RemoveCarRequest request = {plate: plate};
        RemoveCarResponse response = check simulateRemoveCar(request);
        
        return {
            success: response.success,
            message: response.message,
            data: {
                remaining_cars: response.remaining_cars
            }
        };
    }

    // Admin: List all reservations
    resource function get admin/reservations(string? customer_id) returns json|error {
        ListReservationsRequest request = {customer_id: customer_id};
        stream<Reservation, error?> reservationStream = check simulateListReservations(request);
        
        Reservation[] reservations = [];
        error? result = reservationStream.forEach(function(Reservation reservation) {
            reservations.push(reservation);
        });
        
        if result is error {
            return {
                success: false,
                message: "Failed to fetch reservations",
                data: []
            };
        }
        
        return {
            success: true,
            message: "Reservations retrieved successfully",
            data: reservations
        };
    }

    // Customer: List available cars
    resource function get cars(string? filter_text, int? year_filter) returns json|error {
        ListAvailableCarsRequest request = {
            filter_text: filter_text,
            year_filter: year_filter
        };
        
        stream<Car, error?> carStream = check simulateListAvailableCars(request);
        
        Car[] cars = [];
        error? result = carStream.forEach(function(Car car) {
            cars.push(car);
        });
        
        if result is error {
            return {
                success: false,
                message: "Failed to fetch cars",
                data: []
            };
        }
        
        return {
            success: true,
            message: "Cars retrieved successfully",
            data: cars
        };
    }

    // Customer: Search specific car
    resource function get cars/[string plate]() returns json|error {
        SearchCarRequest request = {plate: plate};
        SearchCarResponse response = check simulateSearchCar(request);
        
        return {
            success: response.found,
            message: response.message,
            data: response.car
        };
    }

    // Customer: Add to cart
    resource function post customers/[string customer_id]/cart(@http:Payload json cartData) returns json|error {
        AddToCartRequest request = {
            customer_id: customer_id,
            plate: check cartData.plate,
            start_date: check cartData.start_date,
            end_date: check cartData.end_date
        };
        
        AddToCartResponse response = check simulateAddToCart(request);
        
        return {
            success: response.success,
            message: response.message,
            data: response.cart_item
        };
    }

    // Customer: Place reservation
    resource function post customers/[string customer_id]/reservations() returns json|error {
        PlaceReservationRequest request = {customer_id: customer_id};
        PlaceReservationResponse response = check simulatePlaceReservation(request);
        
        return {
            success: response.success,
            message: response.message,
            data: {
                reservations: response.reservations,
                total_amount: response.total_amount
            }
        };
    }

    // Get customer's cart (mock endpoint)
    resource function get customers/[string customer_id]/cart() returns json {
        CartItem[] cart = restCustomerCarts.get(customer_id) ?: [];
        float total = 0.0;
        
        foreach CartItem item in cart {
            total += item.estimated_price;
        }
        
        return {
            success: true,
            message: "Cart retrieved successfully",
            data: {
                items: cart,
                total_items: cart.length(),
                estimated_total: total
            }
        };
    }

    // System stats endpoint
    resource function get admin/stats() returns json|error {
        Car[] allCars = restCars.values();
        Reservation[] allReservations = restReservations.values();
        
        int available_cars = 0;
        int rented_cars = 0;
        int unavailable_cars = 0;
        
        foreach Car car in allCars {
            if car.status == AVAILABLE {
                available_cars += 1;
            } else if car.status == RENTED {
                rented_cars += 1;
            } else {
                unavailable_cars += 1;
            }
        }
        
        float total_revenue = 0.0;
        int confirmed_reservations = 0;
        
        foreach Reservation reservation in allReservations {
            if reservation.status == "CONFIRMED" {
                confirmed_reservations += 1;
                total_revenue += reservation.total_price;
            }
        }
        
        return {
            success: true,
            message: "Stats retrieved successfully",
            data: {
                total_cars: allCars.length(),
                available_cars: available_cars,
                rented_cars: rented_cars,
                unavailable_cars: unavailable_cars,
                total_reservations: allReservations.length(),
                confirmed_reservations: confirmed_reservations,
                total_revenue: total_revenue
            }
        };
    }
}

public function main() {
    log:printInfo("Car Rental REST Gateway started on http://localhost:8080");
}
    
    if car.status != AVAILABLE {
        return {
            found: false,
            car: car,
            message: "Car with plate " + request.plate + " is not available"
        };
    }
    
    return {
        found: true,
        car: car,
        message: "Car found and available"
    };
}

function simulateAddToCart(AddToCartRequest request) returns AddToCartResponse|error {
    if !restUsers.hasKey(request.customer_id) {
        return {
            success: false,
            message: "Customer not found",
            cart_item: {
                plate: "",
                start_date: "",
                end_date: "",
                estimated_price: 0.0
            }
        };
    }
    
    if !restCars.hasKey(request.plate) {
        return {
            success: false,
            message: "Car not found",
            cart_item: {
                plate: "",
                start_date: "",
                end_date: "",
                estimated_price: 0.0
            }
        };
    }
    
    Car car
