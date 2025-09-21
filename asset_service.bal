import ballerina/http;
import ballerina/time;

type Component record {
    string componentId;
    string name;
};

type Schedule record {
    string scheduleId;
    string description;
    string dueDate; // yyyy-MM-dd
};

type Task record {
    string taskId;
    string description;
    string status;
};

type WorkOrder record {
    string orderId;
    string status;
    Task[] tasks;
};

type Asset record {
    string assetTag;
    string name;
    string faculty;
    string department;
    string status; // ACTIVE, UNDER_REPAIR, DISPOSED
    string acquiredDate; // yyyy-MM-dd
    Component[] components;
    Schedule[] schedules;
    WorkOrder[] workOrders;
};

map<Asset> assets = {};

// -- function to consider users input and exist data  (lowercase + remove spaces)
function normalize(string input) returns string {
    string lowered = input.toLowerAscii();
    string result = "";
    foreach int i in 0 ..< lowered.length() {
        string ch = lowered[i].toString();
        if ch != " " {
            result += ch;
        }
    }
    return result;
}

service /assets on new http:Listener(8080) {

    // add a new asset
    resource function post add(@http:Payload Asset asset) returns json {
        assets[asset.assetTag] = asset;
        return { message: "Asset was added successfully" };
    }

    // get all assets, if they exist
    resource function get all() returns Asset[] {
        Asset[] result = [];
        foreach var [_, asset] in assets.entries() {
            result.push(asset);
        }
        return result;
    }

    // to get them assets by faculty : the ignore spaces,case-insensitive and partial match was implementented
    resource function get byFaculty(string faculty) returns json|Asset[] {
        string normalizedQuery = normalize(faculty);
        Asset[] result = [];

        foreach var [_, asset] in assets.entries() {
            string normalizedFac = normalize(asset.faculty);
            if string:includes(normalizedFac, normalizedQuery) {
                result.push(asset);
            }
        }

        if result.length() == 0 {
            return { message: "No assets found for faculty: " + faculty };
        }
        return result;
    }

    // to add a schedule to ONLY an existing asset
    resource function post addSchedule(string assetTag, @http:Payload Schedule schedule) returns json {
        Asset? maybeAsset = assets[assetTag];
        if maybeAsset is Asset {
            maybeAsset.schedules.push(schedule);
            assets[assetTag] = maybeAsset;
            return { message: "The schedule was added successfully" };
        }
        return { message: "Asset wasn't found" };
    }

    //---- to add a component to ONLY an existing asset
resource function post addComponent(string assetTag, @http:Payload Component component) returns json {
    Asset? maybeAsset = assets[assetTag];
    if maybeAsset is Asset {
        maybeAsset.components.push(component);
        assets[assetTag] = maybeAsset;
        return { message: "The component was added successfully" };
    }
    return { message: "Asset wasn't found" };
}

//to a work order to an existing asset----- NB: don't temper with this one
resource function post addWorkOrder(string assetTag, @http:Payload WorkOrder workOrder) returns json {
    Asset? maybeAsset = assets[assetTag];
    if maybeAsset is Asset {
        maybeAsset.workOrders.push(workOrder);
        assets[assetTag] = maybeAsset;
        return { message: "The work order was added successfully" };
    }
    return { message: "Asset wasn't found" };
}


    // to get overdue  overdue assets
    resource function get overdue() returns json|Asset[] {
        time:Utc now = time:utcNow();
        Asset[] result = [];

        foreach var [_, asset] in assets.entries() {
            foreach var sch in asset.schedules {
                string dueStr = sch.dueDate + "T00:00:00Z";
                var dueOrErr = time:utcFromString(dueStr);

                if dueOrErr is time:Utc {
                    int diff = <int>time:utcDiffSeconds(now, dueOrErr);
                    if diff > 0 {
                        result.push(asset);
                        break;
                    }
                }
            }
        }

        if result.length() == 0 {
            return { message: "No overdue assets found" };
        }
        return result;
    }
}

