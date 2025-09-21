import ballerina/grpc;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Generated types from protobuf (you'll need to generate these using Ballerina gRPC tools)
public type Car record {
    string plate;
    string make;
    string model;
    int year;
    float daily_price;
    int mileage;
    CarStatus status;
    string created_at;
};

public type User record {
    string user_id;
    string name;
    string email;
    UserRole role;
    string created_at;
};

public type CartItem record {
    string plate;
    string start_date;
    string end_date;
    float estimated_price;
};

public type Reservation record {
    string reservation_id;
    string customer_id;
    string plate;
    string start_date;
    string end_date;
    float total_price;
    string status;
    string created_at;
};

public enum CarStatus {
    AVAILABLE,
    UNAVAILABLE,
    RENTED
}

public enum UserRole {
    CUSTOMER,
    ADMIN
}

// In-memory data storage
map<Car> cars = {};
map<User> users = {};
map<CartItem[]> customerCarts = {};  // customer_id -> cart items
map<Reservation> reservations = {};

// Service implementation
@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR, descMap: getDescriptorMap()}
service "CarRentalService" on new grpc:Listener(9090) {

    // Admin: Add a new car to the system
    remote function AddCar(AddCarRequest request) returns AddCarResponse|error {
        log:printInfo("Adding new car with plate: " + request.plate);
        
        // Check if car already exists
        if cars.hasKey(request.plate) {
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
        
        cars[request.plate] = newCar;
        
        return {
            success: true,
            message: "Car added successfully",
            car_id: request.plate
        };
    }
    
    // Admin: Create multiple users
    remote function CreateUsers(CreateUsersRequest request) returns CreateUsersResponse|error {
        log:printInfo("Creating " + request.users.length().toString() + " users");
        
        int created_count = 0;
        foreach User user in request.users {
            if !users.hasKey(user.user_id) {
                User newUser = {
                    user_id: user.user_id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    created_at: time:utcToString(time:utcNow())
                };
                users[user.user_id] = newUser;
                customerCarts[user.user_id] = [];  // Initialize empty cart
                created_count += 1;
            }
        }
        
        return {
            success: true,
            message: created_count.toString() + " users created successfully",
            users_created: created_count
        };
    }
    
    // Admin: Update car details
    remote function UpdateCar(UpdateCarRequest request) returns UpdateCarResponse|error {
        log:printInfo("Updating car with plate: " + request.plate);
        
        if !cars.hasKey(request.plate) {
            return {
                success: false,
                message: "Car with plate " + request.plate + " not found",
                updated_car: {}
            };
        }
        
        Car existingCar = cars.get(request.plate);
        
        // Update fields if provided
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
        
        cars[request.plate] = updatedCar;
        
        return {
            success: true,
            message: "Car updated successfully",
            updated_car: updatedCar
        };
    }
    
    // Admin: Remove a car from inventory
    remote function RemoveCar(RemoveCarRequest request) returns RemoveCarResponse|error {
        log:printInfo("Removing car with plate: " + request.plate);
        
        if !cars.hasKey(request.plate) {
            return {
                success: false,
                message: "Car with plate " + request.plate + " not found",
                remaining_cars: cars.values()
            };
        }
        
        _ = cars.remove(request.plate);
        
        return {
            success: true,
            message: "Car removed successfully",
            remaining_cars: cars.values()
        };
    }
    
    // Admin: List all reservations (streaming)
    remote function ListReservations(ListReservationsRequest request) returns stream<Reservation, error?>|error {
        log:printInfo("Listing reservations");
        
        Reservation[] filtered_reservations = [];
        
        foreach Reservation reservation in reservations.values() {
            if request.customer_id is () || reservation.customer_id == request.customer_id {
                filtered_reservations.push(reservation);
            }
        }
        
        return filtered_reservations.toStream();
    }
    
    // Customer: List available cars (streaming)
    remote function ListAvailableCars(ListAvailableCarsRequest request) returns stream<Car, error?>|error {
        log:printInfo("Listing available cars");
        
        Car[] available_cars = [];
        
        foreach Car car in cars.values() {
            if car.status == AVAILABLE {
                boolean include = true;
                
                // Apply filters if provided
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
    
    // Customer: Search for a specific car by plate
    remote function SearchCar(SearchCarRequest request) returns SearchCarResponse|error {
        log:printInfo("Searching for car with plate: " + request.plate);
        
        if !cars.hasKey(request.plate) {
            return {
                found: false,
                car: {},
                message: "Car with plate " + request.plate + " not found"
            };
        }
        
        Car car = cars.get(request.plate);
        
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
    
    // Customer: Add car to cart with rental dates
    remote function AddToCart(AddToCartRequest request) returns AddToCartResponse|error {
        log:printInfo("Adding car to cart for customer: " + request.customer_id);
        
        // Validate customer exists
        if !users.hasKey(request.customer_id) {
            return {
                success: false,
                message: "Customer not found",
                cart_item: {}
            };
        }
        
        // Validate car exists and is available
        if !cars.hasKey(request.plate) {
            return {
                success: false,
                message: "Car not found",
                cart_item: {}
            };
        }
        
        Car car = cars.get(request.plate);
        if car.status != AVAILABLE {
            return {
                success: false,
                message: "Car is not available",
                cart_item: {}
            };
        }
        
        // Validate dates (basic validation)
        if !isValidDateRange(request.start_date, request.end_date) {
            return {
                success: false,
                message: "Invalid date range",
                cart_item: {}
            };
        }
        
        // Calculate estimated price
        int days = calculateDays(request.start_date, request.end_date);
        float estimated_price = <float>days * car.daily_price;
        
        CartItem cartItem = {
            plate: request.plate,
            start_date: request.start_date,
            end_date: request.end_date,
            estimated_price: estimated_price
        };
        
        // Add to customer's cart
        CartItem[] cart = customerCarts.get(request.customer_id);
        cart.push(cartItem);
        customerCarts[request.customer_id] = cart;
        
        return {
            success: true,
            message: "Car added to cart successfully",
            cart_item: cartItem
        };
    }
    
    // Customer: Place reservation from cart
    remote function PlaceReservation(PlaceReservationRequest request) returns PlaceReservationResponse|error {
        log:printInfo("Placing reservation for customer: " + request.customer_id);
        
        // Validate customer exists
        if !users.hasKey(request.customer_id) {
            return {
                success: false,
                message: "Customer not found",
                reservations: [],
                total_amount: 0.0
            };
        }
        
        CartItem[] cart = customerCarts.get(request.customer_id);
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
            // Verify car is still available
            Car car = cars.get(item.plate);
            if car.status != AVAILABLE {
                return {
                    success: false,
                    message: "Car " + item.plate + " is no longer available",
                    reservations: [],
                    total_amount: 0.0
                };
            }
            
            // Check for date conflicts with existing reservations
            if hasDateConflict(item.plate, item.start_date, item.end_date) {
                return {
                    success: false,
                    message: "Date conflict for car " + item.plate,
                    reservations: [],
                    total_amount: 0.0
                };
            }
            
            // Create reservation
            string reservation_id = uuid:createType1AsString();
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
            
            reservations[reservation_id] = reservation;
            new_reservations.push(reservation);
            total_amount += item.estimated_price;
        }
        
        // Clear the cart
        customerCarts[request.customer_id] = [];
        
        return {
            success: true,
            message: "Reservations placed successfully",
            reservations: new_reservations,
            total_amount: total_amount
        };
    }
}

// Helper functions
function isValidDateRange(string start_date, string end_date) returns boolean {
    // Basic date validation (you can enhance this)
    return start_date.length() == 10 && end_date.length() == 10;
}

function calculateDays(string start_date, string end_date) returns int {
    // Simple day calculation (you can enhance this with proper date parsing)
    return 1; // Placeholder - implement proper date calculation
}

function hasDateConflict(string plate, string start_date, string end_date) returns boolean {
    // Check if there are any existing reservations that overlap with the requested dates
    foreach Reservation reservation in reservations.values() {
        if reservation.plate == plate && reservation.status == "CONFIRMED" {
            // Check for date overlap (implement proper date comparison)
            // This is a simplified check
            if !(end_date < reservation.start_date || start_date > reservation.end_date) {
                return true;
            }
        }
    }
    return false;
}

public function main() {
    log:printInfo("Car Rental gRPC Server started on port 9090");
}