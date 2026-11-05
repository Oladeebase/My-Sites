#!/usr/bin/env python3
"""S-Care Cloud server: serves the app and a small JSON API backed by SQLite.
Run:  python server.py            (then open http://localhost:8000)
Needs only Python 3.8+ (no extra packages)."""
import json, os, sqlite3, sys, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.environ.get('SCARE_DB', os.path.join(HERE, 'scare_cloud.db'))
APP_FILE = os.path.join(HERE, 'S-Care_Cloud.html')
lock = threading.Lock()

def conn():
    c = sqlite3.connect(DB_PATH, timeout=15)
    c.row_factory = sqlite3.Row
    c.execute('PRAGMA foreign_keys=ON')
    return c

def b(v): return 1 if v else 0

def catalogue(c):
    deps = []
    for d in c.execute('SELECT * FROM departments ORDER BY id'):
        subs = [[s['name'], s['group_name'] or ''] for s in
                c.execute('SELECT name,group_name FROM sub_departments WHERE department_id=? ORDER BY id', (d['id'],))]
        deps.append({'code': d['code'], 'name': d['name'], 'short': d['short_name'] or '', 'type': d['dept_type'] or 'Laboratory',
                     'status': d['status'] or 'Active', 'print': d['print_title'] or '',
                     'doc': bool(d['needs_doctor']), 'sample': bool(d['needs_sample']), 'subs': subs})
    items = []
    for r in c.execute('''SELECT s.*, d.name AS dept FROM service_items s JOIN departments d ON d.id=s.department_id
                          ORDER BY d.id, s.sort_order, s.code'''):
        items.append({'code': r['code'], 'name': r['name'], 'dept': r['dept'], 'sample': r['sample_type'] or '\u2014',
                      'tat': r['turnaround'] or '\u2014', 'price': r['price'], 'hmo': r['hmo_price'] or 0,
                      'home': bool(r['home_collection']), 'fasting': bool(r['fasting']), 'disabled': bool(r['disabled'])})
    return {'departments': deps, 'items': items}

def dept_id(c, name):
    r = c.execute('SELECT id FROM departments WHERE name=?', (name,)).fetchone()
    return r['id'] if r else None

def save_department(c, d):
    name = (d.get('name') or '').strip()
    if not name: raise ValueError('Department name required')
    row = c.execute('SELECT id FROM departments WHERE code=?', (d['code'],)).fetchone()
    vals = (name, d.get('short'), d.get('type'), d.get('status', 'Active'), d.get('print'), b(d.get('doc')), b(d.get('sample')))
    if row:
        c.execute('''UPDATE departments SET name=?,short_name=?,dept_type=?,status=?,print_title=?,needs_doctor=?,needs_sample=? WHERE id=?''', vals + (row['id'],))
        did = row['id']
    else:
        c.execute('''INSERT INTO departments(name,short_name,dept_type,status,print_title,needs_doctor,needs_sample,code) VALUES(?,?,?,?,?,?,?,?)''', vals + (d['code'],))
        did = c.lastrowid
    c.execute('DELETE FROM sub_departments WHERE department_id=?', (did,))
    c.executemany('INSERT INTO sub_departments(department_id,name,group_name) VALUES(?,?,?)',
                  [(did, s[0], s[1] if len(s) > 1 else '') for s in d.get('subs', [])])
    return {'ok': True}

def save_item(c, t):
    did = dept_id(c, t['dept'])
    if did is None: raise ValueError('Unknown department: %s' % t['dept'])
    nxt = c.execute('SELECT COALESCE(MAX(sort_order),0)+1 FROM service_items WHERE department_id=?', (did,)).fetchone()[0]
    c.execute('''INSERT INTO service_items(code,name,department_id,sample_type,turnaround,price,hmo_price,home_collection,fasting,disabled,sort_order)
                 VALUES(?,?,?,?,?,?,?,?,?,?,?)
                 ON CONFLICT(code) DO UPDATE SET name=excluded.name, department_id=excluded.department_id, sample_type=excluded.sample_type,
                 turnaround=excluded.turnaround, price=excluded.price, hmo_price=excluded.hmo_price,
                 home_collection=excluded.home_collection, fasting=excluded.fasting, disabled=excluded.disabled''',
              (t['code'], t['name'], did, t.get('sample'), t.get('tat'), float(t.get('price') or 0), float(t.get('hmo') or 0),
               b(t.get('home')), b(t.get('fasting')), b(t.get('disabled')), nxt))
    return {'ok': True}

def toggle_item(c, t):
    c.execute('UPDATE service_items SET disabled=? WHERE code=?', (b(t.get('disabled')), t['code']))
    return {'ok': True}

