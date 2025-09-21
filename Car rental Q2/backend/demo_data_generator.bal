import ballerina/grpc;
import ballerina/io;
import ballerina/log;

// Demo data generator for Car Rental System
CarRentalServiceClient client = check new("http://localhost:9090");

// Demo users data
User[] demoUsers = [
    // Admins
    {
        user_id: "admin1",
        name: "Alice Johnson",
        email: "alice.admin@carrental.com",
        role: ADMIN,
        created_at: ""
    },
    {
        user_id: "admin2", 
        name: "Bob Manager",
        email: "bob.manager@carrental.com",
        role: ADMIN,
        created_at: ""
    },
    
    // Customers
    {
        user_id: "customer1",
        name: "John Doe",
        email: "john.doe@email.com",
        role: CUSTOMER,
        created_at: ""
    },
    {
        user_id: "customer2",
        name: "Jane Smith", 
        email: "jane.smith@email.com",
        role: CUSTOMER,
        created_at: ""
    },
    {
        user_id: "customer3",
        name: "Mike Wilson",
        email: "mike.wilson@email.com", 
        role: CUSTOMER,
        created_at: ""
    },
    {
        user_id: "customer4",
        name: "Sarah Davis",
        email: "sarah.davis@email.com",
        role: CUSTOMER, 
        created_at: ""
    },
    {
        user_id: "customer5",
        name: "David Brown",
        email: "david.brown@email.com",
        role: CUSTOMER,
        created_at: ""
    }
];

// Demo cars data
AddCarRequest[] demoCars = [
    // Economy Cars
    {
        make: "Toyota",
        model: "Corolla",
        year: 2023,
        daily_price: 45.00,
        mileage: 12000,
        plate: "TOY001",
        status: AVAILABLE
    },
    {
        make: "Honda", 
        model: "Civic",
        year: 2023,
        daily_price: 48.00,
        mileage: 15000,
        plate: "HON001",
        status: AVAILABLE
    },
    {
        make: "Nissan",
        model: "Sentra", 
        year: 2022,
        daily_price: 42.00,
        mileage: 18000,
        plate: "NIS001",
        status: AVAILABLE
    },
    {
        make: "Hyundai",
        model: "Elantra",
        year: 2024,
        daily_price: 50.00,
        mileage: 8000,
        plate: "HYU001",
        status: AVAILABLE
    },
    
    // Mid-Size Cars
    {
        make: "Toyota",
        model: "Camry",
        year: 2023, 
        daily_price: 65.00,
        mileage: 14000,
        plate: "TOY002",
        status: AVAILABLE
    },
    {
        make: "Honda",
        model: "Accord",
        year: 2024,
        daily_price: 68.00,
        mileage: 9000,
        plate: "HON002", 
        status: AVAILABLE
    },
    {
        make: "Nissan",
        model: "Altima",
        year: 2023,
        daily_price: 62.00,
        mileage: 16000,
        plate: "NIS002",
        status: RENTED
    },
    {
        make: "Mazda",
        model: "Mazda6",
        year: 2022,
        daily_price: 60.00,
        mileage: 22000,
        plate: "MAZ001",
        status: AVAILABLE
    },
    
    // SUVs
    {
        make: "Toyota",
        model: "RAV4",
        year: 2024,
        daily_price: 85.00,
        mileage: 5000,
        plate: "TOY003",
        status: AVAILABLE
    },
    {
        make: "Honda", 
        model: "CR-V",
        year: 2023,
        daily_price: 82.00,
        mileage: 11000,
        plate: "HON003",
        status: AVAILABLE
    },
    {
        make: "Ford",
        model: "Explorer",
        year: 2023,
        daily_price: 95.00,
        mileage: 13000,
        plate: "FOR001",
        status: AVAILABLE
    },
    {
        make: "Chevrolet",
        model: "Equinox", 
        year: 2022,
        daily_price: 78.00,
        mileage: 19000,
        plate: "CHE001",
        status: UNAVAILABLE
    },
    
    // Luxury Cars
    {
        make: "BMW",
        model: "320i",
        year: 2024,
        daily_price: 120.00,
        mileage: 3000,
        plate: "BMW001",
        status: AVAILABLE
    },
    {
        make: "Mercedes",
        model: "C-Class",
        year: 2024, 
        daily_price: 125.00,
        mileage: 4000,
        plate: "MER001",
        status: AVAILABLE
    },
    {
        make: "Audi",
        model: "A4",
        year: 2023,
        daily_price: 115.00,
        mileage: 7000,
        plate: "AUD001",
        status: RENTED
    },
    {
        make: "Lexus",
        model: "ES350",
        year: 2023,
        daily_price: 110.00,
        mileage: 9000,
        plate: "LEX001",
        status: AVAILABLE
    },
    
    // Sports Cars  
    {
        make: "Ford",
        model: "Mustang",
        year: 2024,
        daily_price: 150.00,
        mileage: 2000,
        plate: "FOR002",
        status: AVAILABLE
    },
    {
        make: "Chevrolet",
        model: "Camaro",
        year: 2023,
        daily_price: 145.00,
        mileage: 6000,
        plate: "CHE002",
        status: AVAILABLE
    },
    {
        make: "Dodge",
        model: "Challenger",
        year: 2023,
        daily_price: 140.00,
        mileage: 8000, 
        plate: "DOD001",
        status: UNAVAILABLE
    },
    
    // Electric Cars
    {
        make: "Tesla",
        model: "Model 3",
        year: 2024,
        daily_price: 130.00,
        mileage: 1000,
        plate: "TES001",
        status: AVAILABLE
    },
    {
        make: "Tesla",
        model: "Model Y", 
        year: 2024,
        daily_price: 160.00,
        mileage: 2000,
        plate: "TES002",
        status: AVAILABLE
    },
    {
        make: "Nissan",
        model: "Leaf",
        year: 2023,
        daily_price: 55.00,
        mileage: 12000,
        plate: "NIS003",
        status: AVAILABLE
    }
];

public function main() returns error? {
    log:printInfo("🚀 Starting Car Rental Demo Data Generator");
    
    io:println("=== Car Rental System Demo Data Generator ===\n");
    
    // 1. Create Users
    io:println("📥 Creating demo users...");
    CreateUsersResponse userResponse = check client->CreateUsers({users: demoUsers});
    
    if userResponse.success {
        io:println(string `✅ Successfully created ${userResponse.users_created} users`);
        io:println("   👤 Admins: admin1 (Alice Johnson), admin2 (Bob Manager)");
        io:println("   👥 Customers: customer1-5 (John, Jane, Mike, Sarah, David)");
    } else {
        io:println("❌ Failed to create users: " + userResponse.message);
    }
    
    io:println();
    
    // 2. Add Cars
    io:println("🚗 Adding demo cars to inventory...");
    
    int successCount = 0;
    int failCount = 0;
    
    foreach AddCarRequest car in demoCars {
        AddCarResponse carResponse = check client->AddCar(car);
        
        if carResponse.success {
            successCount += 1;
            io:print("✅ ");
        } else {
            failCount += 1;
            io:print("❌ ");
        }
        
        io:println(string `${car.make} ${