import ballerina/http;
import ballerina/io;

type Component record { string componentId; string name; };
type Schedule record { string scheduleId; string description; string dueDate; };
type Task record { string taskId; string description; string status; };
type WorkOrder record { string orderId; string status; Task[] tasks; };
type Asset record {
    string assetTag;
    string name;
    string faculty;
    string department;
    string status;
    string acquiredDate;
    Component[] components;
    Schedule[] schedules;
    WorkOrder[] workOrders;
};

public function main() returns error? {
    http:Client assetClient = check new ("http://localhost:8080/assets");

    while true {
        io:println("\nAsset Client Menu:");
        io:println("1. Add Asset");
        io:println("2. View All Assets");
        io:println("3. Filter by Faculty");
        io:println("4. Add Schedule");
        io:println("5. View Overdue Assets");
        io:println("6. Add Component");
        io:println("7. Add Work Order");
        io:println("8. Exit");