def save_patient(c, p):
    f = p.get('fields', {})
    uhid = str(p['uhid']); name = p['name']
    known = {'Full name', 'Age', 'Gender', 'Mobile number', 'Email', 'City', 'Referred by', 'Patient source'}
    extra = {k: v for k, v in f.items() if k not in known and v != ''}
    age = f.get('Age', '')
    c.execute('''INSERT INTO patients(uhid,name,age,gender,phone,email,address,referred_by,source,extra_json)
                 VALUES(?,?,?,?,?,?,?,?,?,?)
                 ON CONFLICT(uhid) DO UPDATE SET name=excluded.name, age=excluded.age, gender=excluded.gender, phone=excluded.phone,
                 email=excluded.email, address=excluded.address, referred_by=excluded.referred_by, source=excluded.source, extra_json=excluded.extra_json''',
              (uhid, name, int(age) if str(age).isdigit() else None, f.get('Gender'), f.get('Mobile number'), f.get('Email'),
               f.get('City'), f.get('Referred by'), f.get('Patient source') or 'Front desk', json.dumps(extra, ensure_ascii=False)))
    return {'ok': True}

def save_invoice(c, i):
    uhid = str(i['uhid'])
    if not c.execute('SELECT 1 FROM patients WHERE uhid=?', (uhid,)).fetchone():
        c.execute('INSERT INTO patients(uhid,name) VALUES(?,?)', (uhid, i.get('name') or 'Unknown'))
    paid = float(i.get('paid') or 0); net = float(i['net'])
    status = 'Paid' if paid >= net else ('Part-paid' if paid > 0 else 'Open')
    cur = c.execute('''INSERT INTO invoices(invoice_no,uhid,gross,discount,net,status,referral) VALUES(?,?,?,?,?,?,?)''',
                    (i['no'], uhid, i['gross'], i['disc'], net, status, i.get('referral')))
    iid = cur.lastrowid
    for l in i['lines']:
        code = c.execute('SELECT s.code FROM service_items s JOIN departments d ON d.id=s.department_id WHERE s.name=? AND (d.name=? OR ? IS NULL) LIMIT 1',
                         (l['name'], l.get('dept'), l.get('dept'))).fetchone()
        c.execute('INSERT INTO invoice_items(invoice_id,service_code,description,department,rate,qty) VALUES(?,?,?,?,?,?)',
                  (iid, code['code'] if code else None, l['name'], l.get('dept'), l['rate'], l['qty']))
    if paid > 0:
        m = i.get('mode') or 'Cash'
        m = {'Card': 'POS'}.get(m, m)
        if m not in ('Cash', 'POS', 'Transfer', 'Credit', 'Advance'): m = 'Cash'
        c.execute('INSERT INTO payments(invoice_id,receipt_no,method,amount) VALUES(?,?,?,?)', (iid, 'RC-' + i['no'], m, min(paid, net) if paid > net else paid))
    return {'ok': True, 'invoice_id': iid}

ROUTES = {
    ('POST', '/api/departments'): save_department,
    ('POST', '/api/service-items'): save_item,
    ('POST', '/api/service-items/toggle'): toggle_item,
    ('POST', '/api/patients'): save_patient,
    ('POST', '/api/invoices'): save_invoice,
}

class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype='application/json'):
        data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype + ('; charset=utf-8' if ctype.startswith('text') or 'json' in ctype else ''))
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers(); self.wfile.write(data)

    def do_GET(self):
        p = urlparse(self.path).path
        if p in ('/', '/index.html', '/S-Care_Cloud.html'):
            with open(APP_FILE, 'rb') as f: return self._send(200, f.read(), 'text/html')
        if p == '/api/catalogue':
            with lock, conn() as c: return self._send(200, catalogue(c))
        if p == '/api/health': return self._send(200, {'ok': True})
        self._send(404, {'error': 'not found'})

    def do_POST(self):
        p = urlparse(self.path).path
        fn = ROUTES.get(('POST', p))
        if not fn: return self._send(404, {'error': 'not found'})
        try:
            n = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(n) or b'{}')
            with lock:
                c = conn()
                try:
                    res = fn(c, body); c.commit()
                finally: c.close()
            self._send(200, res)
        except (ValueError, KeyError, sqlite3.Error) as e:
            self._send(400, {'error': str(e)})

    def log_message(self, fmt, *a):
        sys.stderr.write('%s - %s\n' % (self.address_string(), fmt % a))

if __name__ == '__main__':
    host = os.environ.get('HOST', '127.0.0.1'); port = int(os.environ.get('PORT', '8000'))
    if not os.path.exists(DB_PATH): sys.exit('Database not found: ' + DB_PATH)
    print('S-Care Cloud running at http://%s:%d  (database: %s)' % ('localhost' if host == '127.0.0.1' else host, port, DB_PATH))
    ThreadingHTTPServer((host, port), H).serve_forever()
