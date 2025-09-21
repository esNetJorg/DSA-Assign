import ballerina/time;
import ballerina/regex;
import ballerina/log;

// Date utility functions
public function parseDate(string dateStr) returns time:Date|error {
    // Parse date in format YYYY-MM-DD
    string[] parts = regex:split(dateStr, "-");
    if parts.length() != 3 {
        return error("Invalid date format. Expected YYYY-MM-DD");
    }
    
    int year = check int:fromString(parts[0]);
    int month = check int:fromString(parts[1]);
    int day = check int:fromString(parts[2]);
    
    if year < 2020 || year > 2030 {
        return error("Invalid year. Must be between 2020 and 2030");
    }
    
    if month < 1 || month > 12 {
        return error("Invalid month. Must be between 1 and 12");
    }
    
    if day < 1 || day > 31 {
        return error("Invalid day. Must be between 1 and 31");
    }
    
    return {year: year, month: month, day: day};
}

public function isValidDateRange(string startDate, string endDate) returns boolean {
    time:Date|error start = parseDate(startDate);
    time:Date|error end = parseDate(endDate);
    
    if start is error || end is error {
        return false;
    }
    
    // Check if start date is before or equal to end date
    return compareDates(start, end) <= 0;
}

public function calculateDays(string startDate, string endDate) returns int {
    time:Date|error start = parseDate(startDate);
    time:Date|error end = parseDate(endDate);
    
    if start is error || end is error {
        return 1; // Default to 1 day if parsing fails
    }
    
    // Simple day calculation (can be enhanced with proper date arithmetic)
    int startDays = start.year * 365 + start.month * 30 + start.day;
    int endDays = end.year * 365 + end.month * 30 + end.day;
    
    int days = endDays - startDays + 1; // +1 to include both start and end dates
    return days > 0 ? days : 1;
}

public function compareDates(time:Date date1, time:Date date2) returns int {
    if date1.year != date2.year {
        return date1.year - date2.year;
    }
    if date1.month != date2.month {
        return date1.month - date2.month;
    }
    return date1.day - date2.day;
}

public function datesOverlap(string start1, string end1, string start2, string end2) returns boolean {
    time:Date|error startDate1 = parseDate(start1);
    time:Date|error endDate1 = parseDate(end1);
    time:Date|error startDate2 = parseDate(start2);
    time:Date|error endDate2 = parseDate(end2);
    
    if startDate1 is error || endDate1 is error || startDate2 is error || endDate2 is error {
        return false; // If any date parsing fails, assume no overlap
    }
    
    // Check for overlap: (start1 <= end2) && (end1 >= start2)
    return compareDates(startDate1, endDate2) <= 0 && compareDates(endDate1, startDate2) >= 0;
}

