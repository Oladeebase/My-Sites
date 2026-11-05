BEGIN TRANSACTION;
CREATE TABLE appointments (
  id INTEGER PRIMARY KEY, uhid TEXT NOT NULL REFERENCES patients(uhid), service_id INTEGER REFERENCES services(id),
  scheduled_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled','Checked in','Billed','Cancelled','No-show')),
  notes TEXT, created_by INTEGER REFERENCES users(id), created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE audit_log (id INTEGER PRIMARY KEY, at TEXT DEFAULT CURRENT_TIMESTAMP, user_id INTEGER REFERENCES users(id),
  action TEXT NOT NULL, entity TEXT, entity_id TEXT, detail TEXT);
CREATE TABLE branches (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL);
INSERT INTO "branches" VALUES(1,'Lagos Head Office');
INSERT INTO "branches" VALUES(2,'Egbeda Branch');
INSERT INTO "branches" VALUES(3,'Abuja Branch');
CREATE TABLE departments (
  id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT UNIQUE NOT NULL, short_name TEXT,
  dept_type TEXT, status TEXT DEFAULT 'Active', print_title TEXT,
  needs_doctor INTEGER DEFAULT 0, needs_sample INTEGER DEFAULT 0);
INSERT INTO "departments" VALUES(1,'01','Haematology','HAE','Laboratory','Active','Department of Haematology',1,1);
INSERT INTO "departments" VALUES(2,'02','Chemical Pathology','CHP','Laboratory','Active','Department of Chemical Pathology',1,1);
INSERT INTO "departments" VALUES(3,'03','Immunology & Hormones','IMM','Laboratory','Active','Immunoassay & Endocrinology',1,1);
INSERT INTO "departments" VALUES(4,'04','Serology','SER','Laboratory','Active','Department of Serology',1,1);
INSERT INTO "departments" VALUES(5,'05','Microbiology','MIC','Laboratory','Active','Department of Microbiology',1,1);
INSERT INTO "departments" VALUES(6,'06','Histopathology','HIS','Laboratory','Active','Histopathology & Cytology',1,1);
INSERT INTO "departments" VALUES(7,'07','Ultrasound','USG','Imaging','Active','Ultrasound Report',1,0);
INSERT INTO "departments" VALUES(8,'08','X-Ray','XRY','Imaging','Active','Radiology Report',1,0);
INSERT INTO "departments" VALUES(9,'09','Cardiology','CAR','Imaging','Active','Cardiology Report',1,0);
INSERT INTO "departments" VALUES(10,'10','Consultation','OPD','Clinical','Active','Consultation Note',0,0);
INSERT INTO "departments" VALUES(11,'11','Sample collection','COL','Sample collection','Active','',0,0);
INSERT INTO "departments" VALUES(12,'12','Packages','PKG','Packages','Active','Health Screening Report',0,0);
INSERT INTO "departments" VALUES(13,'13','CT Scan','CT','Imaging','Inactive','CT Report',1,0);
CREATE TABLE expenses (id INTEGER PRIMARY KEY, expense_date TEXT NOT NULL, category TEXT, description TEXT,
  amount NUMERIC NOT NULL, recorded_by INTEGER REFERENCES users(id));
CREATE TABLE imaging_reports (
  id INTEGER PRIMARY KEY, uhid TEXT REFERENCES patients(uhid), invoice_item_id INTEGER REFERENCES invoice_items(id),
  department TEXT, template_id INTEGER REFERENCES sonography_templates(id), body TEXT,
  status TEXT DEFAULT 'Draft' CHECK (status IN ('Draft','Final')), reported_by INTEGER REFERENCES users(id), reported_at TEXT);
CREATE TABLE instruments (id INTEGER PRIMARY KEY, model TEXT UNIQUE NOT NULL, maker TEXT, kind TEXT,
  port INTEGER, protocol TEXT, state TEXT DEFAULT 'offline');
INSERT INTO "instruments" VALUES(1,'BC-5000','Mindray','Haematology analyser',5001,'HL7','offline');
INSERT INTO "instruments" VALUES(2,'BS-200','Mindray','Chemistry analyser',5002,'HL7 / ASTM','offline');
INSERT INTO "instruments" VALUES(3,'Maglumi 800','Snibe','Immunoassay (CLIA) analyser',5003,'ASTM','offline');
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  service_id INTEGER REFERENCES services(id), test_code TEXT REFERENCES test_catalogue(code),
  description TEXT NOT NULL, rate NUMERIC NOT NULL, qty INTEGER NOT NULL DEFAULT 1);
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY, invoice_no TEXT UNIQUE NOT NULL, uhid TEXT NOT NULL REFERENCES patients(uhid),
  invoice_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, gross NUMERIC NOT NULL DEFAULT 0, discount NUMERIC NOT NULL DEFAULT 0,
  net NUMERIC NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Paid','Part-paid','Cancelled','Refunded')),
  referral TEXT, created_by INTEGER REFERENCES users(id));
CREATE TABLE modules (key TEXT PRIMARY KEY, label TEXT NOT NULL);
INSERT INTO "modules" VALUES('dashboard','Dashboard');
INSERT INTO "modules" VALUES('patients','Registration');
INSERT INTO "modules" VALUES('billing','OPD billing');
INSERT INTO "modules" VALUES('appointments','Appointments');
INSERT INTO "modules" VALUES('diagnostics','Sample workflow');
INSERT INTO "modules" VALUES('instruments','Instrument interface');
INSERT INTO "modules" VALUES('sonography','Sonography');
INSERT INTO "modules" VALUES('result-samples','Result samples');
INSERT INTO "modules" VALUES('quality','Quality & audit');
INSERT INTO "modules" VALUES('reports','Reports');
INSERT INTO "modules" VALUES('department','Department master');
INSERT INTO "modules" VALUES('services','Service items');
INSERT INTO "modules" VALUES('users','Users & roles');
INSERT INTO "modules" VALUES('accounts','Accounts');
INSERT INTO "modules" VALUES('stock','Stock & procurement');
INSERT INTO "modules" VALUES('payroll','Payroll & HR');
INSERT INTO "modules" VALUES('sms','SMS configuration');
CREATE TABLE patients (
  uhid TEXT PRIMARY KEY, name TEXT NOT NULL, age INTEGER, gender TEXT, phone TEXT, email TEXT, address TEXT,
  referred_by TEXT, source TEXT DEFAULT 'Front desk', registered_at TEXT DEFAULT CURRENT_TIMESTAMP,
  registered_by INTEGER REFERENCES users(id));
CREATE TABLE payments (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id), receipt_no TEXT UNIQUE,
  paid_at TEXT DEFAULT CURRENT_TIMESTAMP, method TEXT CHECK (method IN ('Cash','POS','Transfer','Credit','Advance')),
  amount NUMERIC NOT NULL, received_by INTEGER REFERENCES users(id));
