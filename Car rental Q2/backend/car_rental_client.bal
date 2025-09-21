import ballerina/grpc;
import ballerina/io;
import ballerina/log;

// Client configuration
CarRentalServiceClient client = check new("http://localhost:9090");

// Mock data
User[] demo_users = [
    {
        user_id: "admin1",
        name: "Admin User",
        email: "admin@carrental.com",
        role: ADMIN,
        created_at: ""
    },
    {
        user_id: "customer1", 
        name: "John Doe",
        email: "john@example.com",
        role: CUSTOMER,
        created_at: ""
    },
    {
        user_id: "customer2",
        name: "Jane Smith", 
        email: "jane@example.com",
        role: CUSTOMER,
        created_at: ""
    }
];

public function main() returns error? {
    log:printInfo("Starting Car Rental System Client Demo");
    
    // Demo scenario
    check runDemo();
}        //40 to 82 here



function addDemoCars() returns error? {
    AddCarRequest request = {
        make: make,
        model: model,
        year: year,
        daily_price: dailyPrice,
        mileage: mileage,
        plate: plate,
        status: AVAILABLE
    };
    
    AddCarResponse response = check client->AddCar(request);
    
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
    
    UpdateCarRequest request = {plate: plate};
    
    if make != "" {
        request.make = make;
    }
    if model != "" {
        request.model = model;
    }
    if yearStr != "" {
        request.year = check int:fromString(yearStr);
    }
    if priceStr != "" {
        request.daily_price = check float:fromString(priceStr);
    }
    if mileageStr != "" {
        request.mileage = check int:fromString(mileageStr);
    }
    
    UpdateCarResponse response = check client->UpdateCar(request);
    
    if response.success {
        io:println("✓ Car updated successfully");
    } else {
        io:println("✗ Failed to update car: " + response.message);
    }
}Request[] cars = [
        {
            make: "Toyota",
            model: "Camry",
            year: 2023,
            daily_price: 60.0,
            mileage: 15000,
            plate: "ABC123",
            status: AVAILABLE
        },
        {
            make: "Honda",
            model: "Civic",
            year: 2022,
            daily_price: 50.0,
            mileage: 25000,
            plate: "XYZ789",
            status: AVAILABLE
        },
        {
            make: "Ford",
            model: "Mustang",
            year: 2024,
            daily_price: 80.0,
            mileage: 5000,
            plate: "DEF456",
            status: AVAILABLE
        }
    ];
    
    foreach AddCarRequest carRequest in cars {
        AddCarResponse response = check client->AddCar(carRequest);
        if response.success {
            io:println("✓ Added car: " + carRequest.plate + " (" + carRequest.make + " " + carRequest.model + ")");
        } else {
            io:println("✗ Failed to add car: " + response.message);
        }
    }
}

function listAvailableCars(string filter) returns error? {
    stream<Car, grpc:Error?> carStream = check client->ListAvailableCars({filter_text: filter});
    
    io:println("Available Cars:");
    io:println("===============");
    
    error? streamResult = carStream.forEach(function(Car car) {
        io:println(string `${car.plate} | ${car.make} ${car.model} (${car.year}) | $${car.daily_price}/day | ${car.mileage} miles`);
    });
    
    if streamResult is error {
        return streamResult;
    }
}

function searchCar(string plate) returns error? {
    SearchCarResponse response = check client->SearchCar({plate: plate});
    
    if response.found {
        Car car = response.car;
        io:println("Car found: " + car.make + " " + car.model + " (" + car.year.toString() + ")");
        io:println("Daily Price: $" + car.daily_price.toString());
        io:println("Status: " + car.status.toString());
    } else {
        io:println("Car not found or not available: " + response.message);
    }
}

