import ballerina/grpc;
import ballerina/io;
import ballerina/test;
import ballerina/log;

// Test client for Car Rental System
CarRentalServiceClient testClient = check new("http://localhost:9090");

// Test data
User[] testUsers = [
    {
        user_id: "test_admin",
        name: "Test Admin",
        email: "testadmin@carrental.com", 
        role: ADMIN,
        created_at: ""
    },
    {
        user_id: "test_customer1",
        name: "Test Customer One",
        email: "customer1@test.com",
        role: CUSTOMER,
        created_at: ""
    },
    {
        user_id: "test_customer2", 
        name: "Test Customer Two",
        email: "customer2@test.com",
        role: CUSTOMER,
        created_at: ""
    }
];

@test:Config {}
function testCreateUsers() returns error? {
    log:printInfo("Testing user creation...");
    
    CreateUsersResponse response = check testClient->CreateUsers({users: testUsers});
    
    test:assertTrue(response.success, "User creation should succeed");
    test:assertEquals(response.users_created, 3, "Should create 3 users");
    
    io:println("✓ User creation test passed");
}

@test:Config {dependsOn: [testCreateUsers]}
function testAddCar() returns error? {
    log:printInfo("Testing car addition...");
    
    AddCarRequest carRequest = {
        make: "Toyota",
        model: "Corolla",
        year: 2023,
        daily_price: 55.0,
        mileage: 10000,
        plate: "TEST001",
        status: AVAILABLE
    };
    
    AddCarResponse response = check testClient->AddCar(carRequest);
    
    test:assertTrue(response.success, "Car addition should succeed");
    test:assertEquals(response.car_id, "TEST001", "Should return correct car ID");
    
    io:println("✓ Car addition test passed");
}

@test:Config {dependsOn: [testAddCar]}
function testAddDuplicateCar() returns error? {
    log:printInfo("Testing duplicate car addition...");
    
    AddCarRequest carRequest = {
        make: "Honda",
        model: "Accord", 
        year: 2022,
        daily_price: 60.0,
        mileage: 15000,
        plate: "TEST001", // Same plate as previous test
        status: AVAILABLE
    };
    
    AddCarResponse response = check testClient->AddCar(carRequest);
    
    test:assertFalse(response.success, "Duplicate car addition should fail");
    
    io:println("✓ Duplicate car addition test passed");
}

@test:Config {dependsOn: [testAddCar]}
function testSearchCar() returns error? {
    log:printInfo("Testing car search...");
    
    // Search for existing car
    SearchCarResponse response = check testClient->SearchCar({plate: "TEST001"});
    
    test:assertTrue(response.found, "Car should be found");
    test:assertEquals(response.car.make, "Toyota", "Should return correct car make");
    
    // Search for non-existent car
    SearchCarResponse notFoundResponse = check testClient->SearchCar({plate: "NOTEXIST"});
    
    test:assertFalse(notFoundResponse.found, "Non-existent car should not be found");
    
    io:println("✓ Car search test passed");
}

@test:Config {dependsOn: [testAddCar]}
function testListAvailableCars() returns error? {
    log:printInfo("Testing available cars listing...");
    
    // Add more test cars
    AddCarRequest[] additionalCars = [
        {
            make: "Honda",
            model: "Civic",
            year: 2023,
            daily_price: 50.0,
            mileage: 8000,
            plate: "TEST002",
            status: AVAILABLE
        },
        {
            make: "Ford",
            model: "Focus", 
            year: 2022,
            daily_price: 45.0,
            mileage: 20000,
            plate: "TEST003",
            status: UNAVAILABLE
        }
    ];
    
    foreach AddCarRequest car in additionalCars {
        _ = check testClient->AddCar(car);
    }
    
    // List all available cars
    stream<Car, grpc:Error?> carStream = check testClient->ListAvailableCars({});
    
    Car[] availableCars = [];
    error? streamResult = carStream.forEach(function(Car car) {
        availableCars.push(car);
    });
    
    test:assertTrue(availableCars.length() >= 2, "Should have at least 2 available cars");
    
    // Test with filter
    stream<Car, grpc:Error?> filteredStream = check testClient->ListAvailableCars({filter_text: "Toyota"});
    
    Car[] toyotaCars = [];
    error? filteredResult = filteredStream.forEach(function(Car car) {
        toyotaCars.push(car);
    });
    
    test:assertTrue(toyotaCars.length() >= 1, "Should find at least 1 Toyota");
    
    io:println("✓ List available cars test passed");
}

