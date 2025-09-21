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

        

        string choice = io:readln("Enter choice: ");

        if choice == "1" {
            Asset asset = {
                assetTag: io:readln("Asset Tag: "),
                name: io:readln("Name: "),
                faculty: io:readln("Faculty: "),
                department: io:readln("Department: "),
                status: io:readln("Status: "),
                acquiredDate: io:readln("Acquired Date (yyyy-MM-dd): "),
                components: [],
                schedules: [],
                workOrders: []
            }; 
            http:Response resp = check assetClient->post("/add", asset);
            json result = check resp.getJsonPayload();
            io:println("Response: ", result);

        } else if choice == "2" {
            http:Response resp = check assetClient->get("/all");
            json result = check resp.getJsonPayload();
            io:println("All Assets: ", result);

        } else if choice == "3" {
            string faculty = io:readln("Faculty: ");
            http:Response resp = check assetClient->get("/byFaculty?faculty=" + faculty);
            json result = check resp.getJsonPayload();
            io:println("Assets by Faculty: ", result);

        } else if choice == "4" {
            string assetTag = io:readln("Asset Tag: ");
            Schedule schedule = {
                scheduleId: io:readln("Schedule ID: "),
                description: io:readln("Description: "),
                dueDate: io:readln("Due Date (yyyy-MM-dd): ")
            };
            http:Response resp = check assetClient->post("/addSchedule/" + assetTag, schedule);
            json result = check resp.getJsonPayload();
            io:println("Response: ", result);

        } else if choice == "5" {
            http:Response resp = check assetClient->get("/overdue");
            json result = check resp.getJsonPayload();
            io:println("Overdue Assets: ", result);

        } else if choice == "6" {
            string assetTag = io:readln("Asset Tag: ");
            Component component ={
                componentId: io:readln("Component ID: "),
                name: io:readln("Component Name: ")
            };
             http:Response resp = check assetClient->post("/addComponent/" + assetTag, component);
             json result = check resp.getJsonPayload();
             io:println("Response: ",result);
        } else if choice == "7" {
            string assetTag = io:readln("Asset Tag: ");
            WorkOrder workOrder = {
                orderId: io:readln("Work Order ID: "),
                status: io:readln("Status: "),
                tasks: []
          };
          
          string addTasks= io:readln("Add tasks? (yes/no): ");
          if addTasks.toLowerAscii()== "yes"{
             while true{
                Task task= {
                    taskId: io:readln("Task ID: "),
                    description: io:readln("Description: "),
                    status: io:readln("Status: ")
               };
               workOrder.tasks.push(task);
               string more = io:readln("Add another task? (yes/no): ");
               if more.toLowerAscii() != "yes" {
                                  break;
            }
        }
    }

    http:Response resp = check assetClient->post("/addWorkOrder/"+ assetTag, workOrder);
    json result = check resp.getJsonPayload();
    io:println("Response: ", result);
               
    
        } else {
            io:println("Invalid choice, try again.");
        }
    }

}
