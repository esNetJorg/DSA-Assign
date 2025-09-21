import ballerina/grpc;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import car_rental; // Generated from car_rental.proto

// Client configuration
car_rental:CarRentalServiceClient client = check new ("http://localhost:9090");

// Mock data
car_rental:User[] demo_users = [
    {
        user_id: "admin1",
        name: "Admin User",
        email: "admin@carrental.com",
        role: car_rental:ADMIN,
        created_at: time:utcToString(time:utcNow())
    },
    {
        user_id: "customer1",
        name: "John Doe",
        email: "john@example.com",
        role: car_rental:CUSTOMER,
        created_at: time:utcToString(time:utcNow())
    },
    {
        user_id: "customer2",
        name: "Jane Smith",
        email: "jane@example.com",
        role: car_rental:CUSTOMER,
        created_at: time:utcToString(time:utcNow())
    }
];

public function main() returns error? {
    log:printInfo("Starting Car Rental System Client Demo");
    
    // Run demo scenario
    check runDemo();
    
    // Optionally start interactive mode
    // check startInteractiveMode();
}

function runDemo() returns error? {
    io:println("=== Car Rental System Demo ===\n");
    
    // 1. Create users
    io:println("1. Creating users...");
    car_rental:CreateUsersResponse userResponse = check client->CreateUsers({users: demo_users});
    io:println("Users created: " + userResponse.message);
    
    // 2. Add cars (Admin operation)
    io:println("\n2. Adding cars to inventory...");
    check addDemoCars();
    
    // 3. List available cars
    io:println("\n3. Listing available cars...");
    check listAvailableCars({filter_text: "", year_filter: ()});
    
    // 4. Search for specific car
    io:println("\n4. Searching for specific car (ABC123)...");
    check searchCar({plate: "ABC123"});
    
    // 5. Add cars to cart
    io:println("\n5. Adding cars to customer cart...");
    check addToCart({customer_id: "customer1", plate: "ABC123", start_date: "2025-10-01", end_date: "2025-10-05"});
    check addToCart({customer_id: "customer1", plate: "XYZ789", start_date: "2025-10-10", end_date: "2025-10-15"});
    
    // 6. Place reservation
    io:println("\n6. Placing reservation...");
    check placeReservation({customer_id: "customer1"});
    
    // 7. List reservations (Admin operation)
    io:println("\n7. Listing all reservations...");
    check listReservations({customer_id: ()});
    
    // 8. Update car details
    io:println("\n8. Updating car details...");
    check updateCar({
        plate: "ABC123",
        make: "Toyota",
        model: "Camry Hybrid",
        year: 2024,
        daily_price: 65.0,
        mileage: (),
        status: ()
    });
    
    // 9. Remove a car
    io:println("\n9. Removing a car...");
    check removeCar({plate: "DEF456"});
    
    io:println("\n=== Demo Completed ===");
}

function addDemoCars() returns error? {
    car_rental:AddCarRequest[] cars = [
        {
            make: "Toyota",
            model: "Camry",
            year: 2023,
            daily_price: 60.0,
            mileage: 15000,
            plate: "ABC123",
            status: car_rental:AVAILABLE
        },
        {
            make: "Honda",
            model: "Civic",
            year: 2022,
            daily_price: 50.0,
            mileage: 25000,
            plate: "XYZ789",
            status: car_rental:AVAILABLE
        },
        {
            make: "Ford",
            model: "Mustang",
            year: 2024,
            daily_price: 80.0,
            mileage: 5000,
            plate: "DEF456",
            status: car_rental:AVAILABLE
        }
    ];
    
    foreach car_rental:AddCarRequest carRequest in cars {
        car_rental:AddCarResponse response = check client->AddCar(carRequest);
        if response.success {
            io:println("✓ Added car: " + carRequest.plate + " (" + carRequest.make + " " + carRequest.model + ")");
        } else {
            io:println("✗ Failed to add car: " + response.message);
        }
    }
}