@test:Config {dependsOn: [testAddCar]}
function testAddToCart() returns error? {
    log:printInfo("Testing add to cart...");
    
    AddToCartRequest cartRequest = {
        customer_id: "test_customer1",
        plate: "TEST001",
        start_date: "2025-11-01",
        end_date: "2025-11-05"
    };
    
    AddToCartResponse response = check testClient->AddToCart(cartRequest);
    
    test:assertTrue(response.success, "Add to cart should succeed");
    test:assertEquals(response.cart_item.plate, "TEST001", "Should add correct car");
    test:assertTrue(response.cart_item.estimated_price > 0, "Should calculate estimated price");
    
    io:println("✓ Add to cart test passed");
}

@test:Config {dependsOn: [testAddToCart]}
function testAddToCartInvalidCustomer() returns error? {
    log:printInfo("Testing add to cart with invalid customer...");
    
    AddToCartRequest cartRequest = {
        customer_id: "invalid_customer",
        plate: "TEST001", 
        start_date: "2025-11-01",
        end_date: "2025-11-05"
    };
    
    AddToCartResponse response = check testClient->AddToCart(cartRequest);
    
    test:assertFalse(response.success, "Add to cart should fail for invalid customer");
    
    io:println("✓ Add to cart invalid customer test passed");
}

@test:Config {dependsOn: [testAddToCart]}
function testPlaceReservation() returns error? {
    log:printInfo("Testing place reservation...");
    
    PlaceReservationResponse response = check testClient->PlaceReservation({customer_id: "test_customer1"});
    
    test:assertTrue(response.success, "Place reservation should succeed");
    test:assertTrue(response.reservations.length() > 0, "Should create reservations");
    test:assertTrue(response.total_amount > 0, "Should calculate total amount");
    
    io:println("✓ Place reservation test passed");
}

@test:Config {dependsOn: [testAddCar]}
function testUpdateCar() returns error? {
    log:printInfo("Testing car update...");
    
    UpdateCarRequest updateRequest = {
        plate: "TEST001",
        daily_price: 65.0,
        status: AVAILABLE
    };
    
    UpdateCarResponse response = check testClient->UpdateCar(updateRequest);
    
    test:assertTrue(response.success, "Car update should succeed");
    test:assertEquals(response.updated_car.daily_price, 65.0, "Should update daily price");
    
    io:println("✓ Car update test passed");
}

@test:Config {dependsOn: [testPlaceReservation]}
function testListReservations() returns error? {
    log:printInfo("Testing list reservations...");
    
    stream<Reservation, grpc:Error?> reservationStream = check testClient->ListReservations({});
    
    Reservation[] allReservations = [];
    error? streamResult = reservationStream.forEach(function(Reservation reservation) {
        allReservations.push(reservation);
    });
    
    test:assertTrue(allReservations.length() > 0, "Should have reservations");
    
    // Test filtering by customer
    stream<Reservation, grpc:Error?> customerStream = check testClient->ListReservations({customer_id: "test_customer1"});
    
    Reservation[] customerReservations = [];
    error? customerResult = customerStream.forEach(function(Reservation reservation) {
        customerReservations.push(reservation);
    });
    
    test:assertTrue(customerReservations.length() > 0, "Should have customer reservations");
    
    io:println("✓ List reservations test passed");
}

