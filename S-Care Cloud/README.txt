S-CARE CLOUD - DATABASE-CONNECTED VERSION
=========================================
1. Install Python 3.8 or newer (python.org). No other packages are needed.
2. Double-click start.bat (Windows) or run ./start.sh (Mac/Linux).
3. Open http://localhost:8000 in your browser.
   Open the app through this address. Opening S-Care_Cloud.html directly
   from the folder will NOT connect to the database.

What is saved to scare_cloud.db
  - Department & sub-department master: new and edited departments
  - Service items: new items, Disable / Enable
  - Front desk: patient registrations, invoices and payments
The billing "Department" and "Service item" lists, the Appointments department
list and the Service items screen all read from the database.

To let other computers on your network use it:  set HOST=0.0.0.0 before starting.
Back up by copying scare_cloud.db while the server is stopped.
