-- S-Care Cloud database schema (SQLite; portable to PostgreSQL/MySQL with minor type changes)
PRAGMA foreign_keys = ON;

-- ===== Access control =====
CREATE TABLE modules (key TEXT PRIMARY KEY, label TEXT NOT NULL);
CREATE TABLE roles (name TEXT PRIMARY KEY, description TEXT, sort_order INTEGER);
CREATE TABLE role_modules (role TEXT REFERENCES roles(name) ON DELETE CASCADE,
                           module_key TEXT REFERENCES modules(key) ON DELETE CASCADE,
                           PRIMARY KEY (role, module_key));
CREATE TABLE branches (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL);
CREATE TABLE users (
  id INTEGER PRIMARY KEY, name TEXT NOT NULL, username TEXT UNIQUE NOT NULL,
  role TEXT REFERENCES roles(name), branch_id INTEGER REFERENCES branches(id),
  status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Inactive','Suspended')),
  password_salt TEXT, password_hash TEXT, must_change_password INTEGER NOT NULL DEFAULT 1,
  last_login_at TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP);

-- ===== Departments, services, tests =====
CREATE TABLE departments (
  id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT UNIQUE NOT NULL, short_name TEXT,
  dept_type TEXT, status TEXT DEFAULT 'Active', print_title TEXT,
  needs_doctor INTEGER DEFAULT 0, needs_sample INTEGER DEFAULT 0);
CREATE TABLE sub_departments (id INTEGER PRIMARY KEY, department_id INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  name TEXT NOT NULL, group_name TEXT);
CREATE TABLE service_categories (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL);
CREATE TABLE services (id INTEGER PRIMARY KEY, category_id INTEGER NOT NULL REFERENCES service_categories(id),
  name TEXT NOT NULL, price NUMERIC NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1, UNIQUE(category_id,name));
CREATE TABLE test_catalogue (code TEXT PRIMARY KEY, name TEXT NOT NULL, department TEXT, turnaround TEXT,
  price NUMERIC NOT NULL DEFAULT 0, home_collection INTEGER DEFAULT 0, disabled INTEGER DEFAULT 0);
CREATE TABLE instruments (id INTEGER PRIMARY KEY, model TEXT UNIQUE NOT NULL, maker TEXT, kind TEXT,
  port INTEGER, protocol TEXT, state TEXT DEFAULT 'offline');
CREATE TABLE test_parameters (id INTEGER PRIMARY KEY, test_name TEXT NOT NULL,
  instrument_id INTEGER REFERENCES instruments(id), analyte TEXT NOT NULL, unit TEXT, ref_low REAL, ref_high REAL);
CREATE TABLE reference_ranges (analyte TEXT PRIMARY KEY, low REAL, high REAL, unit TEXT);

-- ===== Report templates =====
CREATE TABLE result_templates (key TEXT PRIMARY KEY, category TEXT, label TEXT NOT NULL, blocks_json TEXT NOT NULL);
CREATE TABLE sonography_templates (id INTEGER PRIMARY KEY, group_name TEXT, label TEXT NOT NULL, body TEXT NOT NULL);

-- ===== Patients & front desk =====
CREATE TABLE patients (
  uhid TEXT PRIMARY KEY, name TEXT NOT NULL, age INTEGER, gender TEXT, phone TEXT, email TEXT, address TEXT,
  referred_by TEXT, source TEXT DEFAULT 'Front desk', registered_at TEXT DEFAULT CURRENT_TIMESTAMP,
  registered_by INTEGER REFERENCES users(id));
CREATE TABLE appointments (
  id INTEGER PRIMARY KEY, uhid TEXT NOT NULL REFERENCES patients(uhid), service_id INTEGER REFERENCES services(id),
  scheduled_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled','Checked in','Billed','Cancelled','No-show')),
  notes TEXT, created_by INTEGER REFERENCES users(id), created_at TEXT DEFAULT CURRENT_TIMESTAMP);

-- ===== Billing =====
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY, invoice_no TEXT UNIQUE NOT NULL, uhid TEXT NOT NULL REFERENCES patients(uhid),
  invoice_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, gross NUMERIC NOT NULL DEFAULT 0, discount NUMERIC NOT NULL DEFAULT 0,
  net NUMERIC NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Paid','Part-paid','Cancelled','Refunded')),
  referral TEXT, created_by INTEGER REFERENCES users(id));
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  service_id INTEGER REFERENCES services(id), test_code TEXT REFERENCES test_catalogue(code),
  description TEXT NOT NULL, rate NUMERIC NOT NULL, qty INTEGER NOT NULL DEFAULT 1);
