import ballerina/http;
import ballerina/log;
import ballerina/grpc;

// gRPC client connection
CarRentalServiceClient grpcClient = check new("http://localhost:9090");

// HTTP service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://localhost:5173"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}
service /api on new http:Listener(8080) {

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
        AddCarRequest request = check carData.cloneWithType(AddCarRequest);
        AddCarResponse response = check grpcClient->AddCar(request);
        
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
        CreateUsersRequest request = check userData.cloneWithType(CreateUsersRequest);
        CreateUsersResponse response = check grpcClient->CreateUsers(request);
        
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
        json requestData = updateData.clone();
        requestData = check requestData.mergeJson({"plate": plate});
        
        UpdateCarRequest request = check requestData.cloneWithType(UpdateCarRequest);
        UpdateCarResponse response = check grpcClient->UpdateCar(request);
        
        return {
            success: response.success,
            message: response.message,
            data: response.updated_car
        };
    }

    // Admin: Remove car
    resource function delete admin/cars/[string plate]() returns json|error {
        RemoveCarResponse response = check grpcClient->RemoveCar({plate: plate});
        
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
        stream<Reservation, grpc:Error?> reservationStream = check grpcClient->ListReservations({
            customer_id: customer_id
        });
        
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
        stream<Car, grpc:Error?> carStream = check grpcClient->ListAvailableCars({
            filter_text: filter_text,
            year_filter: year_filter
        });
        
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
        SearchCarResponse response = check grpcClient->SearchCar({plate: plate});
        
        return {
            success: response.found,
            message: response.message,
            data: response.car
        };
    }

    // Customer: Add to cart
    resource function post customers/[string customer_id]/cart(@http:Payload json cartData) returns json|error {
        json requestData = cartData.clone();
        requestData = check requestData.mergeJson({"customer_id": customer_id});
        
        AddToCartRequest request = check requestData.cloneWithType(AddToCartRequest);
        AddToCartResponse response = check grpcClient->AddToCart(request);
        
        return {
            success: response.success,
            message: response.message,
            data: response.cart_item
        };
    }

    // Customer: Place reservation
    resource function post customers/[string customer_id]/reservations() returns json|error {
        PlaceReservationResponse response = check grpcClient->PlaceReservation({
            customer_id: customer_id
        });
        
        return {
            success: response.success,
            message: response.message,
            data: {
                reservations: response.reservations,
                total_amount: response.total_amount
            }
        };
    }

    // Get customer's cart (mock endpoint - in real app, this would be stored)
    resource function get customers/[string customer_id]/cart() returns json {
        // This would typically fetch from a session store or database
        return {
            success: true,
            message: "Cart retrieved successfully",
            data: {
                items: [],
                total_items: 0,
                estimated_total: 0.0
            }
        };
    }

    // System stats endpoint
    resource function get admin/stats() returns json|error {
        // Get basic stats by calling multiple endpoints
        json carsResponse = check self->get cars();
        json reservationsResponse = check self->get admin/reservations();
        
        Car[] cars = check carsResponse.data.cloneWithType(Car[]);
        Reservation[] reservations = check reservationsResponse.data.cloneWithType(Reservation[]);
        
        int available_cars = 0;
        int rented_cars = 0;
        
        foreach Car car in cars {
            if car.status == "AVAILABLE" {
                available_cars += 1;
            } else if car.status == "RENTED" {
                rented_cars += 1;
            }
        }
        
        float total_revenue = 0.0;
        int confirmed_reservations = 0;
        
        foreach Reservation reservation in reservations {
            if reservation.status == "CONFIRMED" {
                confirmed_reservations += 1;
                total_revenue += reservation.total_price;
            }
        }
        
        return {
            success: true,
            message: "Stats retrieved successfully",
            data: {
                total_cars: cars.length(),
                available_cars: available_cars,
                rented_cars: rented_cars,
                total_reservations: reservations.length(),
                confirmed_reservations: confirmed_reservations,
                total_revenue: total_revenue
            }
        };
    }
}

public function main() {
    log:printInfo("Car Rental REST Gateway started on http://localhost:8080");
}