function adminAddCar() returns error? {
    string make = io:readln("Enter car make: ");
    string model = io:readln("Enter car model: ");
    string yearStr = io:readln("Enter car year: ");
    string priceStr = io:readln("Enter daily price: ");
    string mileageStr = io:readln("Enter mileage: ");
    string plate = io:readln("Enter license plate: ");
    
    int year = check int:fromString(yearStr) on fail var e => {
        io:println("Invalid year input");
        return e;
    };
    float dailyPrice = check float:fromString(priceStr) on fail var e => {
        io:println("Invalid price input");
        return e;
    };
    int mileage = check int:fromString(mileageStr) on fail var e => {
        io:println("Invalid mileage input");
        return e;
    };
    
    car_rental:AddCarRequest request = {
        make: make,
        model: model,
        year: year,
        daily_price: <double>dailyPrice, // Convert float to double as per proto
        mileage: mileage,
        plate: plate,
        status: car_rental:AVAILABLE
    };
    
    car_rental:AddCarResponse response = check client->AddCar(request);
    
    if response.success {
        io:println("✓ Car added successfully: " + response.car_id);
    } else {
        io:println("✗ Failed to add car: " + response.message);
    }
}

function adminUpdateCar() returns error? {
    string plate = io:readln("Enter car plate to update: ");
    string make = io:readln("Enter new make (or press Enter to skip): ");
    string model = io:readln("Enter new model (or press Enter to skip): ");
    string yearStr = io:readln("Enter new year (or press Enter to skip): ");
    string priceStr = io:readln("Enter new daily price (or press Enter to skip): ");
    string mileageStr = io:readln("Enter new mileage (or press Enter to skip): ");
    
    car_rental:UpdateCarRequest request = {plate: plate};
    
    if make != "" {
        request.make = make;
    }
    if model != "" {
        request.model = model;
    }
    if yearStr != "" {
        request.year = check int:fromString(yearStr) on fail var e => {
            io:println("Invalid year input");
            return e;
        };
    }
    if priceStr != "" {
        request.daily_price = <double>check float:fromString(priceStr) on fail var e => {
            io:println("Invalid price input");
            return e;
        };
    }
    if mileageStr != "" {
        request.mileage = check int:fromString(mileageStr) on fail var e => {
            io:println("Invalid mileage input");
            return e;
        };
    }
    // Status is optional, left as default if not provided
    
    car_rental:UpdateCarResponse response = check client->UpdateCar(request);
    
    if response.success {
        io:println("✓ Car updated successfully");
    } else {
        io:println("✗ Failed to update car: " + response.message);
    }
}

function listAvailableCars(car_rental:ListAvailableCarsRequest request) returns error? {
    stream<car_rental:Car, grpc:Error?> carStream = check client->ListAvailableCars(request);
    
    io:println("Available Cars:");
    io:println("===============");
    
    error? streamResult = carStream.forEach(function(car_rental:Car car) {
        io:println(string `${car.plate} | ${car.make} ${car.model} (${car.year}) | $${car.daily_price}/day | ${car.mileage} miles`);
    });
    
    if streamResult is error {
        return streamResult;
    }
}

function searchCar(car_rental:SearchCarRequest request) returns error? {
    car_rental:SearchCarResponse response = check client->SearchCar(request);
    
    if response.found {
        car_rental:Car car = response.car;
        io:println("Car found: " + car.make + " " + car.model + " (" + car.year.toString() + ")");
        io:println("Daily Price: $" + car.daily_price.toString());
        io:println("Status: " + car.status.toString());
    } else {
        io:println("Car not found or not available: " + response.message);
    }
}

function addToCart(car_rental:AddToCartRequest request) returns error? {
    car_rental:AddToCartResponse response = check client->AddToCart(request);
    
    if response.success {
        car_rental:CartItem item = response.cart_item;
        io:println("✓ Added to cart: " + item.plate + " from " + item.start_date + " to " + item.end_date);
        io:println("  Estimated price: $" + item.estimated_price.toString());
    } else {
        io:println("✗ Failed to add to cart: " + response.message);
    }
}

function placeReservation(car_rental:PlaceReservationRequest request) returns error? {
    car_rental:PlaceReservationResponse response = check client->PlaceReservation(request);
    
    if response.success {
        io:println("✓ Reservation placed successfully!");
        io:println("Total amount: $" + response.total_amount.toString());
        io:println("Reservations created: " + response.reservations.length().toString());
        
        foreach car_rental:Reservation reservation in response.reservations {
            io:println("  - " + reservation.reservation_id + ": " + reservation.plate + 
                      " (" + reservation.start_date + " to " + reservation.end_date + ")");
        }
    } else {
        io:println("✗ Failed to place reservation: " + response.message);
    }
}

