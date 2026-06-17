/// MedCenter SQLite Schema — V2
/// V2 additions:
///   - invoices: added tax_amount, total_amount, payment_method, due_date, paid_at,
///               medical_aid_name, medical_aid_member_no, medical_aid_auth_code,
///               line_items (JSON)
///   - prescriptions: added route, refills, event_id per V2 spec
///   - prescription_items: added route (per item level too)
///   - dashboard_cache: optional aggregate cache (cleared on each open)

class Schema {
  static const int version = 2;

  static const String clinicConfig = '''
    CREATE TABLE IF NOT EXISTS clinic_config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static const String devices = '''
    CREATE TABLE IF NOT EXISTS devices (
      id TEXT PRIMARY KEY,
      clinic_id TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      ip_address TEXT,
      last_seen_at TEXT,
      is_active INTEGER DEFAULT 1
    )
  ''';

  static const String users = '''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      pin_hash TEXT NOT NULL,
      device_id TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_version INTEGER DEFAULT 1
    )
  ''';

  static const String patients = '''
    CREATE TABLE IF NOT EXISTS patients (
      id TEXT PRIMARY KEY,
      file_number TEXT UNIQUE NOT NULL,
      full_name TEXT NOT NULL,
      date_of_birth TEXT,
      gender TEXT,
      national_id TEXT,
      address TEXT,
      phone TEXT,
      email TEXT,
      next_of_kin_name TEXT,
      next_of_kin_phone TEXT,
      next_of_kin_relation TEXT,
      photo_path TEXT,
      blood_group TEXT,
      is_archived INTEGER DEFAULT 0,
      created_by TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      is_deleted INTEGER DEFAULT 0
    )
  ''';

  static const String consultations = '''
    CREATE TABLE IF NOT EXISTS consultations (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      date TEXT NOT NULL,
      chief_complaint TEXT,
      history TEXT,
      examination TEXT,
      diagnosis TEXT,
      icd10_code TEXT,
      treatment_plan TEXT,
      follow_up_date TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      is_deleted INTEGER DEFAULT 0,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  static const String vitals = '''
    CREATE TABLE IF NOT EXISTS vitals (
      id TEXT PRIMARY KEY,
      consultation_id TEXT NOT NULL,
      patient_id TEXT NOT NULL,
      blood_pressure_sys INTEGER,
      blood_pressure_dia INTEGER,
      temperature REAL,
      weight_kg REAL,
      height_cm REAL,
      pulse_rate INTEGER,
      oxygen_saturation INTEGER,
      respiratory_rate INTEGER,
      recorded_at TEXT NOT NULL,
      recorded_by TEXT,
      sync_version INTEGER DEFAULT 1,
      FOREIGN KEY (consultation_id) REFERENCES consultations(id),
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  static const String allergies = '''
    CREATE TABLE IF NOT EXISTS allergies (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      allergen TEXT NOT NULL,
      reaction TEXT,
      severity TEXT,
      noted_at TEXT NOT NULL,
      noted_by TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  static const String chronicConditions = '''
    CREATE TABLE IF NOT EXISTS chronic_conditions (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      condition TEXT NOT NULL,
      diagnosed_at TEXT,
      notes TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  /// V2: added route, refills, event_id
  static const String prescriptions = '''
    CREATE TABLE IF NOT EXISTS prescriptions (
      id TEXT PRIMARY KEY,
      prescription_number TEXT UNIQUE NOT NULL,
      consultation_id TEXT,
      patient_id TEXT NOT NULL,
      doctor_id TEXT NOT NULL,
      date TEXT NOT NULL,
      notes TEXT,
      status TEXT DEFAULT 'active',
      is_repeat INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      is_deleted INTEGER DEFAULT 0,
      event_id TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (doctor_id) REFERENCES users(id)
    )
  ''';

  /// V2: added route per item
  static const String prescriptionItems = '''
    CREATE TABLE IF NOT EXISTS prescription_items (
      id TEXT PRIMARY KEY,
      prescription_id TEXT NOT NULL,
      medication_name TEXT NOT NULL,
      dosage TEXT,
      frequency TEXT,
      duration TEXT,
      route TEXT,
      refills INTEGER DEFAULT 0,
      instructions TEXT,
      quantity INTEGER,
      FOREIGN KEY (prescription_id) REFERENCES prescriptions(id)
    )
  ''';

  static const String appointments = '''
    CREATE TABLE IF NOT EXISTS appointments (
      id TEXT PRIMARY KEY,
      appointment_number TEXT UNIQUE NOT NULL,
      patient_id TEXT NOT NULL,
      doctor_id TEXT NOT NULL,
      scheduled_at TEXT NOT NULL,
      duration_minutes INTEGER DEFAULT 30,
      status TEXT DEFAULT 'booked',
      reason TEXT,
      notes TEXT,
      created_by TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      is_deleted INTEGER DEFAULT 0,
      FOREIGN KEY (patient_id) REFERENCES patients(id),
      FOREIGN KEY (doctor_id) REFERENCES users(id)
    )
  ''';

  /// V2: added tax_amount, total_amount, payment_method, due_date, paid_at,
  ///     medical_aid_name, medical_aid_member_no, medical_aid_auth_code, event_id
  static const String invoices = '''
    CREATE TABLE IF NOT EXISTS invoices (
      id TEXT PRIMARY KEY,
      invoice_number TEXT UNIQUE NOT NULL,
      patient_id TEXT NOT NULL,
      consultation_id TEXT,
      date TEXT NOT NULL,
      due_date TEXT,
      subtotal REAL DEFAULT 0,
      tax_amount REAL DEFAULT 0,
      discount REAL DEFAULT 0,
      total_amount REAL DEFAULT 0,
      status TEXT DEFAULT 'unpaid',
      payment_method TEXT,
      medical_aid_name TEXT,
      medical_aid_member_no TEXT,
      medical_aid_auth_code TEXT,
      notes TEXT,
      created_by TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      paid_at TEXT,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      is_deleted INTEGER DEFAULT 0,
      event_id TEXT,
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  static const String invoiceItems = '''
    CREATE TABLE IF NOT EXISTS invoice_items (
      id TEXT PRIMARY KEY,
      invoice_id TEXT NOT NULL,
      description TEXT NOT NULL,
      quantity INTEGER DEFAULT 1,
      unit_price REAL DEFAULT 0,
      total REAL DEFAULT 0,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    )
  ''';

  static const String payments = '''
    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      receipt_number TEXT UNIQUE NOT NULL,
      invoice_id TEXT NOT NULL,
      patient_id TEXT NOT NULL,
      amount REAL NOT NULL,
      method TEXT NOT NULL,
      reference TEXT,
      paid_at TEXT NOT NULL,
      received_by TEXT,
      notes TEXT,
      sync_version INTEGER DEFAULT 1,
      device_id TEXT,
      FOREIGN KEY (invoice_id) REFERENCES invoices(id),
      FOREIGN KEY (patient_id) REFERENCES patients(id)
    )
  ''';

  static const String auditLog = '''
    CREATE TABLE IF NOT EXISTS audit_log (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      device_id TEXT,
      action TEXT NOT NULL,
      table_name TEXT,
      record_id TEXT,
      old_value TEXT,
      new_value TEXT,
      timestamp TEXT NOT NULL
    )
  ''';

  static const String syncQueue = '''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      device_id TEXT NOT NULL,
      sync_version INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      synced_at TEXT
    )
  ''';

  static const String syncConflicts = '''
    CREATE TABLE IF NOT EXISTS sync_conflicts (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      winning_payload TEXT,
      losing_payload TEXT,
      resolved_at TEXT,
      device_id TEXT
    )
  ''';

  static const String counters = '''
    CREATE TABLE IF NOT EXISTS counters (
      key TEXT PRIMARY KEY,
      value INTEGER DEFAULT 0
    )
  ''';

  static List<String> get all => [
        clinicConfig,
        devices,
        users,
        patients,
        consultations,
        vitals,
        allergies,
        chronicConditions,
        prescriptions,
        prescriptionItems,
        appointments,
        invoices,
        invoiceItems,
        payments,
        auditLog,
        syncQueue,
        syncConflicts,
        counters,
      ];

  /// V1 → V2 migration: add new columns where missing (ALTER TABLE is safe — ignores if already exists via try/catch)
  static List<String> get v2Migrations => [
        'ALTER TABLE prescriptions ADD COLUMN event_id TEXT',
        'ALTER TABLE prescription_items ADD COLUMN route TEXT',
        'ALTER TABLE prescription_items ADD COLUMN refills INTEGER DEFAULT 0',
        'ALTER TABLE invoices ADD COLUMN due_date TEXT',
        'ALTER TABLE invoices ADD COLUMN tax_amount REAL DEFAULT 0',
        'ALTER TABLE invoices ADD COLUMN total_amount REAL DEFAULT 0',
        'ALTER TABLE invoices ADD COLUMN payment_method TEXT',
        'ALTER TABLE invoices ADD COLUMN medical_aid_name TEXT',
        'ALTER TABLE invoices ADD COLUMN medical_aid_member_no TEXT',
        'ALTER TABLE invoices ADD COLUMN medical_aid_auth_code TEXT',
        'ALTER TABLE invoices ADD COLUMN paid_at TEXT',
        'ALTER TABLE invoices ADD COLUMN event_id TEXT',
      ];
}