// Validation utility functions
public function validateCarData(AddCarRequest request) returns error? {
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

public function validateUserData(User user) returns error? {
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

public function isValidEmail(string email) returns boolean {
    // Simple email validation regex
    return regex:matches(email, "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
}

// Business logic utility functions
public function calculateTotalPrice(CartItem[] cartItems) returns float {
    float total = 0.0;
    foreach CartItem item in cartItems {
        total += item.estimated_price;
    }
    return total;
}

public function generateReservationId() returns string {
    // Generate a simple reservation ID with timestamp
    time:Utc currentTime = time:utcNow();
    int timestamp = <int>time:utcToTimeSeconds(currentTime);
    return "RES-" + timestamp.toString();
}

public function isCarAvailableForDates(string plate, string startDate, string endDate, map<Reservation> existingReservations) returns boolean {
    foreach Reservation reservation in existingReservations.values() {
        if reservation.plate == plate && reservation.status == "CONFIRMED" {
            if datesOverlap(startDate, endDate, reservation.start_date, reservation.end_date) {
                return false;
            }
        }
    }
    return true;
}

public function filterCarsByText(Car[] cars, string filterText) returns Car[] {
    if filterText == "" {
        return cars;
    }
    
    string filter = filterText.toLowerAscii();
    Car[] filteredCars = [];
    
    foreach Car car in cars {
        string carInfo = (car.make + " " + car.model + " " + car.year.toString()).toLowerAscii();
        if carInfo.includes(filter) {
            filteredCars.push(car);
        }
    }
    
    return filteredCars;
}

public function filterCarsByYear(Car[] cars, int year) returns Car[] {
    Car[] filteredCars = [];
    
    foreach Car car in cars {
        if car.year == year {
            filteredCars.push(car);
        }
    }
    
    return filteredCars;
}

public function filterCarsByStatus(Car[] cars, CarStatus status) returns Car[] {
    Car[] filteredCars = [];
    
    foreach Car car in cars {
        if car.status == status {
            filteredCars.push(car);
        }
    }
    
    return filteredCars;
}

public function getCarsByMake(Car[] cars) returns map<Car[]> {
    map<Car[]> carsByMake = {};
    
    foreach Car car in cars {
        if carsByMake.hasKey(car.make) {
            Car[] existing = carsByMake.get(car.make);
            existing.push(car);
            carsByMake[car.make] = existing;
        } else {
            carsByMake[car.make] = [car];
        }
    }
    
    return carsByMake;
}

public function getCarsPriceRange(Car[] cars) returns record {| float min; float max; float avg; |} {
    if cars.length() == 0 {
        return {min: 0.0, max: 0.0, avg: 0.0};
    }
    
    float min = cars[0].daily_price;
    float max = cars[0].daily_price;
    float total = 0.0;
    
    foreach Car car in cars {
        if car.daily_price < min {
            min = car.daily_price;
        }
        if car.daily_price > max {
            max = car.daily_price;
        }
        total += car.daily_price;
    }
    
    return {
        min: min,
        max: max,
        avg: total / <float>cars.length()
    };
}

// Logging utilities
public function logCarOperation(string operation, string plate, string details) {
    log:printInfo(string `Car Operation: ${operation} | Plate: ${plate} | Details: ${details}`);
}

public function logUserOperation(string operation, string userId, string details) {
    log:printInfo(string `User Operation: ${operation} | User: ${userId} | Details: ${details}`);
}

public function logReservationOperation(string operation, string reservationId, string details) {
    log:printInfo(string `Reservation Operation: ${operation} | ID: ${reservationId} | Details: ${details}`);
}

public function logSystemEvent(string event, string details) {
    log:printInfo(string `System Event: ${event} | Details: ${details}`);
}

public function logError(string operation, string errorMessage) {
    log:printError(string `Error in ${operation}: ${errorMessage}`);
}

// Data formatting utilities
public function formatCarInfo(Car car) returns string {
    return string `${car.make} ${car.model} (${car.year}) - $${car.daily_price}/day | ${car.mileage} miles | Status: ${car.status}`;
}

public function formatReservationInfo(Reservation reservation) returns string {
    return string `${reservation.reservation_id} | Customer: ${reservation.customer_id} | Car: ${reservation.plate} | ${reservation.start_date} to ${reservation.end_date} | $${reservation.total_price} | ${reservation.status}`;
}

public function formatUserInfo(User user) returns string {
    return string `${user.user_id} | ${user.name} | ${user.email} | ${user.role}`;
}

public function formatCartItemInfo(CartItem item) returns string {
    return string `${item.plate} | ${item.start_date} to ${item.end_date} | $${item.estimated_price}`;
}

public function formatPriceRange(record {| float min; float max; float avg; |} priceRange) returns string {
    return string `Min: $${priceRange.min} | Max: $${priceRange.max} | Avg: $${priceRange.avg}`;
}

// System statistics utilities
public function getSystemStats(map<Car> cars, map<User> users, map<Reservation> reservations) returns record {|
    int total_cars;
    int available_cars;
    int rented_cars;
    int unavailable_cars;
    int total_users;
    int customers;
    int admins;
    int total_reservations;
    int confirmed_reservations;
    int cancelled_reservations;
    float total_revenue;
    record {| float min; float max; float avg; |} price_range;
    map<int> cars_by_make;
    map<int> reservations_by_month;
|} {
    
    // Car statistics
    int totalCars = cars.length();
    int availableCars = 0;
    int rentedCars = 0;
    int unavailableCars = 0;
    
    Car[] allCars = cars.values();
    foreach Car car in allCars {
        if car.status == AVAILABLE {
            availableCars += 1;
        } else if car.status == RENTED {
            rentedCars += 1;
        } else {
            unavailableCars += 1;
        }
    }
    
    // User statistics
    int totalUsers = users.length();
    int customers = 0;
    int admins = 0;
    
    foreach User user in users.values() {
        if user.role == CUSTOMER {
            customers += 1;
        } else if user.role == ADMIN {
            admins += 1;
        }
    }
    
    // Reservation statistics
    int totalReservations = reservations.length();
    int confirmedReservations = 0;
    int cancelledReservations = 0;
    float totalRevenue = 0.0;
    map<int> reservationsByMonth = {};
    
    foreach Reservation reservation in reservations.values() {
        if reservation.status == "CONFIRMED" {
            confirmedReservations += 1;
            totalRevenue += reservation.total_price;
        } else if reservation.status == "CANCELLED" {
            cancelledReservations += 1;
        }
        
        // Count by month (simplified)
        string monthKey = reservation.created_at.substring(0, 7); // YYYY-MM
        if reservationsByMonth.hasKey(monthKey) {
            reservationsByMonth[monthKey] = reservationsByMonth.get(monthKey) + 1;
        } else {
            reservationsByMonth[monthKey] = 1;
        }
    }
    
    // Car make statistics
    map<int> carsByMake = {};
    foreach Car car in allCars {
        if carsByMake.hasKey(car.make) {
            carsByMake[car.make] = carsByMake.get(car.make) + 1;
        } else {
            carsByMake[car.make] = 1;
        }
    }
    
    // Price range
    record {| float min; float max; float avg; |} priceRange = getCarsPriceRange(allCars);
    
    return {
        total_cars: totalCars,
        available_cars: availableCars,
        rented_cars: rentedCars,
        unavailable_cars: unavailableCars,
        total_users: totalUsers,
        customers: customers,
        admins: admins,
        total_reservations: totalReservations,
        confirmed_reservations: confirmedReservations,
        cancelled_reservations: cancelledReservations,
        total_revenue: totalRevenue,
        price_range: priceRange,
        cars_by_make: carsByMake,
        reservations_by_month: reservationsByMonth
    };
}

// Data validation utilities
public function validateReservationDates(string startDate, string endDate) returns error? {
    if !isValidDateRange(startDate, endDate) {
        return error("Invalid date range");
    }
    
    // Check if start date is not in the past
    time:Date today = time:utcToDate(time:utcNow());
    time:Date|error start = parseDate(startDate);
    
    if start is time:Date {
        if compareDates(start, today) < 0 {
            return error("Start date cannot be in the past");
        }
    }
    
    // Check if reservation period is not too long (e.g., max 30 days)
    int days = calculateDays(startDate, endDate);
    if days > 30 {
        return error("Reservation period cannot exceed 30 days");
    }
    
    if days < 1 {
        return error("Reservation must be at least 1 day");
    }
}

public function validateCarUpdate(UpdateCarRequest request) returns error? {
    if request.make is string && (request.make as string).length() < 2 {
        return error("Car make must be at least 2 characters");
    }
    
    if request.model is string && (request.model as string).length() < 2 {
        return error("Car model must be at least 2 characters");
    }
    
    if request.year is int {
        int year = request.year as int;
        if year < 1990 || year > 2025 {
            return error("Car year must be between 1990 and 2025");
        }
    }
    
    if request.daily_price is float {
        float price = request.daily_price as float;
        if price <= 0.0 {
            return error("Daily price must be positive");
        }
    }
    
    if request.mileage is int {
        int mileage = request.mileage as int;
        if mileage < 0 {
            return error("Mileage cannot be negative");
        }
    }
}

// Search and filtering utilities
public function searchCars(Car[] cars, string searchTerm) returns Car[] {
    if searchTerm == "" {
        return cars;
    }
    
    string search = searchTerm.toLowerAscii();
    Car[] results = [];
    
    foreach Car car in cars {
        string carData = (car.make + " " + car.model + " " + car.plate + " " + car.year.toString()).toLowerAscii();
        if carData.includes(search) {
            results.push(car);
        }
    }
    
    return results;
}

public function sortCarsByPrice(Car[] cars, boolean ascending = true) returns Car[] {
    // Simple bubble sort implementation
    Car[] sortedCars = cars.clone();
    int n = sortedCars.length();
    
    foreach int i in 0 ..< n - 1 {
        foreach int j in 0 ..< n - i - 1 {
            boolean shouldSwap = ascending ? 
                sortedCars[j].daily_price > sortedCars[j + 1].daily_price :
                sortedCars[j].daily_price < sortedCars[j + 1].daily_price;
                
            if shouldSwap {
                Car temp = sortedCars[j];
                sortedCars[j] = sortedCars[j + 1];
                sortedCars[j + 1] = temp;
            }
        }
    }
    
    return sortedCars;
}

public function sortCarsByYear(Car[] cars, boolean ascending = true) returns Car[] {
    Car[] sortedCars = cars.clone();
    int n = sortedCars.length();
    
    foreach int i in 0 ..< n - 1 {
        foreach int j in 0 ..< n - i - 1 {
            boolean shouldSwap = ascending ? 
                sortedCars[j].year > sortedCars[j + 1].year :
                sortedCars[j].year < sortedCars[j + 1].year;
                
            if shouldSwap {
                Car temp = sortedCars[j];
                sortedCars[j] = sortedCars[j + 1];
                sortedCars[j + 1] = temp;
            }
        }
    }
    
    return sortedCars;
}

// Report generation utilities
public function generateCarInventoryReport(map<Car> cars) returns string {
    Car[] allCars = cars.values();
    string report = "=== CAR INVENTORY REPORT ===\n";
    report += "Generated: " + time:utcToString(time:utcNow()) + "\n\n";
    
    // Summary statistics
    int available = filterCarsByStatus(allCars, AVAILABLE).length();
    int rented = filterCarsByStatus(allCars, RENTED).length();
    int unavailable = filterCarsByStatus(allCars, UNAVAILABLE).length();
    
    report += "SUMMARY:\n";
    report += string `Total Cars: ${allCars.length()}\n`;
    report += string `Available: ${available}\n`;
    report += string `Rented: ${rented}\n`;
    report += string `Unavailable: ${unavailable}\n\n`;
    
    // Price analysis
    record {| float min; float max; float avg; |} priceRange = getCarsPriceRange(allCars);
    report += "PRICE ANALYSIS:\n";
    report += formatPriceRange(priceRange) + "\n\n";
    
    // Cars by make
    map<Car[]> carsByMake = getCarsByMake(allCars);
    report += "CARS BY MAKE:\n";
    foreach string make in carsByMake.keys() {
        Car[] makeCars = carsByMake.get(make);
        report += string `${make}: ${makeCars.length()} cars\n`;
    }
    
    report += "\nDETAILED INVENTORY:\n";
    report += "Plate\t\tMake\t\tModel\t\tYear\tPrice\t\tMileage\t\tStatus\n";
    report += "-------------------------------------------------------------------------\n";
    
    foreach Car car in allCars {
        report += string `${car.plate}\t\t${car.make}\t\t${car.model}\t\t${car.year}\t${car.daily_price}\t\t${car.mileage}\t\t${car.status}\n`;
    }
    
    return report;
}

public function generateReservationReport(map<Reservation> reservations) returns string {
    Reservation[] allReservations = reservations.values();
    string report = "=== RESERVATION REPORT ===\n";
    report += "Generated: " + time:utcToString(time:utcNow()) + "\n\n";
    
    // Summary statistics
    int confirmed = 0;
    int cancelled = 0;
    int completed = 0;
    float totalRevenue = 0.0;
    
    foreach Reservation reservation in allReservations {
        if reservation.status == "CONFIRMED" {
            confirmed += 1;
            totalRevenue += reservation.total_price;
        } else if reservation.status == "CANCELLED" {
            cancelled += 1;
        } else if reservation.status == "COMPLETED" {
            completed += 1;
            totalRevenue += reservation.total_price;
        }
    }
    
    report += "SUMMARY:\n";
    report += string `Total Reservations: ${allReservations.length()}\n`;
    report += string `Confirmed: ${confirmed}\n`;
    report += string `Cancelled: ${cancelled}\n`;
    report += string `Completed: ${completed}\n`;
    report += string `Total Revenue: ${totalRevenue}\n\n`;
    
    report += "DETAILED RESERVATIONS:\n";
    report += "ID\t\tCustomer\t\tCar\t\tStart Date\tEnd Date\tPrice\t\tStatus\n";
    report += "-----------------------------------------------------------------------------------------\n";
    
    foreach Reservation reservation in allReservations {
        report += string `${reservation.reservation_id.substring(0, 8)}\t\t${reservation.customer_id}\t\t${reservation.plate}\t\t${reservation.start_date}\t${reservation.end_date}\t${reservation.total_price}\t\t${reservation.status}\n`;
    }
    
    return report;
}

public function generateSystemReport(map<Car> cars, map<User> users, map<Reservation> reservations) returns string {
    string report = "=== SYSTEM OVERVIEW REPORT ===\n";
    report += "Generated: " + time:utcToString(time:utcNow()) + "\n\n";
    
    var stats = getSystemStats(cars, users, reservations);
    
    report += "SYSTEM STATISTICS:\n";
    report += string `Total Cars: ${stats.total_cars}\n`;
    report += string `  - Available: ${stats.available_cars}\n`;
    report += string `  - Rented: ${stats.rented_cars}\n`;
    report += string `  - Unavailable: ${stats.unavailable_cars}\n\n`;
    
    report += string `Total Users: ${stats.total_users}\n`;
    report += string `  - Customers: ${stats.customers}\n`;
    report += string `  - Admins: ${stats.admins}\n\n`;
    
    report += string `Total Reservations: ${stats.total_reservations}\n`;
    report += string `  - Confirmed: ${stats.confirmed_reservations}\n`;
    report += string `  - Cancelled: ${stats.cancelled_reservations}\n`;
    report += string `Total Revenue: ${stats.total_revenue}\n\n`;
    
    report += "PRICE ANALYSIS:\n";
    report += formatPriceRange(stats.price_range) + "\n\n";
    
    report += "CARS BY MAKE:\n";
    foreach string make in stats.cars_by_make.keys() {
        int count = stats.cars_by_make.get(make);
        report += string `${make}: ${count} cars\n`;
    }
    
    report += "\nRESERVATIONS BY MONTH:\n";
    foreach string month in stats.reservations_by_month.keys() {
        int count = stats.reservations_by_month.get(month);
        report += string `${month}: ${count} reservations\n`;
    }
    
    return report;
}

// Utility functions for data export
public function exportCarsToCSV(Car[] cars) returns string {
    string csv = "Plate,Make,Model,Year,Daily_Price,Mileage,Status,Created_At\n";
    
    foreach Car car in cars {
        csv += string `${car.plate},${car.make},${car.model},${car.year},${car.daily_price},${car.mileage},${car.status},${car.created_at}\n`;
    }
    
    return csv;
}

public function exportReservationsToCSV(Reservation[] reservations) returns string {
    string csv = "Reservation_ID,Customer_ID,Plate,Start_Date,End_Date,Total_Price,Status,Created_At\n";
    
    foreach Reservation reservation in reservations {
        csv += string `${reservation.reservation_id},${reservation.customer_id},${reservation.plate},${reservation.start_date},${reservation.end_date},${reservation.total_price},${reservation.status},${reservation.created_at}\n`;
    }
    
    return csv;
}

public function exportUsersToCSV(User[] users) returns string {
    string csv = "User_ID,Name,Email,Role,Created_At\n";
    
    foreach User user in users {
        csv += string `${user.user_id},${user.name},${user.email},${user.role},${user.created_at}\n`;
    }
    
    return csv;
}

// Performance monitoring utilities
public function measureExecutionTime<T>(function() returns T func, string operationName) returns T {
    time:Utc startTime = time:utcNow();
    T result = func();
    time:Utc endTime = time:utcNow();
    
    decimal duration = time:utcDiffSeconds(endTime, startTime);
    log:printInfo(string `Performance: ${operationName} took ${duration} seconds`);
    
    return result;
}

public function logMemoryUsage(string context) {
    // In a real implementation, you would use system-specific memory monitoring
    log:printInfo(string `Memory Usage Check: ${context} - System resources monitored`);
}

// Configuration and constants
public const int MAX_RESERVATION_DAYS = 30;
public const int MIN_RESERVATION_DAYS = 1;
public const float MIN_DAILY_PRICE = 10.0;
public const float MAX_DAILY_PRICE = 1000.0;
public const int MIN_CAR_YEAR = 1990;
public const int MAX_CAR_YEAR = 2025;
public const int MAX_PLATE_LENGTH = 10;
public const int MIN_PLATE_LENGTH = 3;

// Error handling utilities
public function handleAndLogError(error err, string context) returns error {
    string errorMsg = string `Error in ${context}: ${err.message()}`;
    logError(context, err.message());
    return error(errorMsg);
}

public function createValidationError(string field, string requirement) returns error {
    return error(string `Validation failed for ${field}: ${requirement}`);
}

// Database simulation utilities (for future database integration)
public function simulateDatabaseDelay() {
    // Simulate database response time
    time:sleep(0.1); // 100ms delay
}

public function generateUniqueId(string prefix) returns string {
    time:Utc now = time:utcNow();
    int timestamp = <int>time:utcToTimeSeconds(now);
    return string `${prefix}-${timestamp}`;
}

// Cleanup and maintenance utilities
public function cleanupExpiredReservations(map<Reservation> reservations) returns int {
    time:Date today = time:utcToDate(time:utcNow());
    string[] expiredIds = [];
    
    foreach string reservationId in reservations.keys() {
        Reservation reservation = reservations.get(reservationId);
        time:Date|error endDate = parseDate(reservation.end_date);
        
        if endDate is time:Date {
            if compareDates(endDate, today) < 0 && reservation.status == "CONFIRMED" {
                // Mark as completed if end date has passed
                reservation.status = "COMPLETED";
                reservations[reservationId] = reservation;
            }
        }
    }
    
    return expiredIds.length();
}

public function generateSystemHealthCheck(map<Car> cars, map<User> users, map<Reservation> reservations) returns record {|
    boolean healthy;
    string status;
    record {| int cars; int users; int reservations; |} counts;
    string[] warnings;
    string[] errors;
|} {
    
    string[] warnings = [];
    string[] errors = [];
    boolean healthy = true;
    
    // Check data integrity
    if cars.length() == 0 {
        warnings.push("No cars in system");
    }
    
    if users.length() == 0 {
        errors.push("No users in system");
        healthy = false;
    }
    
    // Check for orphaned reservations (reservations for non-existent cars/users)
    foreach Reservation reservation in reservations.values() {
        if !cars.hasKey(reservation.plate) {
            errors.push(string `Reservation ${reservation.reservation_id} references non-existent car ${reservation.plate}`);
            healthy = false;
        }
        
        if !users.hasKey(reservation.customer_id) {
            errors.push(string `Reservation ${reservation.reservation_id} references non-existent user ${reservation.customer_id}`);
            healthy = false;
        }
    }
    
    return {
        healthy: healthy,
        status: healthy ? "HEALTHY" : "UNHEALTHY",
        counts: {
            cars: cars.length(),
            users: users.length(),
            reservations: reservations.length()
        },
        warnings: warnings,
        errors: errors
    };
}