function listReservations(car_rental:ListReservationsRequest request) returns error? {
    stream<car_rental:Reservation, grpc:Error?> reservationStream = check client->ListReservations(request);
    
    io:println("All Reservations:");
    io:println("=================");
    
    error? streamResult = reservationStream.forEach(function(car_rental:Reservation reservation) {
        io:println(string `${reservation.reservation_id} | Customer: ${reservation.customer_id} | Car: ${reservation.plate}`);
        io:println(string `  Dates: ${reservation.start_date} to ${reservation.end_date} | Price: $${reservation.total_price} | Status: ${reservation.status}`);
        io:println("---");
    });
    
    if streamResult is error {
        return streamResult;
    }
}

function updateCar(car_rental:UpdateCarRequest request) returns error? {
    car_rental:UpdateCarResponse response = check client->UpdateCar(request);
    
    if response.success {
        car_rental:Car car = response.updated_car;
        io:println("✓ Updated car: " + car.plate + " -> " + car.make + " " + car.model + 
                  " (" + car.year.toString() + ") $" + car.daily_price.toString() + "/day");
    } else {
        io:println("✗ Failed to update car: " + response.message);
    }
}

function removeCar(car_rental:RemoveCarRequest request) returns error? {
    car_rental:RemoveCarResponse response = check client->RemoveCar(request);
    
    if response.success {
        io:println("✓ Car removed: " + request.plate);
        io:println("Remaining cars in inventory: " + response.remaining_cars.length().toString());
    } else {
        io:println("✗ Failed to remove car: " + response.message);
    }
}

function startInteractiveMode() returns error? {
    io:println("=== Car Rental System - Interactive Mode ===");
    
    while true {
        io:println("\nSelect an option:");
        io:println("1. List available cars");
        io:println("2. Search for a car");
        io:println("3. Add car to cart");
        io:println("4. Place reservation");
        io:println("5. Admin: Add car");
        io:println("6. Admin: Update car");
        io:println("7. Admin: Remove car");
        io:println("8. Admin: List reservations");
        io:println("9. Exit");
        
        string choice = io:readln("Enter your choice (1-9): ");
        
        match choice {
            "1" => {
                string filter = io:readln("Enter filter (or press Enter for all): ");
                int? yearFilter = ();
                string yearStr = io:readln("Enter year filter (or press Enter to skip): ");
                if yearStr != "" {
                    yearFilter = check int:fromString(yearStr) on fail var e => {
                        io:println("Invalid year filter");
                        return e;
                    };
                }
                check listAvailableCars({filter_text: filter == "" ? () : filter, year_filter: yearFilter});
            }
            "2" => {
                string plate = io:readln("Enter car plate: ");
                check searchCar({plate: plate});
            }
            "3" => {
                string customerId = io:readln("Enter customer ID: ");
                string plate = io:readln("Enter car plate: ");
                string startDate = io:readln("Enter start date (YYYY-MM-DD): ");
                string endDate = io:readln("Enter end date (YYYY-MM-DD): ");
                check addToCart({customer_id: customerId, plate: plate, start_date: startDate, end_date: endDate});
            }
            "4" => {
                string customerId = io:readln("Enter customer ID: ");
                check placeReservation({customer_id: customerId});
            }
            "5" => {
                check adminAddCar();
            }
            "6" => {
                check adminUpdateCar();
            }
            "7" => {
                string plate = io:readln("Enter car plate to remove: ");
                check removeCar({plate: plate});
            }
            "8" => {
                string? customerId = ();
                string customerIdInput = io:readln("Enter customer ID to filter (or press Enter for all): ");
                if customerIdInput != "" {
                    customerId = customerIdInput;
                }
                check listReservations({customer_id: customerId});
            }
            "9" => {
                io:println("Goodbye!");
                break;
            }
            _ => {
                io:println("Invalid choice. Please try again.");
            }
        }
    }
}