function addToCart(string customerId, string plate, string startDate, string endDate) returns error? {
    AddToCartRequest request = {
        customer_id: customerId,
        plate: plate,
        start_date: startDate,
        end_date: endDate
    };
    
    AddToCartResponse response = check client->AddToCart(request);
    
    if response.success {
        CartItem item = response.cart_item;
        io:println("✓ Added to cart: " + item.plate + " from " + item.start_date + " to " + item.end_date);
        io:println("  Estimated price: $" + item.estimated_price.toString());
    } else {
        io:println("✗ Failed to add to cart: " + response.message);
    }
}

function placeReservation(string customerId) returns error? {
    PlaceReservationResponse response = check client->PlaceReservation({customer_id: customerId});
    
    if response.success {
        io:println("✓ Reservation placed successfully!");
        io:println("Total amount: $" + response.total_amount.toString());
        io:println("Reservations created: " + response.reservations.length().toString());
        
        foreach Reservation reservation in response.reservations {
            io:println("  - " + reservation.reservation_id + ": " + reservation.plate + 
                      " (" + reservation.start_date + " to " + reservation.end_date + ")");
        }
    } else {
        io:println("✗ Failed to place reservation: " + response.message);
    }
}

function listReservations() returns error? {
    stream<Reservation, grpc:Error?> reservationStream = check client->ListReservations({});
    
    io:println("All Reservations:");
    io:println("=================");
    
    error? streamResult = reservationStream.forEach(function(Reservation reservation) {
        io:println(string `${reservation.reservation_id} | Customer: ${reservation.customer_id} | Car: ${reservation.plate}`);
        io:println(string `  Dates: ${reservation.start_date} to ${reservation.end_date} | Price: $${reservation.total_price} | Status: ${reservation.status}`);
        io:println("---");
    });
    
    if streamResult is error {
        return streamResult;
    }
}

function updateCar(string plate, string make, string model, int year, float dailyPrice) returns error? {
    UpdateCarRequest request = {
        plate: plate,
        make: make,
        model: model,
        year: year,
        daily_price: dailyPrice
    };
    
    UpdateCarResponse response = check client->UpdateCar(request);
    
    if response.success {
        Car car = response.updated_car;
        io:println("✓ Updated car: " + car.plate + " -> " + car.make + " " + car.model + 
                  " (" + car.year.toString() + ") $" + car.daily_price.toString() + "/day");
    } else {
        io:println("✗ Failed to update car: " + response.message);
    }
}

function removeCar(string plate) returns error? {
    RemoveCarResponse response = check client->RemoveCar({plate: plate});
    
    if response.success {
        io:println("✓ Car removed: " + plate);
        io:println("Remaining cars in inventory: " + response.remaining_cars.length().toString());
    } else {
        io:println("✗ Failed to remove car: " + response.message);
    }
}

// Interactive client functions
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
                check listAvailableCars(filter);
            }
            "2" => {
                string plate = io:readln("Enter car plate: ");
                check searchCar(plate);
            }
            "3" => {
                string customerId = io:readln("Enter customer ID: ");
                string plate = io:readln("Enter car plate: ");
                string startDate = io:readln("Enter start date (YYYY-MM-DD): ");
                string endDate = io:readln("Enter end date (YYYY-MM-DD): ");
                check addToCart(customerId, plate, startDate, endDate);
            }
            "4" => {
                string customerId = io:readln("Enter customer ID: ");
                check placeReservation(customerId);
            }
            "5" => {
                // Admin add car
                check adminAddCar();
            }
            "6" => {
                // Admin update car
                check adminUpdateCar();
            }
            "7" => {
                string plate = io:readln("Enter car plate to remove: ");
                check removeCar(plate);
            }
            "8" => {
                check listReservations();
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

function adminAddCar() returns error? {
    string make = io:readln("Enter car make: ");
    string model = io:readln("Enter car model: ");
    string yearStr = io:readln("Enter car year: ");
    string priceStr = io:readln("Enter daily price: ");
    string mileageStr = io:readln("Enter mileage: ");
    string plate = io:readln("Enter license plate: ");
    
    int year = check int:fromString(yearStr);
    float dailyPrice = check float:fromString(priceStr);
    int mileage = check int:fromString(mileageStr);
    

    AddCar