CREATE TABLE payments (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id), receipt_no TEXT UNIQUE,
  paid_at TEXT DEFAULT CURRENT_TIMESTAMP, method TEXT CHECK (method IN ('Cash','POS','Transfer','Credit','Advance')),
  amount NUMERIC NOT NULL, received_by INTEGER REFERENCES users(id));
CREATE TABLE refunds (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id), amount NUMERIC NOT NULL, reason TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected','Paid')),
  requested_by INTEGER REFERENCES users(id), approved_by INTEGER REFERENCES users(id), created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE expenses (id INTEGER PRIMARY KEY, expense_date TEXT NOT NULL, category TEXT, description TEXT,
  amount NUMERIC NOT NULL, recorded_by INTEGER REFERENCES users(id));

-- ===== Samples & results =====
CREATE TABLE samples (
  id INTEGER PRIMARY KEY, barcode TEXT UNIQUE NOT NULL, invoice_item_id INTEGER REFERENCES invoice_items(id),
  uhid TEXT REFERENCES patients(uhid), sample_type TEXT,
  status TEXT DEFAULT 'Collected' CHECK (status IN ('Collected','Received','Processing','Reported','Rejected')),
  collected_at TEXT, collected_by INTEGER REFERENCES users(id), reject_reason TEXT);
CREATE TABLE results (
  id INTEGER PRIMARY KEY, sample_id INTEGER REFERENCES samples(id), invoice_item_id INTEGER REFERENCES invoice_items(id),
  test_code TEXT REFERENCES test_catalogue(code), analyte TEXT, value TEXT, unit TEXT, ref_low REAL, ref_high REAL, flag TEXT,
  source TEXT DEFAULT 'Manual' CHECK (source IN ('Manual','Instrument')), instrument_id INTEGER REFERENCES instruments(id),
  entered_by INTEGER REFERENCES users(id), validated_by INTEGER REFERENCES users(id),
  status TEXT DEFAULT 'Draft' CHECK (status IN ('Draft','Validated','Released')), created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE imaging_reports (
  id INTEGER PRIMARY KEY, uhid TEXT REFERENCES patients(uhid), invoice_item_id INTEGER REFERENCES invoice_items(id),
  department TEXT, template_id INTEGER REFERENCES sonography_templates(id), body TEXT,
  status TEXT DEFAULT 'Draft' CHECK (status IN ('Draft','Final')), reported_by INTEGER REFERENCES users(id), reported_at TEXT);

-- ===== Stock, HR, comms, audit =====
CREATE TABLE stock_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, department TEXT, batch_no TEXT, expiry_date TEXT,
  quantity INTEGER NOT NULL DEFAULT 0, reorder_level INTEGER NOT NULL DEFAULT 0, supplier TEXT);
CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY, po_no TEXT UNIQUE, supplier TEXT, status TEXT DEFAULT 'Open',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP, created_by INTEGER REFERENCES users(id));
CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY, po_id INTEGER NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  stock_item_id INTEGER REFERENCES stock_items(id), quantity INTEGER NOT NULL);
CREATE TABLE staff (id INTEGER PRIMARY KEY, name TEXT NOT NULL, designation TEXT, gross_monthly NUMERIC,
  allowance_1 NUMERIC, allowance_2 NUMERIC, status TEXT DEFAULT 'Available', user_id INTEGER REFERENCES users(id));
CREATE TABLE sms_log (id INTEGER PRIMARY KEY, uhid TEXT REFERENCES patients(uhid), phone TEXT, message TEXT,
  status TEXT, sent_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE audit_log (id INTEGER PRIMARY KEY, at TEXT DEFAULT CURRENT_TIMESTAMP, user_id INTEGER REFERENCES users(id),
  action TEXT NOT NULL, entity TEXT, entity_id TEXT, detail TEXT);

CREATE INDEX ix_appt_uhid ON appointments(uhid, scheduled_at);
CREATE INDEX ix_inv_uhid ON invoices(uhid, invoice_date);
CREATE INDEX ix_items_inv ON invoice_items(invoice_id);
CREATE INDEX ix_pay_inv ON payments(invoice_id);
CREATE INDEX ix_samples_uhid ON samples(uhid);
CREATE INDEX ix_results_sample ON results(sample_id);
CREATE INDEX ix_stock_exp ON stock_items(expiry_date);