CREATE TABLE purchase_order_items (id INTEGER PRIMARY KEY, po_id INTEGER NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  stock_item_id INTEGER REFERENCES stock_items(id), quantity INTEGER NOT NULL);
CREATE TABLE purchase_orders (id INTEGER PRIMARY KEY, po_no TEXT UNIQUE, supplier TEXT, status TEXT DEFAULT 'Open',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP, created_by INTEGER REFERENCES users(id));
CREATE TABLE reference_ranges (analyte TEXT PRIMARY KEY, low REAL, high REAL, unit TEXT);
INSERT INTO "reference_ranges" VALUES('Fasting glucose',3.9,5.6,'mmol/L');
INSERT INTO "reference_ranges" VALUES('Haemoglobin',12.0,16.0,'g/dL');
INSERT INTO "reference_ranges" VALUES('Creatinine',60.0,110.0,'µmol/L');
INSERT INTO "reference_ranges" VALUES('ALT',7.0,56.0,'U/L');
INSERT INTO "reference_ranges" VALUES('Potassium',3.5,5.1,'mmol/L');
INSERT INTO "reference_ranges" VALUES('Urea',2.5,7.8,'mmol/L');
CREATE TABLE refunds (
  id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL REFERENCES invoices(id), amount NUMERIC NOT NULL, reason TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected','Paid')),
  requested_by INTEGER REFERENCES users(id), approved_by INTEGER REFERENCES users(id), created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE result_templates (key TEXT PRIMARY KEY, category TEXT, label TEXT NOT NULL, blocks_json TEXT NOT NULL);
INSERT INTO "result_templates" VALUES('hba1c','Chemistry','HbA1c (Glycated Haemoglobin)','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Glycated Haemoglobin (HbA1c)", "5.6 %", "4.0 &ndash; 6.5 %"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('creatinine-egfr','Chemistry','Creatinine & Estimated GFR','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Creatinine", "1.65 mg/dl", "0.4&ndash;1.5 mg/dl"]]}, {"type": "table", "cols": ["Test", "Result", "Range"], "rows": [["Estimated GFR (eGFR)", "49 ml/min/1.73m&sup2;", "&mdash;"]]}, {"type": "table", "cols": ["Kidney damage stage", "Description", "Estimated GFR (ml/min/1.73m&sup2;)"], "rows": [["1", "Normal or minimal kidney damage with normal GFR", "90+"], ["2", "Mild decrease in GFR", "60-89"], ["3", "Moderate decrease in GFR", "30-59"], ["4", "Severe decrease in GFR", "15-29"], ["5", "Kidney failure", "&lt; 15"]]}]');
INSERT INTO "result_templates" VALUES('rft','Chemistry','Renal Function Test (E/U/Cr)','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Urea", "24.70", "10.0-50.0 mg/dl"], ["Sodium", "143.3", "135-149 mmol/L"], ["Potassium", "6.66", "3.5-5.4 mmol/L"], ["Chloride", "108.9", "95-107 mmol/L"], ["TCO2", "25.3", "20.0-31.0 mmol/L"], ["Creatinine", "1.07", "0.4-1.5 mg/dl"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('fbs-panel','Chemistry','FBS, Uric Acid, PO4, T.Cal, VLDL, BUN & Globulin','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Fasting Blood Sugar", "93.98", "75-115 mg/dl"], ["Uric Acid", "4.0", "2.7-5.0 mg/dl (Female) / 3.4-7.0 mg/dl (Male)"], ["Total Calcium", "9.51", "8.10&ndash;10.4 mg/dl"], ["Blood Urea Nitrogen", "2.13", "2.5-8 mmol/L"], ["Phosphorus", "2.86", "2.49&ndash;4.49 mg/dl"], ["Globulin", "2.70", "2.0&ndash;3.5 g/dl"], ["VLDL", "17.5", "5-30 mg/dl"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('fbs','Chemistry','Fasting Blood Sugar (FBS)','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Fasting Blood Sugar", "103.3", "75-115 mg/dl"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('lipid','Chemistry','Lipid Profile','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. values"], "rows": [["Cholesterol", "180.73", "&lt;200 mg/dl Desirable &middot; 201-239 Borderline high &middot; &ge;240 High"], ["LDL (LDL-C)", "100.22", "&lt;100 Optimal &middot; 100-129 Near optimal &middot; 130-159 Borderline high &middot; 160-189 High &middot; &ge;190 Very high"], ["HDL (HDL-C)", "68.26", "&lt;40 Major risk &middot; 40-59 Higher the better &middot; &ge;60 Protective"], ["Triglyceride", "61.23", "&lt;150 Normal &middot; 150-199 Borderline high &middot; &ge;200 High &middot; &ge;500 Very high"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('tft','Chemistry','Thyroid Function Test (TFT)','[{"type": "table", "cols": ["Test", "Result", "Normal range"], "rows": [["Triiodothyronine (T3)", "1.08", "0.75 - 2.10 nmoI/L"], ["Free T3 (FT3)", "2.77", "2.00 - 4.20 pmol/L"], ["Thyroxine (T4)", "114.0", "66.9-163.5 nmol/L"], ["Free T4 (FT4)", "31.0", "11.46 &ndash; 22.14 pmoI/L"], ["Thyrotropin (TSH)", "1.31", "0.3 &ndash; 4.5 mIU/L"]]}, {"type": "text", "html": "<p><b>Comment:</b> Kindly correlate clinically.</p><p><b>Assay method:</b> CLIA</p><ul style=\"margin:6px 0 0 18px;padding:0;\"><li>About 90% of all thyroid problems can be diagnosed using measurements of TSH, FT4 and FT3.</li><li>If TSH, FT4 and FT3 are within normal range, thyroid dysfunction can be excluded.</li><li>Low TSH, high FT4 and FT3 indicate primary hyperthyroidism.</li><li>High TSH, low FT4 or FT3 indicates mild thyroid failure (subclinical hypothyroidism).</li></ul><p class=\"muted-sm\" style=\"margin-top:8px;\">Results auto-generated by CLIA Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('hsv','Serology','Herpes Simplex Virus (HSV) IgG & IgM','[{"type": "table", "cols": ["Investigation", "Result", "Units", "Ref. values"], "rows": [["Herpes Simplex 1 (IgG)", "1.69", "S/Co", "&lt;0.8 Negative / &gt;0.8 Positive"], ["Herpes Simplex 1 (IgM)", "0.29", "S/Co", "&lt;0.8 Negative / &gt;0.8 Positive"], ["Herpes Simplex 2 (IgG)", "0.34", "S/Co", "&lt;0.8 Negative / &gt;0.8 Positive"], ["Herpes Simplex 2 (IgM)", "0.18", "S/Co", "&lt;0.8 Negative / &gt;0.8 Positive"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Results auto-generated by Chemistry Analyzer.</p>"}]');
INSERT INTO "result_templates" VALUES('hepbc-rvs','Serology','Hepatitis B, C & RVS Screening','[{"type": "text", "html": "<p><b>Hepatitis B surface antigen (HBsAg):</b> Non-reactive as at the time of screening.</p><p><b>Hepatitis C virus screening:</b> Non-reactive as at the time of screening.</p><p><b>Retroviral screening (RVS):</b> Non-reactive as at the time of screening.</p>"}]');
INSERT INTO "result_templates" VALUES('widal-mp','Serology','MP & Widal Test','[{"type": "table", "cols": ["Antigen", "\"O\"", "\"H\""], "rows": [["S. typhi (D)", "1:40", "1:20"], ["S. paratyphi (A)", "1:20", "1:20"], ["S. paratyphi (B)", "1:20", "1:40"], ["S. paratyphi (C)", "1:20", "1:40"]]}, {"type": "text", "html": "<p class=\"muted-sm\">Comment: significant titre &ge; 1/80.</p><p><b>Malaria parasites:</b> Trophozoites of <i>Plasmodium falciparum</i> (+) seen.</p><p class=\"muted-sm\">High significant titre values are not specific for enteric fever (typhoid). A stool m/c/s and occult blood are advised for further evaluation.</p>"}]');
INSERT INTO "result_templates" VALUES('malaria','Microbiology','Malaria Parasite (MP)','[{"type": "text", "html": "<p><b>Malaria parasites:</b> Trophozoites of <i>Plasmodium falciparum</i> (+) seen.</p>"}]');
INSERT INTO "result_templates" VALUES('stool','Microbiology','Stool Analysis','[{"type": "text", "html": "<p><b>Specimen:</b> Stool</p><p><b>Appearance:</b> Dark brownish formed stool, no mucoid or blood stain seen.</p><p><b>Wet preparation (microscopy):</b> No cyst or ova of parasite seen.</p><p class=\"muted-sm\">Kindly correlate with clinical findings.</p>"}]');
INSERT INTO "result_templates" VALUES('stool-mcs','Microbiology','Stool M/C/S — Salmonella sp.','[{"type": "text", "html": "<p><b>Specimen:</b> Faecal sample</p><p><b>Appearance:</b> Brownish formed stool, no mucoid or blood stain seen.</p><p><b>Wet preparation (microscopy):</b> No ova or cyst of parasite seen.</p><p><b>Culture (identified organism):</b> Significant growth of Salmonella sp. Incubation at 37&deg;C for 48 hrs.</p>"}, {"type": "table", "cols": ["Antimicrobial", "Interpretation grade"], "rows": [["Ceftriaxone", "+++"], ["Levofloxacin", "++"], ["Gentamycin", "++"], ["Lyntriaxone", "R"], ["Ofloxacin", "R"], ["Cefixime", "R"], ["Nalidixic acid", "R"], ["Cefuroxime", "R"], ["Nitrofurantoin", "R"], ["Ampiclox", "R"], ["Cefotaxime", "R"], ["Amoxicillin/Clavulanate", "R"], ["Imipenem/Cilastatin", "R"]]}, {"type": "text", "html": "<p class=\"muted-sm\">S: Sensitive &middot; R: Resistant &middot; I: Intermediate. Kindly correlate with clinical findings.</p>"}]');
INSERT INTO "result_templates" VALUES('blood-culture','Microbiology','Blood Culture','[{"type": "text", "html": "<p><b>Specimen:</b> Whole blood</p><p><b>Culture (identified organism):</b> No bacteria growth. Incubation at 37&deg;C for 7 days.</p><p class=\"muted-sm\">Kindly correlate with clinical findings.</p>"}]');
INSERT INTO "result_templates" VALUES('troponin-i','Cardiac markers','Troponin I','[{"type": "table", "cols": ["Test", "Result", "Normal range"], "rows": [["Troponin I", "&lt;0.04 ng/mL", "0-0.1"]]}, {"type": "text", "html": "<p><b>Comment:</b> Kindly correlate clinically.</p><p class=\"muted-sm\"><b>N.B:</b> Diagnosis of MI requires clinical/ECG evidence of ischemia and demonstration of a rise and/or fall of Troponin &mdash; serial testing essential. Other causes of raised TnI include pulmonary embolism, cardiac failure, myocarditis, cardiomyopathy, cardiac contusion, arrhythmia, GI bleed, acute neurologic disease, aortic dissection, sepsis, renal failure and extreme exertion. Analytical interference may cause false positive/negative results.</p>"}]');
INSERT INTO "result_templates" VALUES('troponin-t','Cardiac markers','Troponin T','[{"type": "table", "cols": ["Test", "Result", "Normal range"], "rows": [["Troponin T", "&lt;0.03", "&lt;0.1 ng/ml"]]}]');
INSERT INTO "result_templates" VALUES('ckmb','Cardiac markers','CKMB','[{"type": "table", "cols": ["Investigation", "Patient result", "Ref. value"], "rows": [["CKMB", "&lt;1.00", "0.0 - 5.0 ng/mL"]]}]');
INSERT INTO "result_templates" VALUES('sfa','Andrology','Seminal Fluid Analysis (SFA)','[{"type": "table", "cols": ["Parameter", "Report", "Normal range"], "rows": [["Abstinence", "4 days", "2-7 days"], ["Method", "Coitus interruptus", "&mdash;"], ["Volume", "5 mls", "1.5-5.5 mls"], ["Colour", "Creamy white", "&mdash;"], ["pH", "7.5", "7.2-8.0"], ["Viscosity", "Normal", "Normal /+"], ["Liquefaction", "50 mins", "10-60 mins"], ["Agglutination", "Absent", "Absent /+"], ["Velocity", "Good", "Fair, Good, Excellent"], ["% Motility", "70%", "&ge; 40%"], ["% Active progressive (AP)", "45%", "&mdash;"], ["% Non-progressive (NP)", "25%", "&mdash;"], ["% Immotile", "30%", "&mdash;"], ["% Normal morphology", "80%", "&mdash;"], ["% Abnormal morphology", "20%", "&mdash;"], ["Sperm concentration", "4.0 x10&sup6; cells/ml", "&ge;15.0 x10&sup6; cells/ml"], ["Sperm numbers", "20.0 x10&sup6; cells", "&gt; 39.0 x10&sup6;"], ["WBC count", "1-2/hpf", "&mdash;"], ["Epithelial cells", "Nil", "&mdash;"]]}, {"type": "text", "html": "<p><b>Culture (identified organism):</b> No bacteria growth. Incubation at 37&deg;C for 48 hrs.</p><p class=\"muted-sm\">Kindly correlate with clinical findings.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-chest','Radiology','CT Scan — Chest','[{"type": "text", "html": "<p><b>Clinical history:</b> Past history of pneumonia.</p><p><b>Technique:</b> Serial axial pre and post contrast images were acquired; sagittal and coronal reformatted images were then generated.</p><p><b>Findings:</b> The heart is normal in size and contour. The pulmonary vasculatures are normal. Interlobular septal thickenings are seen in the superior lingual segment of the left upper lung lobe and the apical segment, as well as the right middle lobe. Ground glass appearance is seen in the left lower lung lobe and right lung. Traction bronchiectasis is seen in the basomedial segment of the right lower lung lobe. Mild atelectasis is seen in the right lower lung lobe. Both costophrenic angles are free. Bone window images show no abnormality.</p><p><b>Impression:</b> Overall features are consistent with fibrotic lung changes with mild right lung atelectasis from previous chest infection.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-lumbosacral','Radiology','CT Scan — Lumbosacral','[{"type": "text", "html": "<p><b>Clinical history:</b> Paraplegia &mdash; cause; rule out Ca. prostate.</p><p><b>Technique:</b> Serial axial non-contrast images were acquired; sagittal and coronal reformatted images were then generated.</p><p><b>Findings:</b> Straightening of the normal lumbar lordosis consistent with muscular spasm; alignment preserved. Anterior and lateral marginal osteophytes seen in L1-L5. Posterior marginal osteophytes seen in L1/L2, L2/L3 and L5/S1. Narrowing of intervertebral discs at L1-L2, L2-L3, L3-L4, L4-L5 and L5-S1 with vacuum phenomenon and endplate sclerosis. All lumbar facet joints narrowed bilaterally. No osteolytic or osteoblastic metastases or paravertebral collection seen. Narrowing of both sacroiliac joints with vacuum phenomenon.</p><p><b>Conclusion:</b> Severe lumbar spondylosis with muscle spasm. Bilateral sacroiliitis. No metastatic deposit seen.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-cranial','Radiology','CT Scan — Cranial','[{"type": "text", "html": "<p><b>Clinical indication:</b> History of forgetfulness and absent-mindedness.</p><p><b>Technique:</b> Serial pre and post-contrast axial images were acquired; reformatted sagittal and coronal images were then generated.</p><p><b>Findings:</b> The cerebrum, cerebellum, brainstem and ventricles are normal. No space-occupying lesion, bleed or abnormal collection seen; no unusual contrast enhancement. Pituitary gland appears normal. Both orbits and their contents are within normal limits. Bone window images show no abnormality. Mucosal thickening of the frontal and ethmoidal sinuses noted bilaterally with engorgement of both inferior nasal turbinates, in keeping with chronic rhinosinusitis. Remaining paranasal sinuses normal.</p><p><b>Impression:</b> Normal brain examination. Chronic rhinosinusitis.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-chest-abdomino','Radiology','CT Scan — Chest + Abdominopelvic','[{"type": "text", "html": "<p><b>Clinical history:</b> Cancer of the prostate.</p><p><b>Technique:</b> Serial axial pre and post contrast images were acquired; sagittal and coronal reformatted images were then generated.</p><p><b>Chest findings:</b> Heart normal in size and contour. Pulmonary vasculatures normal. Lung parenchymal density normal bilaterally, no diffuse or focal lesion. Both costophrenic angles free. Bone window images show multiple diffuse osteoblastic metastases involving the thoracic vertebrae, both scapulae and the left proximal humerus.</p><p><b>Abdominopelvic findings:</b> Liver enlarged (16.2cm at right MCL), smooth outline, normal density, no intrahepatic mass. Gallbladder moderately distended, normal wall. Spleen and pancreas normal. Kidneys normal in size with prompt contrast excretion; an oval thin-walled non-enhancing cyst in the mid pole of the left kidney (2.5cm); linear hyperdensities in both kidneys. Bowel loops normal. Bladder moderately distended with thickened wall. Prostate gland enlarged (approx. 40cm&sup3;) with lobulated outline, heterogeneous density and intravesical protrusion. Bone window images show multiple sclerotic lesions in the lumbar vertebrae, pelvic bones and proximal femurs.</p><p><b>Impression:</b> Hepatomegaly. Left renal cortical cyst (Bosniak I). Bilateral nephrolithiasis. Bone metastases (thoracic/lumbar vertebrae, scapular, pelvic and femoral) from known Ca. prostate.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-abdominopelvic','Radiology','CT Scan — Abdominopelvic','[{"type": "text", "html": "<p><b>Technique:</b> Serial axial pre and post contrast images were acquired; sagittal and coronal reformatted images were then generated.</p><p><b>Findings:</b> Liver normal in size (13.6cm craniocaudal span, right MCL), smooth outline, normal density, no intrahepatic mass or ductal dilatation. Gallbladder moderately distended with normal wall thickness. Spleen normal (6.6cm), smooth outline. Pancreas normal. Bowel loops normal, no increased free fluid, no significant lymphadenopathy. Both kidneys normal in size (Rk 9.5x4.7cm, Lk 9.6x3.8cm) with good corticomedullary differentiation and prompt contrast excretion. Two oval thick-walled hypodense cysts seen in the cortex of the right kidney, the largest in the upper pole measuring 2.4x1.8cm. No renal or ureteric calculus. Uterine bed empty, no adnexal mass. Urinary bladder well distended with normal wall thickness, no calculus. Bone window images and visualised lungs appear normal.</p><p><b>Impression:</b> Right renal cortical cysts &mdash; Bosniak I.</p>"}]');
INSERT INTO "result_templates" VALUES('ct-craniofacial','Radiology','CT Scan — Craniofacial','[{"type": "text", "html": "<p><b>Clinical indication:</b> Trauma to the head secondary to a fall.</p><p><b>Technique:</b> Serial non-contrast axial images were acquired; reformatted sagittal and coronal images were then generated.</p><p><b>Findings:</b> The cerebrum, cerebellum, brainstem and ventricles are normal. No space-occupying lesion, bleed or abnormal collection seen. Pituitary gland appears normal. Both orbits and their contents within normal limits. Bone window images show no abnormality; no fracture seen. Paranasal sinuses normal.</p><p><b>Impression:</b> Normal brain examination. No fracture or intracranial haemorrhage seen.</p>"}]');
CREATE TABLE results (
  id INTEGER PRIMARY KEY, sample_id INTEGER REFERENCES samples(id), invoice_item_id INTEGER REFERENCES invoice_items(id),
  test_code TEXT REFERENCES test_catalogue(code), analyte TEXT, value TEXT, unit TEXT, ref_low REAL, ref_high REAL, flag TEXT,
  source TEXT DEFAULT 'Manual' CHECK (source IN ('Manual','Instrument')), instrument_id INTEGER REFERENCES instruments(id),
  entered_by INTEGER REFERENCES users(id), validated_by INTEGER REFERENCES users(id),
  status TEXT DEFAULT 'Draft' CHECK (status IN ('Draft','Validated','Released')), created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE role_modules (role TEXT REFERENCES roles(name) ON DELETE CASCADE,
                           module_key TEXT REFERENCES modules(key) ON DELETE CASCADE,
                           PRIMARY KEY (role, module_key));
INSERT INTO "role_modules" VALUES('Administrator','dashboard');
INSERT INTO "role_modules" VALUES('Administrator','patients');
INSERT INTO "role_modules" VALUES('Administrator','appointments');
INSERT INTO "role_modules" VALUES('Administrator','billing');
INSERT INTO "role_modules" VALUES('Administrator','diagnostics');
INSERT INTO "role_modules" VALUES('Administrator','reports');
INSERT INTO "role_modules" VALUES('Administrator','department');
INSERT INTO "role_modules" VALUES('Administrator','services');
INSERT INTO "role_modules" VALUES('Administrator','users');
INSERT INTO "role_modules" VALUES('Administrator','accounts');
INSERT INTO "role_modules" VALUES('Administrator','stock');
INSERT INTO "role_modules" VALUES('Administrator','payroll');
INSERT INTO "role_modules" VALUES('Administrator','sms');
INSERT INTO "role_modules" VALUES('Front desk','dashboard');
INSERT INTO "role_modules" VALUES('Front desk','patients');
INSERT INTO "role_modules" VALUES('Front desk','appointments');
INSERT INTO "role_modules" VALUES('Front desk','billing');
INSERT INTO "role_modules" VALUES('Lab technician','dashboard');
INSERT INTO "role_modules" VALUES('Lab technician','diagnostics');
INSERT INTO "role_modules" VALUES('Lab technician','result-samples');
INSERT INTO "role_modules" VALUES('Lab technician','reports');
INSERT INTO "role_modules" VALUES('Accountant','dashboard');
INSERT INTO "role_modules" VALUES('Accountant','billing');
INSERT INTO "role_modules" VALUES('Accountant','reports');
INSERT INTO "role_modules" VALUES('Accountant','accounts');
INSERT INTO "role_modules" VALUES('Accountant','payroll');
INSERT INTO "role_modules" VALUES('Phlebotomist','dashboard');
INSERT INTO "role_modules" VALUES('Phlebotomist','diagnostics');
INSERT INTO "role_modules" VALUES('Lab manager','dashboard');
INSERT INTO "role_modules" VALUES('Lab manager','diagnostics');
INSERT INTO "role_modules" VALUES('Lab manager','reports');
INSERT INTO "role_modules" VALUES('Lab manager','department');
INSERT INTO "role_modules" VALUES('Lab manager','services');
INSERT INTO "role_modules" VALUES('Lab manager','users');
INSERT INTO "role_modules" VALUES('Lab manager','stock');
INSERT INTO "role_modules" VALUES('Lab secretary','dashboard');
INSERT INTO "role_modules" VALUES('Lab secretary','patients');
INSERT INTO "role_modules" VALUES('Lab secretary','appointments');
INSERT INTO "role_modules" VALUES('Lab secretary','diagnostics');
INSERT INTO "role_modules" VALUES('Lab secretary','result-samples');
INSERT INTO "role_modules" VALUES('Lab secretary','reports');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','instruments');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','dashboard');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','diagnostics');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','result-samples');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','reports');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','department');
INSERT INTO "role_modules" VALUES('Medical laboratory scientist','stock');
INSERT INTO "role_modules" VALUES('Pathologist','dashboard');
INSERT INTO "role_modules" VALUES('Pathologist','diagnostics');
INSERT INTO "role_modules" VALUES('Pathologist','result-samples');
INSERT INTO "role_modules" VALUES('Pathologist','reports');
INSERT INTO "role_modules" VALUES('Radiographer','dashboard');
INSERT INTO "role_modules" VALUES('Radiographer','diagnostics');
INSERT INTO "role_modules" VALUES('Radiographer','reports');
INSERT INTO "role_modules" VALUES('Sonographer','dashboard');
INSERT INTO "role_modules" VALUES('Sonographer','diagnostics');
INSERT INTO "role_modules" VALUES('Sonographer','sonography');
INSERT INTO "role_modules" VALUES('Sonographer','reports');
INSERT INTO "role_modules" VALUES('IT support','dashboard');
INSERT INTO "role_modules" VALUES('IT support','department');
INSERT INTO "role_modules" VALUES('IT support','users');
INSERT INTO "role_modules" VALUES('IT support','sms');
CREATE TABLE roles (name TEXT PRIMARY KEY, description TEXT, sort_order INTEGER);
INSERT INTO "roles" VALUES('Administrator','Full system access, including setup, billing, diagnostics, stock, payroll and user &amp; role management.',0);
INSERT INTO "roles" VALUES('Front desk','Registers patients, books appointments and takes OPD payments at the counter.',1);
INSERT INTO "roles" VALUES('Lab technician','Logs samples, updates the workflow board and enters preliminary results.',2);
INSERT INTO "roles" VALUES('Accountant','Reviews OPD billing, collections, financial registers and staff payroll.',3);
INSERT INTO "roles" VALUES('Phlebotomist','Collects samples at OPD and home-collection points and hands them to the lab.',4);
INSERT INTO "roles" VALUES('Lab manager','Oversees lab operations, test catalogue, reagent stock and staff access for the branch.',5);
INSERT INTO "roles" VALUES('Lab secretary','Handles patient registration, appointment booking and compiles each report before forwarding it to the Medical Laboratory Scientist for final release.',6);
INSERT INTO "roles" VALUES('Medical laboratory scientist','Processes samples, runs and verifies tests, handles quality control and reagent stock, and gives final release for compiled reports.',7);
INSERT INTO "roles" VALUES('Pathologist','Reviews and authorises laboratory reports before they are released.',8);
INSERT INTO "roles" VALUES('Radiographer','Performs imaging studies and manages the radiology report queue.',9);
INSERT INTO "roles" VALUES('Sonographer','Performs ultrasound studies and files the accompanying reports.',10);
INSERT INTO "roles" VALUES('IT support','Maintains system setup, staff accounts, SMS gateway and technical configuration.',11);
CREATE TABLE samples (
  id INTEGER PRIMARY KEY, barcode TEXT UNIQUE NOT NULL, invoice_item_id INTEGER REFERENCES invoice_items(id),
  uhid TEXT REFERENCES patients(uhid), sample_type TEXT,
  status TEXT DEFAULT 'Collected' CHECK (status IN ('Collected','Received','Processing','Reported','Rejected')),
  collected_at TEXT, collected_by INTEGER REFERENCES users(id), reject_reason TEXT);
CREATE TABLE service_categories (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL);
INSERT INTO "service_categories" VALUES(1,'Consultation');
INSERT INTO "service_categories" VALUES(2,'Haematology');
INSERT INTO "service_categories" VALUES(3,'Chemical Pathology');
INSERT INTO "service_categories" VALUES(4,'Microbiology');
INSERT INTO "service_categories" VALUES(5,'Serology');
INSERT INTO "service_categories" VALUES(6,'Radiology');
CREATE TABLE services (id INTEGER PRIMARY KEY, category_id INTEGER NOT NULL REFERENCES service_categories(id),
  name TEXT NOT NULL, price NUMERIC NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1, UNIQUE(category_id,name));
INSERT INTO "services" VALUES(1,1,'General OPD consultation',5000,1);
INSERT INTO "services" VALUES(2,1,'Specialist consultation',15000,1);
INSERT INTO "services" VALUES(3,1,'Follow-up review',3500,1);
INSERT INTO "services" VALUES(4,2,'Full blood count',8500,1);
INSERT INTO "services" VALUES(5,2,'ESR',3000,1);
INSERT INTO "services" VALUES(6,2,'Genotype',4000,1);
INSERT INTO "services" VALUES(7,2,'Blood group & Rh',3500,1);
INSERT INTO "services" VALUES(8,2,'Clotting profile',12000,1);
INSERT INTO "services" VALUES(9,3,'Fasting blood sugar',3000,1);
INSERT INTO "services" VALUES(10,3,'Liver function test',14000,1);
INSERT INTO "services" VALUES(11,3,'Kidney function test',14000,1);
INSERT INTO "services" VALUES(12,3,'Lipid profile',12500,1);
INSERT INTO "services" VALUES(13,3,'HbA1c',9000,1);
INSERT INTO "services" VALUES(14,4,'Urine m/c/s',7500,1);
INSERT INTO "services" VALUES(15,4,'Stool m/c/s',7000,1);
INSERT INTO "services" VALUES(16,4,'Wound swab m/c/s',8000,1);
INSERT INTO "services" VALUES(17,4,'Malaria parasite',3500,1);
INSERT INTO "services" VALUES(18,5,'HIV screening',5000,1);
INSERT INTO "services" VALUES(19,5,'Hepatitis B surface antigen',5000,1);
INSERT INTO "services" VALUES(20,5,'Widal test',4500,1);
INSERT INTO "services" VALUES(21,5,'VDRL',4500,1);
INSERT INTO "services" VALUES(22,6,'Chest X-ray',18000,1);
INSERT INTO "services" VALUES(23,6,'Abdominal ultrasound',25000,1);
INSERT INTO "services" VALUES(24,6,'Obstetric scan',22000,1);
CREATE TABLE sms_log (id INTEGER PRIMARY KEY, uhid TEXT REFERENCES patients(uhid), phone TEXT, message TEXT,
  status TEXT, sent_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE sonography_templates (id INTEGER PRIMARY KEY, group_name TEXT, label TEXT NOT NULL, body TEXT NOT NULL);
INSERT INTO "sonography_templates" VALUES(1,'Normal','Abdominal scan — Normal study','LIVER: The liver is normal in size, shape and outline with a liver span of about 12.87cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation. They measure about 9.18 x 3.42 x 5.57cm with a corresponding volume of 91.60ml (right) and 9.11 x 5.10 x 5.11cm with a corresponding volume of 124.43ml (left). The central echogenic complexes are normal, no demonstrable cysts, renal stones nor hydronephrosis.

The Pancreas and Spleen (span- 6.12cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

IMPRESSION: Normal study.');
INSERT INTO "sonography_templates" VALUES(2,'Hepatobiliary','Hepatic steatosis','LIVER: The liver is normal in size, shape and outline with a liver span of about 15.24cm. It has a uniform parenchymal echotexture with increased parenchymal echogenicity, no intrahepatic duct dilation.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.55 x 4.39 x 5.15cm with a corresponding volume of 116.63ml (right) and 4.94 x 4.90 x 5.87cm with a corresponding volume of 149.71ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas and Spleen (span- 8.25cm) are within normal limit.

URINARY BLADDER: The urinary bladder is well distended with urine and exhibits normal wall calibre thickness. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

IMPRESSION: Hepatic steatosis.');
INSERT INTO "sonography_templates" VALUES(3,'Hepatobiliary','Hepatic steatosis with splenomegaly','LIVER: The liver is normal in size, shape and outline with a liver span of about 15.24cm. It has a uniform parenchymal echotexture with increased parenchymal echogenicity, no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.55 x 4.39 x 5.15cm with a corresponding volume of 116.63ml (right) and 4.94 x 4.90 x 5.87cm with a corresponding volume of 149.71ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas is within normal limit. The Spleen is enlarged with a uniform parenchyma, measuring about 12.05cm in length.

URINARY BLADDER: The urinary bladder is well distended with urine and exhibits normal wall calibre thickness. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

IMPRESSION: 1. Hepatic steatosis.
2. Splenomegaly.');
INSERT INTO "sonography_templates" VALUES(4,'Hepatobiliary','Hepatomegaly with steatosis','LIVER: The liver is enlarged. It is regular in outline with a liver span of about 17.19cm. It has a uniform parenchymal echotexture with increased parenchymal echogenicity, no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 10.23 x 4.29 x 5.92cm with a corresponding volume of 136.24ml (right) and 9.81 x 5.81 x 6.09cm with a corresponding volume of 181.71ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas and Spleen (span- 8.27cm) are within normal limit.

URINARY BLADDER: The urinary bladder is well distended with urine and exhibits normal wall calibre thickness. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

IMPRESSION: Hepatomegaly with steatosis.');
INSERT INTO "sonography_templates" VALUES(5,'Hepatobiliary','Hepatic cyst','LIVER: The liver is normal in size, shape and outline with a liver span of about 11.71cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation. There is an ovoid shaped anechoic mass with posterior acoustic enhancement of about 5.36 x 4.28cm in size seen in the right lobe of the liver, no flow on colour Doppler interrogation.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 8.86 x 4.15 x 5.54cm with a corresponding volume of 106.68ml (right) and 9.37 x 4.35 x 5.79cm with a corresponding volume of 123.72ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas and Spleen (span- 7.64cm) are within normal limit.

IMPRESSION: Hepatic cyst.');
INSERT INTO "sonography_templates" VALUES(6,'Hepatobiliary','Hepatic metastases','LIVER: The liver is normal in size, shape and outline with a liver span of about 13.65cm, with inhomogeneous parenchymal echotexture, no intrahepatic duct dilation. There are multiple ovoid shaped, well-defined masses of variable attenuation with hypoechoic halo, the largest measuring about 4.45 x 4.05cm (right lobe) and 3.20 x 3.76cm (left lobe). No flow on colour Doppler interrogation.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 8.86 x 4.15 x 5.54cm with a corresponding volume of 106.68ml (right) and 9.37 x 4.35 x 5.79cm with a corresponding volume of 123.72ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas and Spleen (span- 7.64cm) are within normal limit.

IMPRESSION: Hepatic metastases ?Cause.
Contrast-enhanced abdomino-pelvic CT is advised.');
INSERT INTO "sonography_templates" VALUES(7,'Renal','Acquired cystic kidney disease','LIVER: The liver is normal in size, shape and outline with a liver span of about 15.52cm. Uniform parenchymal echotexture with increased parenchymal echogenicity, no intrahepatic duct dilation, no mass, abscess or cyst is seen.

KIDNEYS: Both kidneys are enlarged in size, regular outline with smooth contour. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 11.2 x 6.19 x 8.05cm with a corresponding volume of 294.36ml (right) and 13.46 x 6.73 x 7.79cm with a corresponding volume of 369.62ml (left). There are about four (4) and five (5) ovoid shaped, thin-walled, anechoic masses in the right and left kidney respectively; the largest measures about 5.39 x 4.97cm (right) and 4.71 x 4.45cm (left). No demonstrable renal stones nor hydronephrosis.

GALL BLADDER: The gall bladder is well distended, normal in size and wall thickness. No gall stone or sludge is seen.

GIT: Bowel loops seen appear normal in calibre with good peristalsis. No free peritoneal fluid seen. No intra-abdominal mass or collection is visualised. No appendiceal mass or abscess is detected. No ascites.

The Pancreas and Spleen (span- 8.03cm) are within normal limit.

A normal sized prostate gland is seen, marginated, well-defined with homogenous parenchymal echotexture and intact capsule. No calculi or focal lesion seen. It measures about 3.68 x 3.20 x 4.02cm with a corresponding volume of 24.74ml.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Acquired cystic kidney disease.');
INSERT INTO "sonography_templates" VALUES(8,'Renal','Bilateral simple renal cyst','LIVER: The liver is normal in size, shape and outline with a liver span of about 15.52cm. Uniform parenchymal echotexture with increased parenchymal echogenicity, no intrahepatic duct dilation, no mass, abscess or cyst is seen.

KIDNEYS: Both kidneys are enlarged in size, regular outline with smooth contour. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 11.2 x 6.19 x 8.05cm with a corresponding volume of 294.36ml (right) and 13.46 x 6.73 x 7.79cm with a corresponding volume of 369.62ml (left). An ovoid shaped, thin-walled, anechoic mass measuring about 5.39 x 4.97cm is seen in the superior pole of the right kidney and 4.71 x 4.45cm in the middle pole of the left kidney. No demonstrable renal stones nor hydronephrosis.

GALL BLADDER: The gall bladder is well distended, normal in size and wall thickness. No gall stone or sludge is seen.

GIT: Bowel loops seen appear normal in calibre with good peristalsis. No free peritoneal fluid seen. No intra-abdominal mass or collection is visualised. No appendiceal mass or abscess is detected. No ascites.

The Pancreas and Spleen (span- 8.03cm) are within normal limit.

A normal sized prostate gland is seen, marginated, well-defined with homogenous parenchymal echotexture and intact capsule. No calculi or focal lesion seen. It measures about 3.68 x 3.20 x 4.02cm with a corresponding volume of 24.74ml.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Bilateral simple renal cyst.');
INSERT INTO "sonography_templates" VALUES(9,'Renal','Bilateral nephrolithiasis','LIVER: The liver is normal in size, shape and outline with a liver span of about 11.73cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.55 x 4.39 x 5.15cm with a corresponding volume of 116.63ml (right) and 4.94 x 4.90 x 5.87cm with a corresponding volume of 149.71ml (left). Multiple ovoid shaped echogenic masses with posterior acoustic attenuation are demonstrated in both renal pelves, the largest measuring about 0.43cm (right) and 0.50cm (left), associated with mild pelvi-calyceal system dilatation. No cyst.

The Pancreas and Spleen (span- 8.08cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

IMPRESSION: 1. Bilateral nephrolithiasis.
2. Bilateral hydronephrosis.');
INSERT INTO "sonography_templates" VALUES(10,'Renal','Right nephrolithiasis','LIVER: The liver is normal in size (span- 13.48cm), shape, outline and echogenicities. No liver mass, abscess or cyst is detected. Both intra- and extra-hepatic ducts are not dilated. The IVC and aorta are normal sonographically.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour and normal cortical echotexture, measuring about 9.17 x 4.01 x 6.38cm with a corresponding volume of 122.71ml (right) and 9.95 x 5.26 x 5.33cm with a corresponding volume of 146.09ml (left). The right kidney shows multiple echogenic ovoid shaped masses with posterior acoustic attenuation, one of which measures about 0.35cm in diameter, located in the middle third of the right kidney, associated with mild pelvi-calyceal system dilatation, no cyst. No renal stone, hydronephrosis or cyst in the left kidney.

GALL BLADDER: The gall bladder is distended with clear bile, normal in size and wall thickness. No gall stone or sludge is seen.

GIT: Bowel loops seen appear normal in size and calibre with demonstrable peristalsis. No free peritoneal fluid seen. No intra-abdominal mass or collection, no appendiceal mass or abscess is detected.

The Pancreas and Spleen (span- 8.38cm) are within normal limit.

URINARY BLADDER: The urinary bladder is well distended with urine and exhibits normal wall calibre thickness. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

FINDINGS:
1. Right nephrolithiasis.
2. Right mild hydronephrosis.');
INSERT INTO "sonography_templates" VALUES(11,'Renal','Right nephrolithiasis with bladder calculi','LIVER: The liver is normal in size (span- 13.29cm), shape, outline and echogenicities. No liver mass, abscess or cyst is detected. Both intra- and extra-hepatic ducts are not dilated. The IVC and aorta are normal sonographically.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour and normal cortical echotexture, measuring about 10.25 x 4.61 x 5.97cm with a corresponding volume of 147.70ml (right) and 9.56 x 5.16 x 6.01cm with a corresponding volume of 155.22ml (left). The right kidney shows multiple echogenic ovoid shaped masses with posterior acoustic attenuation, measuring about 0.45cm in diameter, located in the middle third of the right kidney, associated with mild pelvi-calyceal system dilatation, no cyst. No renal stone, hydronephrosis or cyst in the left kidney.

GALL BLADDER: The gall bladder is distended with clear bile, normal in size and wall thickness. No gall stone or sludge is seen.

GIT: Bowel loops seen appear normal in size and calibre with demonstrable peristalsis. No free peritoneal fluid seen. No intra-abdominal mass or collection, no appendiceal mass or abscess is detected.

The Pancreas and Spleen (span- 6.57cm) are within normal limit.

URINARY BLADDER: The urinary bladder is well distended with urine containing echogenic structures with posterior acoustic attenuation, measuring about 4.8mm in diameter. Normal wall thickness. No mass, cystocoele, ureterocoele, calculus or polyp otherwise seen.

FINDINGS:
1. Right nephrolithiasis.
2. Right mild hydronephrosis.
3. Urinary bladder calculi.');
INSERT INTO "sonography_templates" VALUES(12,'Renal','Left nephrolithiasis with bladder calculi','LIVER: The liver is normal in size (span- 13.29cm), shape, outline and echogenicities. No liver mass, abscess or cyst is detected. Both intra- and extra-hepatic ducts are not dilated. The IVC and aorta are normal sonographically.

KIDNEYS: Both kidneys are normal in position, size and shape with smooth contour and normal cortical echotexture, measuring about 10.25 x 4.61 x 5.97cm with a corresponding volume of 147.70ml (right) and 9.56 x 5.16 x 6.01cm with a corresponding volume of 155.22ml (left). The left kidney shows multiple echogenic ovoid shaped masses with posterior acoustic attenuation, measuring about 0.45cm in diameter, located in the middle third of the left kidney, associated with mild pelvi-calyceal system dilatation, no cyst. No renal stone, hydronephrosis or cyst in the right kidney.

GALL BLADDER: The gall bladder is distended with clear bile, normal in size and wall thickness. No gall stone or sludge is seen.

GIT: Bowel loops seen appear normal in size and calibre with demonstrable peristalsis. No free peritoneal fluid seen. No intra-abdominal mass or collection, no appendiceal mass or abscess is detected.

The Pancreas and Spleen (span- 6.57cm) are within normal limit.

URINARY BLADDER: The urinary bladder is well distended with urine containing echogenic structures with posterior acoustic attenuation, measuring about 4.8mm in diameter. Normal wall thickness. No mass, cystocoele, ureterocoele, calculus or polyp otherwise seen.

FINDINGS:
1. Left nephrolithiasis.
2. Left hydronephrosis, Grade II.
3. Urinary bladder calculi.');
INSERT INTO "sonography_templates" VALUES(13,'Renal','Right ectopic kidney','LIVER: The liver is normal in size, shape and outline with a liver span of about 13.12cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: The right renal bed is empty; the right kidney is noted in the right iliac fossa below the umbilicus. Both kidneys are normal in size, shape, with smooth outline, normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.91 x 4.51 x 5.72cm with a corresponding volume of 133.71ml (right) and 9.56 x 5.55 x 6.04cm with a corresponding volume of 167.86ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

The Pancreas and Spleen (span- 8.05cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Right ectopic kidney.');
INSERT INTO "sonography_templates" VALUES(14,'Renal','Left ectopic kidney','LIVER: The liver is normal in size, shape and outline with a liver span of about 13.12cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: The left renal bed is empty; the left kidney is noted in the pelvic region. Both kidneys are normal in size, shape with smooth outline, normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.91 x 4.51 x 5.72cm with a corresponding volume of 133.71ml (right) and 9.56 x 5.55 x 6.04cm with a corresponding volume of 167.86ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

The Pancreas and Spleen (span- 8.05cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Left ectopic kidney.');
INSERT INTO "sonography_templates" VALUES(15,'Renal','Left renal hypoplasia with ectopia','LIVER: The liver is normal in size, shape and outline with a liver span of about 13.12cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: The right kidney is normal in size and shape with smooth outline, normal cortical echogenicity with good corticomedullary differentiation, central echogenic complexes normal, no demonstrable cysts, renal stones nor hydronephrosis. The left renal bed is empty; the left kidney is noted at the umbilical area and reduced in size.

The Pancreas and Spleen (span- 8.05cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Left renal hypoplasia with ectopia.');
INSERT INTO "sonography_templates" VALUES(16,'Renal','Left renal hypoplasia','LIVER: The liver is normal in size, shape and outline with a liver span of about 13.12cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: The right kidney is normal in size and shape with uniform outline, normal cortical echogenicity with good corticomedullary differentiation, measuring about 9.91 x 4.51 x 5.72cm with a corresponding volume of 133.71ml. Central echogenic complexes normal, no demonstrable cysts, renal stones nor hydronephrosis. The left kidney is markedly enlarged with extreme dilation of the pelvi-calyceal system and significant loss of renal parenchyma, evidenced by cortico-medullary thinning; it measures about 9.56 x 5.55 x 6.04cm with a corresponding volume of 167.86ml.

The Pancreas and Spleen (span- 8.05cm) are within normal limit.

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The pelvic organs are within normal limit for age.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Left renal hydronephrosis, Grade V, ?Cause.');
INSERT INTO "sonography_templates" VALUES(17,'Renal / Doppler','Renal artery Doppler — Normal','LIVER: The liver is normal in size, shape and outline with a liver span of about 18.34cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 10.92 x 4.64 x 6.56cm with a corresponding volume of 174.05ml (right) and 11.56 x 5.23 x 5.23cm with a corresponding volume of 180.99ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

RENAL ARTERY DOPPLER: No sonographic evidence of renal artery stenosis. Resistive indices are normal — right 0.67, left 0.69 (normal <0.70 bilaterally). Renal–aortic ratio values are normal — right 0.32, left 0.35 (normal range <3.52).

GIT: The visualized bowel loops show normal peristaltic activities, no free peritoneal fluid, no intra-abdominal lymphadenopathy or mass is visualised. No inflamed appendix or abscess is detected.

The Pancreas and Spleen (span- 10.72cm) are within normal limit.

The uterus is normal in size with a uniform outline, non-gravid, anteverted, with a uniform myometrial echopattern. It measures about 9.90 x 5.91 x 6.53cm with a corresponding volume of 200.16ml. The endometrial plate is intact and measures about 0.70cm. Both ovaries are normal in size and outline, containing few developing follicles. Both adnexa are free. No fluid in the pouch of Douglas.

The urinary bladder is well distended with urine and exhibits normal wall calibre thickness. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

IMPRESSION: Normal study.');
INSERT INTO "sonography_templates" VALUES(18,'GIT / Appendix','Colitis of caecum','GIT: The visualized small bowel loops show normal peristaltic activities. There is marked tenderness in the right iliac fossa; the large bowel in the right iliac fossa demonstrates increased mural thickening of about 13.3mm. No free peritoneal fluid, no intra-abdominal lymphadenopathy visualised. Appendix not visualized.

LIVER: The liver is normal in size, shape and outline with a liver span of about 15.10cm. Its parenchymal echotexture is preserved with no intrahepatic duct dilation, no mass, abscess or cyst is seen.

GALL BLADDER: The gallbladder is distended with clear bile, it is normal in outline and wall thickness. No gallstones, polyps or sludge are seen and the patient is sonographic Murphy’s negative.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline. Normal cortical echogenicity with good corticomedullary differentiation, measuring about 10.29 x 3.56 x 6.40cm with a corresponding volume of 122.84ml (right) and 10.04 x 5.01 x 5.54cm with a corresponding volume of 145.78ml (left). No demonstrable cysts, renal stones nor hydronephrosis.

The Pancreas and Spleen (span- 8.39cm) are within normal limit.

IMPRESSION: Colitis of caecum.');
INSERT INTO "sonography_templates" VALUES(19,'GIT / Appendix','Acute appendicitis','GIT: There is significant probe tenderness in the right iliac fossa. The appendix is visualized — aperistaltic, non-compressible, dilated, with distinct appendiceal wall layers and peri-appendiceal lymph nodes noted. It measures about 7.7mm in AP diameter.

LIVER: The liver is normal in size (span- 13.82cm), shape, outline and echogenicities. No liver mass, abscess or cyst is detected. Both intra- and extra-hepatic ducts are not dilated.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline and normal cortical echotexture, measuring about 9.24 x 4.22 x 5.79cm with a corresponding volume of 118.23ml (right) and 9.90 x 4.47 x 5.14cm with a corresponding volume of 119.09ml (left). The pelvi-calyceal systems are not dilated. No renal cyst, mass or calculus is seen.

GALL BLADDER: The gall bladder is well distended, normal in size and wall thickness. No gall stone or sludge is seen.

The Pancreas and Spleen (span- 9.35cm) are within normal limit.

A normal sized prostate gland is seen, marginated, well-defined with homogenous parenchymal echotexture and intact capsule. No calculi or focal lesion seen. It measures about 3.68 x 3.20 x 4.02cm with a corresponding volume of 24.74ml.

The urinary bladder is distended with clear urine, normal wall thickness. No urinary bladder mass, polyp or calculus is seen.

IMPRESSION: Acute appendicitis.
Urgent surgical review is advised.');
INSERT INTO "sonography_templates" VALUES(20,'GIT / Appendix','Appendiceal mass','GIT: There is significant probe tenderness in the right iliac fossa. The appendix is visualized — aperistaltic, non-compressible, dilated at its distal end, with distinct appendiceal wall layers, peri-appendiceal lymph nodes and significant peri-appendiceal fluid collection noted. It measures about 1.26cm in diameter.

LIVER: The liver is normal in size (span- 15.56cm), shape, outline and echogenicities. No liver mass, abscess or cyst is detected. Both intra- and extra-hepatic ducts are not dilated.

KIDNEYS: Both kidneys are normal in size, shape and position with a smooth outline and normal cortical echotexture, measuring about 8.87 x 4.16 x 6.43cm with a corresponding volume of 124.22ml (right) and 10.48 x 4.67 x 5.56cm with a corresponding volume of 142.60ml (left). The pelvi-calyceal systems are not dilated. No renal cyst, mass or calculus is seen.

GALL BLADDER: The gall bladder is well distended, normal in size and wall thickness. No gall stone or sludge is seen.

The Pancreas and Spleen (span- 8.7cm) are within normal limit.

URINARY BLADDER: The urinary bladder is moderately distended with urine. No mass, cystocoele, ureterocoele, calculus or polyp is seen.

IMPRESSION: Appendiceal mass, ?Ruptured.
Urgent surgical review is advised.');
CREATE TABLE staff (id INTEGER PRIMARY KEY, name TEXT NOT NULL, designation TEXT, gross_monthly NUMERIC,
  allowance_1 NUMERIC, allowance_2 NUMERIC, status TEXT DEFAULT 'Available', user_id INTEGER REFERENCES users(id));
INSERT INTO "staff" VALUES(1,'Chidi Okonkwo','Lab technician',180000,50000,30000,'Available',NULL);
INSERT INTO "staff" VALUES(2,'Ifeoma Nwachukwu','Phlebotomist',140000,40000,25000,'On leave',NULL);
INSERT INTO "staff" VALUES(3,'Tolu Adeyemi','Medical laboratory scientist',320000,90000,50000,'Available',NULL);
INSERT INTO "staff" VALUES(4,'Dr. Femi Adeyemi','Pathologist',950000,300000,120000,'Available',NULL);
INSERT INTO "staff" VALUES(5,'Halima Suleiman','Sonographer',380000,110000,60000,'Available',NULL);
INSERT INTO "staff" VALUES(6,'Funmilayo Adisa','Front desk',120000,35000,20000,'Available',NULL);
INSERT INTO "staff" VALUES(7,'Grace Umeh','Accountant',260000,70000,40000,'Available',NULL);
CREATE TABLE stock_items (id INTEGER PRIMARY KEY, name TEXT NOT NULL, department TEXT, batch_no TEXT, expiry_date TEXT,
  quantity INTEGER NOT NULL DEFAULT 0, reorder_level INTEGER NOT NULL DEFAULT 0, supplier TEXT);
INSERT INTO "stock_items" VALUES(1,'CBC reagent kit (Mindray BC-5000)','Haematology','B2410','2027-05-16',18,10,'Randox / Mindray distributor');
INSERT INTO "stock_items" VALUES(2,'Chemistry reagent: ALT/AST','Chemical Pathology','B2398','2027-01-11',6,8,'Randox');
INSERT INTO "stock_items" VALUES(3,'Maglumi TSH reagent kit','Immunology & Hormones','B2377','2027-03-27',3,4,'Snibe distributor');
INSERT INTO "stock_items" VALUES(4,'EDTA tubes (purple)','Haematology','B2501','2027-12-02',140,200,'Medical Supply Co.');
INSERT INTO "stock_items" VALUES(5,'Serum gel tubes','Chemical Pathology','B2502','2027-11-12',260,200,'Medical Supply Co.');
INSERT INTO "stock_items" VALUES(6,'Urine universal containers','Microbiology','B2433','2028-03-11',320,150,'Medical Supply Co.');
INSERT INTO "stock_items" VALUES(7,'HIV / HBsAg rapid kits','Serology','B2366','2026-12-27',12,15,'Abbott / local agent');
INSERT INTO "stock_items" VALUES(8,'Ultrasound gel, 5L','Ultrasound','B2288','2027-08-24',3,6,'Medical Supply Co.');
INSERT INTO "stock_items" VALUES(9,'X-ray film / CR plates','X-Ray','B2120','2028-01-21',22,15,'Fuji agent');
INSERT INTO "stock_items" VALUES(10,'Examination gloves (box)','Sample collection','B2509','2028-06-19',30,20,'Medical Supply Co.');
INSERT INTO "stock_items" VALUES(11,'Biohazard bags','Sample collection','B2510','2028-09-27',40,25,'Medical Supply Co.');
CREATE TABLE sub_departments (id INTEGER PRIMARY KEY, department_id INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  name TEXT NOT NULL, group_name TEXT);
INSERT INTO "sub_departments" VALUES(1,1,'Haematology','Blood tests');
INSERT INTO "sub_departments" VALUES(2,1,'Coagulation','Blood tests');
INSERT INTO "sub_departments" VALUES(3,2,'Clinical chemistry','Chemistry');
INSERT INTO "sub_departments" VALUES(4,2,'Electrolytes','Chemistry');
INSERT INTO "sub_departments" VALUES(5,2,'Diabetes','Chemistry');
INSERT INTO "sub_departments" VALUES(6,3,'Thyroid','Hormones');
INSERT INTO "sub_departments" VALUES(7,3,'Fertility & reproductive','Hormones');
INSERT INTO "sub_departments" VALUES(8,3,'Tumour markers','Hormones');
INSERT INTO "sub_departments" VALUES(9,4,'Infectious disease screen','Immunology');
INSERT INTO "sub_departments" VALUES(10,4,'Widal / VDRL','Immunology');
INSERT INTO "sub_departments" VALUES(11,5,'Bacteriology','Cultures');
INSERT INTO "sub_departments" VALUES(12,5,'Parasitology','Cultures');
INSERT INTO "sub_departments" VALUES(13,5,'Semen analysis','Cultures');
INSERT INTO "sub_departments" VALUES(14,6,'Histology','Pathology');
INSERT INTO "sub_departments" VALUES(15,6,'Cytology','Pathology');
INSERT INTO "sub_departments" VALUES(16,7,'Abdominal & pelvic','General');
INSERT INTO "sub_departments" VALUES(17,7,'Obstetric','Obstetrics');
INSERT INTO "sub_departments" VALUES(18,7,'Small parts','General');
INSERT INTO "sub_departments" VALUES(19,8,'Chest','Plain film');
INSERT INTO "sub_departments" VALUES(20,8,'Skeletal','Plain film');
INSERT INTO "sub_departments" VALUES(21,9,'ECG','Cardiac');
INSERT INTO "sub_departments" VALUES(22,9,'Echocardiography','Cardiac');
INSERT INTO "sub_departments" VALUES(23,10,'General OPD','Clinic');
INSERT INTO "sub_departments" VALUES(24,10,'Specialist clinic','Clinic');
INSERT INTO "sub_departments" VALUES(25,11,'Phlebotomy (walk-in)','Collection');
INSERT INTO "sub_departments" VALUES(26,11,'Home collection','Collection');
INSERT INTO "sub_departments" VALUES(27,12,'Wellness packages','Packages');
INSERT INTO "sub_departments" VALUES(28,12,'Pre-employment','Packages');
INSERT INTO "sub_departments" VALUES(29,13,'CT head','Neuro');
CREATE TABLE test_catalogue (code TEXT PRIMARY KEY, name TEXT NOT NULL, department TEXT, turnaround TEXT,
  price NUMERIC NOT NULL DEFAULT 0, home_collection INTEGER DEFAULT 0, disabled INTEGER DEFAULT 0);
INSERT INTO "test_catalogue" VALUES('CBC001','Complete blood count','Laboratory','3 hrs',4500,1,0);
INSERT INTO "test_catalogue" VALUES('LFT004','Liver function test','Laboratory','6 hrs',9200,1,0);
INSERT INTO "test_catalogue" VALUES('USG012','Abdominal ultrasound','Ultrasound','Same day',15000,0,0);
INSERT INTO "test_catalogue" VALUES('XRC003','Chest X-ray','X-Ray','1 hr',7500,0,0);
INSERT INTO "test_catalogue" VALUES('CTB007','CT brain, plain','CT Scan','2 hrs',55000,0,0);
CREATE TABLE test_parameters (id INTEGER PRIMARY KEY, test_name TEXT NOT NULL,
  instrument_id INTEGER REFERENCES instruments(id), analyte TEXT NOT NULL, unit TEXT, ref_low REAL, ref_high REAL);
INSERT INTO "test_parameters" VALUES(1,'Full blood count',1,'WBC','x10^9/L',4.0,11.0);
INSERT INTO "test_parameters" VALUES(2,'Full blood count',1,'HGB','g/dL',12.0,17.0);
INSERT INTO "test_parameters" VALUES(3,'Full blood count',1,'PLT','x10^9/L',150.0,400.0);
INSERT INTO "test_parameters" VALUES(4,'Fasting blood sugar',2,'GLU','mmol/L',3.9,5.6);
INSERT INTO "test_parameters" VALUES(5,'Liver function test',2,'ALT','U/L',7.0,56.0);
INSERT INTO "test_parameters" VALUES(6,'Liver function test',2,'AST','U/L',10.0,40.0);
INSERT INTO "test_parameters" VALUES(7,'Kidney function test',2,'CREA','umol/L',60.0,110.0);
INSERT INTO "test_parameters" VALUES(8,'Kidney function test',2,'UREA','mmol/L',2.5,7.8);
INSERT INTO "test_parameters" VALUES(9,'Lipid profile',2,'CHOL','mmol/L',0.0,5.2);
INSERT INTO "test_parameters" VALUES(10,'Lipid profile',2,'TG','mmol/L',0.0,1.7);
INSERT INTO "test_parameters" VALUES(11,'HIV screening',3,'HIV','S/CO',0.0,1.0);
INSERT INTO "test_parameters" VALUES(12,'Hepatitis B surface antigen',3,'HBSAG','S/CO',0.0,1.0);
CREATE TABLE users (
  id INTEGER PRIMARY KEY, name TEXT NOT NULL, username TEXT UNIQUE NOT NULL,
  role TEXT REFERENCES roles(name), branch_id INTEGER REFERENCES branches(id),
  status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Inactive','Suspended')),
  password_salt TEXT, password_hash TEXT, must_change_password INTEGER NOT NULL DEFAULT 1,
  last_login_at TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
INSERT INTO "users" VALUES(1,'Funmilayo Adisa','funmilayo.adisa','Front desk',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(2,'Chidi Okonkwo','chidi.okonkwo','Lab technician',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(3,'Grace Umeh','grace.umeh','Accountant',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(4,'Ifeoma Nwachukwu','ifeoma.nwachukwu','Phlebotomist',2,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(5,'Emeka Bassey','emeka.bassey','Lab manager',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(6,'Tolu Adeyemi','tolu.adeyemi','Medical laboratory scientist',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(7,'Bisi Fashola','bisi.fashola','Medical laboratory scientist',3,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(8,'Dr. Chinedu Obi','chinedu.obi','Medical laboratory scientist',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(9,'Dr. Femi Adeyemi','femi.adeyemi','Pathologist',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(10,'Ngozi Eze','ngozi.eze','Radiographer',2,'Suspended',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(11,'Halima Suleiman','halima.suleiman','Sonographer',3,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
INSERT INTO "users" VALUES(12,'Yusuf Bello','yusuf.bello','IT support',1,'Active',NULL,NULL,1,NULL,'2026-10-28 09:37:21');
CREATE INDEX ix_appt_uhid ON appointments(uhid, scheduled_at);
CREATE INDEX ix_inv_uhid ON invoices(uhid, invoice_date);
CREATE INDEX ix_items_inv ON invoice_items(invoice_id);
CREATE INDEX ix_pay_inv ON payments(invoice_id);
CREATE INDEX ix_samples_uhid ON samples(uhid);
CREATE INDEX ix_results_sample ON results(sample_id);
CREATE INDEX ix_stock_exp ON stock_items(expiry_date);
COMMIT;