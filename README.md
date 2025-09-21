# Assignment 1 – Asset Management RESTful API

## 📘 Course Information
- **Course Title:** Distributed Systems and Applications  
- **Course Code:** DSA612S  
- **Assessment:** First Assignment  
- **Released on:** 27/08/2025  
- **Due date:** 21/09/2025 at 23h59  
- **Total Marks:** 100

## 📖 Project Description
This project is a **RESTful API built in Ballerina** for the **Facilities Directorate at NUST**.  
The system manages university-owned assets such as laboratory equipment, servers, and vehicles.  

Each asset contains details like:
- Asset Tag (unique key)  
- Name  
- Faculty and Department  
- Date Acquired  
- Current Status (**ACTIVE**, **UNDER_REPAIR**, or **DISPOSED**)

Assets can also include:
- **Components** – parts of the asset (e.g., motor in a printer, hard drive in a server).  
- **Maintenance Schedules** – servicing plans with due dates (e.g., quarterly/yearly checks).  
- **Work Orders** – reports when assets break and need fixing.  
- **Tasks** – small jobs under a work order (e.g., replace screen, update antivirus).  

---

## 🎯 Features Implemented
- **Create & Manage Assets** – add, update, look up, or remove assets.  
- **View Assets** – retrieve all assets or filter by faculty.  
- **Overdue Check** – identify assets with maintenance schedules past their due dates.  
- **Manage Components** – add/remove components for an asset.  
- **Manage Schedules** – add/remove maintenance schedules for an asset.  
- **Manage Work Orders** – open, update, or close work orders.  
- **Manage Tasks** – add/remove tasks under a work order.

The main database is implemented as a **map/table**, where each asset is identified by its `assetTag`.

---

## 📂 Project Structure

- service.bal # Ballerina service file (API endpoints)
-client.bal # Ballerina client file (test client)
- README.md # Project description (this file)

{
  "assetTag": "EQ-001",
  "name": "3D Printer",
  "faculty": "Computing & Informatics",
  "department": "Software Engineering",
  "status": "ACTIVE",
  "acquiredDate": "2024-03-10",
  "components": {},
   "schedules": {},
  "workOrders": {}
}

▶️ Running the Project

1. Install Ballerina
2. Clone the repository:
git clone <your-repo-link>
cd <repo-folder>

3. Run the service:
bal run service.bal

4. In a new terminal, run the client to test the API:
bal run client.bal

Endpoints summary:
POST /assets        -> add new asset
GET /assets         -> view all assets
GET /assets/{tag}   -> view asset by ID
PUT /assets/{tag}   -> update asset
DELETE /assets/{tag} -> remove asset
GET /assets/faculty/{name} -> filter by faculty

Limitations / Future work
Something simple and human-sounding, like:

The project is limited to in-memory storage using maps/tables, so data is lost when the service restarts. In future, a database could be added.

How the client works
Brief explanation:

The client was written to demonstrate the main functions (adding/updating assets, viewing all assets, filtering by faculty, overdue checks, etc.). It connects to the service and prints the responses.
