import ballerina/grpc;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Data types (these would be generated from protobuf in real implementation)
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

// Request/Response types
public type AddCarRequest record {
    string make;
    string model;
    int year;
    float daily_price;
    int mileage;
    string plate;
    CarStatus status;
};

public type AddCarResponse record {
    boolean success;
    string message;
    string car_id;
};

public type CreateUsersRequest record {
    User[] users;
};

public type CreateUsersResponse record {
    boolean success;
    string message;
    int users_created;
};

public type UpdateCarRequest record {
    string plate;
    string? make = ();
    string? model = ();
    int? year = ();
    float? daily_price = ();
    int? mileage = ();
    CarStatus? status = ();
};

public type UpdateCarResponse record {
    boolean success;
    string message;
    Car updated_car;
};

public type RemoveCarRequest record {
    string plate;
};

public type RemoveCarResponse record {
    boolean success;
    string message;
    Car[] remaining_cars;
};

public type ListAvailableCarsRequest record {
    string? filter_text = ();
    int? year_filter = ();
};

public type SearchCarRequest record {
    string plate;
};

public type SearchCarResponse record {
    boolean found;
    Car car;
    string message;
};

public type AddToCartRequest record {
    string customer_id;
    string plate;
    string start_date;
    string end_date;
};

public type AddToCartResponse record {
    boolean success;
    string message;
    CartItem cart_item;
};

public type PlaceReservationRequest record {
    string customer_id;
};

public type PlaceReservationResponse record {
    boolean success;
    string message;
    Reservation[] reservations;
    float total_amount;
};

public type ListReservationsRequest record {
    string? customer_id = ();
};

// In-memory data storage
map<Car> cars = {};
map<User> users = {};
map<CartItem[]> customerCarts = {};
map<Reservation> reservations = {};

// Service implementation
@grpc:ServiceDescriptor {
    descriptor: ROOT_DESCRIPTOR,
    descMap: getDescriptorMap()
}
service "CarRentalService" on new grpc:Listener(9090) {

    // Admin: Add a new car to the system
    remote function AddCar(AddCarRequest request) returns AddCarResponse|error {
        log:printInfo("Adding new car with plate: " + request.plate);
        
        // Validate car data
        error? validationResult = validateCarData(request);
        if validationResult is error {
            log:printError("Car validation failed: " + validationResult.message());
            return {
                success: false,
                message: validationResult.message(),
                car_id: ""
            };
        }
        
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
        log:printInfo("Car added successfully: " + formatCarInfo(newCar));
        
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
        string[] errors = [];
        
        foreach User user in request.users {
            // Validate user data
            error? validationResult = validateUserData(user);
            if validationResult is error {
                errors.push("User " + user.user_id + ": " + validationResult.message());
                continue;
            }
            
            if !users.hasKey(user.user_id) {
                User newUser = {
                    user_id: user.user_id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    created_at: time:utcToString(time:utcNow())
                };
                users[user.user_id] = newUser;
                customerCarts[user.user_id] = [];
                created_count += 1;
                log:printInfo("User created: " + formatUserInfo(newUser));
            } else {
                errors.push("User " + user.user_id + " already exists");
            }
        }
        
        string message = created_count.toString() + " users created successfully";
        if errors.length() > 0 {
            message += ". Errors: " + string:'join(", ", ...errors);
        }
        
        return {
            success: created_count > 0,
            message: message,
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
        log:printInfo("Car updated: " + formatCarInfo(updatedCar));
        
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
        log:printInfo("Car removed: " + request.plate);
        
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
        
        log:printInfo("Found " + available_cars.length().toString() + " available cars");
        return available_cars.toStream();
    }
    
    // Customer: Search for a specific car by plate
    remote function SearchCar(SearchCarRequest request) returns SearchCarResponse|error {
        log:printInfo("Searching for car with plate: " + request.plate);
        
        if !cars.hasKey(request.plate) {
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
                cart_item: {
                    plate: "",
                    start_date: "",
                    end_date: "",
                    estimated_price: 0.0
                }
            };
        }
        
        // Validate car exists and is available
        if !cars.hasKey(request.plate) {
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
        
        Car car = cars.get(request.plate);
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
        
        // Validate dates
        if !isValidDateRange(request.start_date, request.end_date) {
            return {
                success: false,
                message: "Invalid date range",
                cart_item: {
                    plate: "",
                    start_date: "",
                    end_date: "",
                    estimated_price: 0.0
                }
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
        
        log:printInfo("Car added to cart: " + cartItem.plate + " for " + days.toString() + " days");
        
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
            
            log:printInfo("Reservation created: " + formatReservationInfo(reservation));
        }
        
        // Clear the cart
        customerCarts[request.customer_id] = [];
        
        log:printInfo("Reservations placed successfully. Total amount: $" + total_amount.toString());
        
        return {
            success: true,
            message: "Reservations placed successfully",
            reservations: new_reservations,
            total_amount: total_amount
        };
    }
}

// Utility Functions
function validateCarData(AddCarRequest request) returns error? {
    if request.plate.length() < 3 || request.plate.length() > 10 {
        return error("License plate must be between 3 and 10 characters");
    }
    
    if request.make.length() < 2 {
        return error("Car make must be at least 2 characters");
    }
    
    if request.model.length() < 2 {
        return error("Car model must be at least 2 characters");
    }
    
    if request.year < 1990 || request.year > 2025 {
        return error("Car year must be between 1990 and 2025");
    }
    
    if request.daily_price <= 0.0 {
        return error("Daily price must be positive");
    }
    
    if request.mileage < 0 {
        return error("Mileage cannot be negative");
    }
}

function validateUserData(User user) returns error? {
    if user.user_id.length() < 3 {
        return error("User ID must be at least 3 characters");
    }
    
    if user.name.length() < 2 {
        return error("Name must be at least 2 characters");
    }
    
    if !isValidEmail(user.email) {
        return error("Invalid email format");
    }
}

function isValidEmail(string email) returns boolean {
    // Simple email validation
    return email.includes("@") && email.includes(".") && email.length() > 5;
}

function isValidDateRange(string startDate, string endDate) returns boolean {
    // Basic date validation
    return startDate.length() == 10 && endDate.length() == 10 && startDate <= endDate;
}

function calculateDays(string startDate, string endDate) returns int {
    // Simplified day calculation
    // In real implementation, use proper date parsing
    return 1; // Placeholder
}

function hasDateConflict(string plate, string startDate, string endDate) returns boolean {
    // Check if there are any existing reservations that overlap
    foreach Reservation reservation in reservations.values() {
        if reservation.plate == plate && reservation.status == "CONFIRMED" {
            // Simple overlap check
            if !(endDate < reservation.start_date || startDate > reservation.end_date) {
                return true;
            }
        }
    }
    return false;
}

function formatCarInfo(Car car) returns string {
    return string `${car.make} ${car.model} (${car.year}) - $${car.daily_price}/day | ${car.mileage} miles | Status: ${car.status}`;
}

function formatUserInfo(User user) returns string {
    return string `${user.user_id} | ${user.name} | ${user.email} | ${user.role}`;
}

function formatReservationInfo(Reservation reservation) returns string {
    return string `${reservation.reservation_id} | Customer: ${reservation.customer_id} | Car: ${reservation.plate} | ${reservation.start_date} to ${reservation.end_date} | $${reservation.total_price}`;
}

// Placeholder descriptor functions (would be generated from protobuf)
function ROOT_DESCRIPTOR() returns byte[] {
    return [];
}

function getDescriptorMap() returns map<any> {
    return {};
}

public function main() {
    log:printInfo("Car Rental gRPC Server started on port 9090");
}
