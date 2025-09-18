import ballerina /http;
import ballerina /time;

type Component record {
 string componentId;
 string name; };

type Schedule record {
string scheduleId;
string description;
string dueDate; //yyyy-MM-dd
};

type Task record {
  string taskId;
  string description;
  string status; };
type WorkOder record {
  string orderId;
  string status;
  Task [] tasks; };
type Asset record {
  string assetTag;
  string name;
string faculty;
 string department;
string status ;
string acquiredDate; //yyyy-MM-dd
Component [] components;
Schedule[] schedules;
WorkOder [] workOder;
};

map<Asset> assets = {};
service /assets on new http:Listener(8080) {
resource function post add (@http:payload Asset asset) returns json{assets [asset.assetTag] = asset;
return {message: "Asset was added successfully"};
}

resource function get all() returns Asset[] {
  Asset[] result = [];
  foreach var [_, asset] in assets.entries() {
     result.push(asset);
  }
}
return result}

resource function get byFaculty (string faculty) returns Assset [] {
  Asset [] result = [];
  foreach var [_, asset] in assets.entries() {
 if asset.faculty == faculty {
  result.push(asset);
}
}
return result;
}


//for adding a schedule to an existing asset
resource function post addSchedule (string assetTag,@http:Payload Schedule schedule) returns json {
Asset? maybeAsset = assets[assetTag];
if maybeAsset is Asset{
maybeAsset.schedules.push(schedule);
assets[assetTag] = maybeAsset;
return {message: "The schedule was added successfully"};
}
return {message: "Asset wasn't found"};
}

// get the overdue assets

resource function get overdue () returns Asset[] {
time:utc now = time:utcNow();

Asset [] result = [];
foreach var [_, asset] in assets.entries(){
foreach var sch in asset.schedules {
string dueStr = sch.dueDate +"T00:00:00Z";
var dueOrErr = time:utcFromString(dueStr);

if dueOrErr is time:Utc {
 int diff = <int> time:utcDiffSeconds(now, dueOrErr);
 if diff>0{
 result.push(asset);
 break;
}
}
}
}
return result;
}
} 
    