@test:Config {dependsOn: [testUpdateCar]}
function testRemoveCar() returns error? {
    log:printInfo("Testing car removal...");
    
    RemoveCarResponse response = check testClient->RemoveCar({plate: "TEST002"});
    
    test:assertTrue(response.success, "Car removal should succeed");
    
    // Verify car is removed by searching for it
    SearchCarResponse searchResponse = check testClient->SearchCar({plate: "TEST002"});
    test:assertFalse(searchResponse.found, "Removed car should not be found");
    
    io:println("✓ Car removal test passed");
}

// Comprehensive integration test
@test:Config {}
function testCompleteWorkflow() returns error? {
    log:printInfo("Testing complete workflow...");
    
    // 1. Create a new user
    User newUser = {
        user_id: "workflow_customer",
        name: "Workflow Customer",
        email: "workflow@test.com",
        role: CUSTOMER,
        created_at: ""
    };
    
    CreateUsersResponse userResponse = check testClient->CreateUsers({users: [newUser]});
    test:assertTrue(userResponse.success, "User creation should succeed");
    
    // 2. Add a new car
    AddCarRequest newCar = {
        make: "BMW",
        model: "X3",
        year: 2024,
        daily_price: 90.0,
        mileage: 2000,
        plate: "WORKFLOW001",
        status: AVAILABLE
    };
    
    AddCarResponse carResponse = check testClient->AddCar(newCar);
    test:assertTrue(carResponse.success, "Car addition should succeed");
    
    // 3. Customer searches for the car
    SearchCarResponse searchResponse = check testClient->SearchCar({plate: "WORKFLOW001"});
    test:assertTrue(searchResponse.found, "Car should be found");
    
    // 4. Add to cart
    AddToCartResponse cartResponse = check testClient->AddToCart({
        customer_id: "workflow_customer",
        plate: "WORKFLOW001",
        start_date: "2025-12-01",
        end_date: "2025-12-07"
    });
    test:assertTrue(cartResponse.success, "Add to cart should succeed");
    
    // 5. Place reservation
    PlaceReservationResponse reservationResponse = check testClient->PlaceReservation({
        customer_id: "workflow_customer"
    });
    test:assertTrue(reservationResponse.success, "Reservation should succeed");
    
    io:println("✓ Complete workflow test passed");
}

// Performance test
@test:Config {}
function testPerformance() returns error? {
    log:printInfo("Testing performance with multiple operations...");
    
    int startTime = checkpanic time:currentTimeMillis();
    
    // Add multiple cars concurrently
    AddCarRequest[] performanceCars = [];
    foreach int i in 1...10 {
        performanceCars.push({
            make: "TestMake" + i.toString(),
            model: "TestModel" + i.toString(), 
            year: 2020 + (i % 5),
            daily_price: 40.0 + <float>i * 5.0,
            mileage: 10000 + i * 1000,
            plate: "PERF" + i.toString().padZero(3),
            status: AVAILABLE
        });
    }
    
    foreach AddCarRequest car in performanceCars {
        _ = check testClient->AddCar(car);
    }
    
    // List cars multiple times
    foreach int i in 1...5 {
        stream<Car, grpc:Error?> carStream = check testClient->ListAvailableCars({});
        error? result = carStream.forEach(function(Car car) {
            // Process each car
        });
    }
    
    int endTime = checkpanic time:currentTimeMillis();
    int duration = endTime - startTime;
    
    test:assertTrue(duration < 5000, "Performance test should complete in under 5 seconds");
    
    io:println("✓ Performance test passed (Duration: " + duration.toString() + "ms)");
}

public function main() returns error? {
    io:println("=== Running Car Rental System Tests ===\n");
    
    // Run all tests
    check testCreateUsers();
    check testAddCar();
    check testAddDuplicateCar();
    check testSearchCar();
    check testListAvailableCars();
    check testAddToCart();
    check testAddToCartInvalidCustomer();
    check testPlaceReservation();
    check testUpdateCar();
    check testListReservations();
    check testRemoveCar();
    check testCompleteWorkflow();
    check testPerformance();
    
    io:println("\n=== All Tests Passed! ===");
}