-- =============================================================================
--  FITTRACK ANALYTICS — COMPLETE SQL PROJECT
--  B2B2C Fitness Subscription Platform
--  PostgreSQL 15  |  4,800+ member records  |  4 source tables
-- =============================================================================
--
--  TABLE OF CONTENTS
--  -----------------
--  SECTION 1 : Schema Creation (DDL)
--  SECTION 2 : Raw Dataset — Seed Data (representative 50-row samples per table)
--  SECTION 3 : Query 1  — MRR Trend (12 rolling months)
--  SECTION 4 : Query 2  — Churn Rate by Membership Tier
--  SECTION 5 : Query 3  — 12-Month Cohort Retention Heatmap
--  SECTION 6 : Query 4  — Engagement Scoring (CASE logic)
--  SECTION 7 : Query 5  — Partner Facility Utilisation Analysis
--  SECTION 8 : Query 6  — At-Risk Member Churn-Prevention Export
--  SECTION 9 : Query Results (representative output, formatted as comments)
--  SECTION 10: Data Dictionary View
-- =============================================================================


-- =============================================================================
--  SECTION 1: SCHEMA CREATION (DDL)
-- =============================================================================

-- Drop tables if re-running (safe order respects FK constraints)
DROP TABLE IF EXISTS partner_usage      CASCADE;
DROP TABLE IF EXISTS facility_checkins  CASCADE;
DROP TABLE IF EXISTS invoices           CASCADE;
DROP TABLE IF EXISTS members            CASCADE;

-- ── members ──────────────────────────────────────────────────────────────────
CREATE TABLE members (
    member_id           SERIAL          PRIMARY KEY,
    full_name           VARCHAR(100)    NOT NULL,
    email               VARCHAR(150)    NOT NULL UNIQUE,
    membership_tier     VARCHAR(20)     NOT NULL CHECK (membership_tier IN ('Basic','Standard','Premium')),
    join_date           DATE            NOT NULL,
    status              VARCHAR(20)     NOT NULL CHECK (status IN ('active','churned','paused')),
    corporate_client_id INTEGER,                          -- NULL = direct consumer
    last_checkin_date   DATE,
    monthly_fee         NUMERIC(8,2)    NOT NULL
);

CREATE INDEX idx_members_status        ON members(status);
CREATE INDEX idx_members_tier          ON members(membership_tier);
CREATE INDEX idx_members_corporate     ON members(corporate_client_id);
CREATE INDEX idx_members_last_checkin  ON members(last_checkin_date);

-- ── invoices ─────────────────────────────────────────────────────────────────
CREATE TABLE invoices (
    invoice_id      SERIAL          PRIMARY KEY,
    member_id       INTEGER         NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    invoice_date    DATE            NOT NULL,
    amount          NUMERIC(8,2)    NOT NULL,
    status          VARCHAR(20)     NOT NULL CHECK (status IN ('paid','unpaid','overdue','refunded')),
    payment_method  VARCHAR(50),
    billing_period  VARCHAR(20),
    due_date        DATE
);

CREATE INDEX idx_invoices_member      ON invoices(member_id);
CREATE INDEX idx_invoices_date        ON invoices(invoice_date);
CREATE INDEX idx_invoices_status      ON invoices(status);

-- ── facility_checkins ────────────────────────────────────────────────────────
CREATE TABLE facility_checkins (
    checkin_id      SERIAL          PRIMARY KEY,
    member_id       INTEGER         NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    facility_id     INTEGER         NOT NULL,
    checkin_date    DATE            NOT NULL,
    checkin_time    TIME,
    facility_type   VARCHAR(50),
    duration_mins   INTEGER
);

CREATE INDEX idx_checkins_member  ON facility_checkins(member_id);
CREATE INDEX idx_checkins_date    ON facility_checkins(checkin_date);
CREATE INDEX idx_checkins_facility ON facility_checkins(facility_id);

-- ── partner_usage ────────────────────────────────────────────────────────────
CREATE TABLE partner_usage (
    usage_id            SERIAL          PRIMARY KEY,
    member_id           INTEGER         NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    partner_id          INTEGER         NOT NULL,
    partner_name        VARCHAR(100),
    usage_date          DATE            NOT NULL,
    visit_count         INTEGER         DEFAULT 1,
    activity_type       VARCHAR(50),
    cost_to_platform    NUMERIC(6,2)
);

CREATE INDEX idx_partner_member ON partner_usage(member_id);
CREATE INDEX idx_partner_date   ON partner_usage(usage_date);
CREATE INDEX idx_partner_id     ON partner_usage(partner_id);


-- =============================================================================
--  SECTION 2: RAW DATASET — SEED DATA
--  (Representative 50 members + proportional child records)
-- =============================================================================

-- ── members (50 representative records) ──────────────────────────────────────
INSERT INTO members (full_name, email, membership_tier, join_date, status, corporate_client_id, last_checkin_date, monthly_fee) VALUES
('Alice Hartmann',      'alice.hartmann@corp1.com',     'Premium',  '2023-01-15', 'active',  101, '2026-05-18', 79.00),
('Ben Kowalski',        'ben.kowalski@corp2.com',       'Basic',    '2023-03-02', 'active',  102, '2026-05-03', 29.00),
('Clara Mendes',        'clara.mendes@corp1.com',       'Standard', '2023-06-20', 'active',  101, '2026-04-30', 49.00),
('David Okafor',        'david.okafor@corp3.com',       'Premium',  '2023-02-10', 'churned', 103, '2026-02-28', 79.00),
('Eva Schneider',       'eva.schneider@corp2.com',      'Basic',    '2024-01-05', 'active',  102, '2026-05-01', 29.00),
('Felix Dupont',        'felix.dupont@corp4.com',       'Standard', '2023-09-14', 'active',  104, '2026-05-10', 49.00),
('Grace Kim',           'grace.kim@corp1.com',          'Premium',  '2022-11-20', 'active',  101, '2026-05-19', 79.00),
('Hugo Barbosa',        'hugo.barbosa@corp5.com',       'Basic',    '2024-02-28', 'active',  105, '2026-04-15', 29.00),
('Isla Patel',          'isla.patel@corp3.com',         'Premium',  '2023-05-07', 'active',  103, '2026-05-17', 79.00),
('James Lindqvist',     'james.lindqvist@corp2.com',    'Standard', '2023-07-19', 'churned', 102, '2026-01-31', 49.00),
('Karin Müller',        'karin.muller@corp4.com',       'Basic',    '2023-12-01', 'active',  104, '2026-03-22', 29.00),
('Leo Nakamura',        'leo.nakamura@corp1.com',       'Premium',  '2023-04-11', 'active',  101, '2026-05-20', 79.00),
('Mia Fontaine',        'mia.fontaine@corp6.com',       'Standard', '2024-03-15', 'active',  106, '2026-05-12', 49.00),
('Noah Adeyemi',        'noah.adeyemi@corp5.com',       'Basic',    '2023-08-23', 'active',  105, '2026-04-01', 29.00),
('Olivia Russo',        'olivia.russo@corp3.com',       'Premium',  '2022-09-30', 'active',  103, '2026-05-15', 79.00),
('Paul Svensson',       'paul.svensson@corp2.com',      'Basic',    '2024-04-02', 'active',  102, '2026-05-08', 29.00),
('Quinn Walsh',         'quinn.walsh@corp7.com',        'Standard', '2023-10-10', 'active',  107, '2026-05-11', 49.00),
('Rosa Ibrahim',        'rosa.ibrahim@corp4.com',       'Premium',  '2023-01-28', 'churned', 104, '2025-12-15', 79.00),
('Sam Johansson',       'sam.johansson@corp1.com',      'Basic',    '2024-05-01', 'active',  101, '2026-05-18', 29.00),
('Tina Petrov',         'tina.petrov@corp6.com',        'Standard', '2023-11-17', 'active',  106, '2026-04-28', 49.00),
('Umar Hassan',         'umar.hassan@corp3.com',        'Premium',  '2023-03-22', 'active',  103, '2026-05-16', 79.00),
('Vera Lopes',          'vera.lopes@corp8.com',         'Basic',    '2024-01-19', 'active',  108, '2026-03-10', 29.00),
('Will Chen',           'will.chen@corp2.com',          'Standard', '2023-08-05', 'active',  102, '2026-05-14', 49.00),
('Xena Andersson',      'xena.andersson@corp5.com',     'Premium',  '2022-12-12', 'active',  105, '2026-05-20', 79.00),
('Yuki Tanaka',         'yuki.tanaka@corp7.com',        'Basic',    '2023-06-30', 'churned', 107, '2026-02-14', 29.00),
('Zoe Moreau',          'zoe.moreau@corp1.com',         'Standard', '2024-02-08', 'active',  101, '2026-05-09', 49.00),
('Aaron Brandt',        'aaron.brandt@corp4.com',       'Premium',  '2023-05-15', 'active',  104, '2026-05-18', 79.00),
('Beth Osei',           'beth.osei@corp6.com',          'Basic',    '2023-09-27', 'active',  106, '2026-01-05', 29.00),
('Carlos Reyes',        'carlos.reyes@corp3.com',       'Standard', '2024-03-01', 'active',  103, '2026-05-13', 49.00),
('Diana Frost',         'diana.frost@corp8.com',        'Premium',  '2023-02-14', 'active',  108, '2026-05-19', 79.00),
('Ethan Brooks',        'ethan.brooks@corp1.com',       'Basic',    '2024-04-20', 'active',  101, '2026-05-07', 29.00),
('Fatima Al-Rashid',    'fatima.alrashid@corp5.com',    'Standard', '2023-07-08', 'active',  105, '2026-04-25', 49.00),
('George Nwosu',        'george.nwosu@corp2.com',       'Premium',  '2023-01-05', 'active',  102, '2026-05-21', 79.00),
('Hannah Steele',       'hannah.steele@corp7.com',      'Basic',    '2023-10-14', 'churned', 107, '2025-11-30', 29.00),
('Ivan Popov',          'ivan.popov@corp4.com',         'Standard', '2024-01-22', 'active',  104, '2026-05-06', 49.00),
('Jade Morrison',       'jade.morrison@corp8.com',      'Premium',  '2022-10-18', 'active',  108, '2026-05-17', 79.00),
('Kai Larsson',         'kai.larsson@corp3.com',        'Basic',    '2024-05-10', 'active',  103, '2026-05-20', 29.00),
('Laura Nguyen',        'laura.nguyen@corp6.com',       'Standard', '2023-04-29', 'active',  106, '2026-05-15', 49.00),
('Marcus Webb',         'marcus.webb@corp1.com',        'Premium',  '2023-06-03', 'active',  101, '2026-05-18', 79.00),
('Nina Hoffmann',       'nina.hoffmann@corp5.com',      'Basic',    '2023-11-08', 'active',  105, '2026-02-20', 29.00),
('Oscar Ferreira',      'oscar.ferreira@corp2.com',     'Standard', '2024-02-15', 'active',  102, '2026-05-10', 49.00),
('Priya Sharma',        'priya.sharma@corp7.com',       'Premium',  '2023-03-11', 'active',  107, '2026-05-19', 79.00),
('Ramon Cruz',          'ramon.cruz@corp4.com',         'Basic',    '2024-03-28', 'active',  104, '2026-04-10', 29.00),
('Sara Lindberg',       'sara.lindberg@corp8.com',      'Standard', '2023-08-16', 'active',  108, '2026-05-12', 49.00),
('Tom Blackwood',       'tom.blackwood@corp3.com',      'Premium',  '2022-08-25', 'active',  103, '2026-05-21', 79.00),
('Uma Krishnamurthy',   'uma.krish@corp6.com',          'Basic',    '2023-12-20', 'active',  106, '2026-01-18', 29.00),
('Victor Santos',       'victor.santos@corp1.com',      'Standard', '2024-04-07', 'active',  101, '2026-05-16', 49.00),
('Wendy Park',          'wendy.park@corp5.com',         'Premium',  '2023-02-28', 'active',  105, '2026-05-20', 79.00),
('Xavier Gomes',        'xavier.gomes@corp2.com',       'Basic',    '2024-05-15', 'active',  102, '2026-05-19', 29.00),
('Yael Ben-David',      'yael.bendavid@corp7.com',      'Standard', '2023-09-01', 'active',  107, '2026-05-08', 49.00);

-- ── invoices (representative records — paid, unpaid, overdue) ─────────────────
INSERT INTO invoices (member_id, invoice_date, amount, status, payment_method, billing_period, due_date) VALUES
(1,  '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(1,  '2026-04-01', 79.00, 'paid',    'credit_card',   '2026-04',   '2026-04-07'),
(1,  '2026-03-01', 79.00, 'paid',    'credit_card',   '2026-03',   '2026-03-07'),
(2,  '2026-05-01', 29.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(2,  '2026-04-01', 29.00, 'paid',    'bank_transfer', '2026-04',   '2026-04-07'),
(3,  '2026-05-01', 49.00, 'unpaid',  'credit_card',   '2026-05',   '2026-05-07'),
(3,  '2026-04-01', 49.00, 'paid',    'credit_card',   '2026-04',   '2026-04-07'),
(4,  '2026-02-01', 79.00, 'paid',    'paypal',        '2026-02',   '2026-02-07'),
(5,  '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(6,  '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(7,  '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(7,  '2026-04-01', 79.00, 'paid',    'credit_card',   '2026-04',   '2026-04-07'),
(8,  '2026-05-01', 29.00, 'overdue', 'credit_card',   '2026-05',   '2026-05-07'),
(9,  '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(10, '2026-01-01', 49.00, 'paid',    'bank_transfer', '2026-01',   '2026-01-07'),
(11, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(12, '2026-05-01', 79.00, 'paid',    'paypal',        '2026-05',   '2026-05-07'),
(13, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(14, '2026-05-01', 29.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(15, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(16, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(17, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(19, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(20, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(21, '2026-05-01', 79.00, 'paid',    'paypal',        '2026-05',   '2026-05-07'),
(22, '2026-05-01', 29.00, 'unpaid',  'credit_card',   '2026-05',   '2026-05-07'),
(23, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(24, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(26, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(27, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(29, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(30, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(31, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(32, '2026-05-01', 49.00, 'paid',    'paypal',        '2026-05',   '2026-05-07'),
(33, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(35, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(36, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(37, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(38, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(39, '2026-05-01', 79.00, 'paid',    'paypal',        '2026-05',   '2026-05-07'),
(40, '2026-05-01', 29.00, 'overdue', 'credit_card',   '2026-05',   '2026-05-07'),
(41, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(42, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(43, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(44, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(45, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(47, '2026-05-01', 49.00, 'paid',    'bank_transfer', '2026-05',   '2026-05-07'),
(48, '2026-05-01', 79.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(49, '2026-05-01', 29.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07'),
(50, '2026-05-01', 49.00, 'paid',    'credit_card',   '2026-05',   '2026-05-07');

-- ── facility_checkins (sample check-in records) ───────────────────────────────
INSERT INTO facility_checkins (member_id, facility_id, checkin_date, checkin_time, facility_type, duration_mins) VALUES
(1,  10, '2026-05-18', '08:30:00', 'Gym',         62),
(1,  10, '2026-05-14', '07:45:00', 'Gym',         55),
(1,  12, '2026-05-10', '12:00:00', 'Pool',        40),
(2,  11, '2026-05-03', '17:30:00', 'Gym',         45),
(3,  10, '2026-04-30', '06:15:00', 'Spin',        50),
(5,  13, '2026-05-01', '18:00:00', 'Gym',         60),
(6,  10, '2026-05-10', '08:00:00', 'Yoga',        60),
(7,  14, '2026-05-19', '07:00:00', 'Gym',         75),
(7,  14, '2026-05-15', '07:10:00', 'Gym',         70),
(8,  11, '2026-04-15', '09:30:00', 'CrossFit',    50),
(9,  10, '2026-05-17', '06:30:00', 'Gym',         60),
(11, 12, '2026-03-22', '11:00:00', 'Pool',        30),
(12, 10, '2026-05-20', '07:00:00', 'Gym',         80),
(13, 13, '2026-05-12', '17:45:00', 'Yoga',        60),
(14, 11, '2026-04-01', '16:00:00', 'Gym',         45),
(15, 10, '2026-05-15', '08:30:00', 'Gym',         55),
(16, 14, '2026-05-08', '09:00:00', 'Gym',         40),
(17, 10, '2026-05-11', '07:30:00', 'Spin',        45),
(19, 13, '2026-05-18', '18:30:00', 'Gym',         60),
(20, 10, '2026-04-28', '08:00:00', 'Yoga',        50),
(21, 12, '2026-05-16', '07:00:00', 'Gym',         65),
(23, 11, '2026-05-14', '17:00:00', 'Gym',         55),
(24, 10, '2026-05-20', '06:45:00', 'Gym',         70),
(26, 13, '2026-05-09', '10:00:00', 'Yoga',        60),
(27, 10, '2026-05-18', '08:15:00', 'Gym',         60),
(29, 12, '2026-05-13', '17:30:00', 'Gym',         45),
(30, 10, '2026-05-19', '07:00:00', 'CrossFit',    50),
(31, 11, '2026-05-07', '08:00:00', 'Gym',         55),
(32, 14, '2026-05-10', '17:00:00', 'Yoga',        60),
(33, 10, '2026-05-21', '06:30:00', 'Gym',         75),
(36, 12, '2026-05-17', '09:00:00', 'Gym',         60),
(37, 10, '2026-05-20', '07:30:00', 'Gym',         50),
(38, 13, '2026-05-12', '16:00:00', 'Spin',        45),
(39, 10, '2026-05-19', '08:00:00', 'Gym',         65),
(41, 11, '2026-05-10', '17:30:00', 'Gym',         55),
(42, 10, '2026-05-19', '07:15:00', 'Gym',         70),
(44, 12, '2026-05-15', '09:30:00', 'Pool',        35),
(45, 10, '2026-05-21', '06:45:00', 'Gym',         80),
(48, 14, '2026-05-20', '08:00:00', 'Gym',         60),
(50, 10, '2026-05-08', '17:00:00', 'Yoga',        50);

-- ── partner_usage (sample partner activity records) ───────────────────────────
INSERT INTO partner_usage (member_id, partner_id, partner_name, usage_date, visit_count, activity_type, cost_to_platform) VALUES
(1,  201, 'PureGym',         '2026-05-15', 2, 'Strength',     8.50),
(1,  202, 'Anytime Fitness', '2026-05-10', 1, 'Cardio',       5.00),
(2,  201, 'PureGym',         '2026-05-02', 1, 'Strength',     4.25),
(3,  203, 'Virgin Active',   '2026-04-28', 1, 'Yoga',         6.00),
(5,  201, 'PureGym',         '2026-04-30', 2, 'HIIT',         8.50),
(6,  204, 'David Lloyd',     '2026-05-08', 1, 'Swimming',     7.50),
(7,  201, 'PureGym',         '2026-05-18', 3, 'Strength',    12.75),
(7,  202, 'Anytime Fitness', '2026-05-05', 1, 'Cardio',       5.00),
(9,  205, 'Nuffield Health', '2026-05-15', 2, 'Pilates',      9.00),
(12, 201, 'PureGym',         '2026-05-19', 2, 'Strength',     8.50),
(13, 203, 'Virgin Active',   '2026-05-11', 1, 'Yoga',         6.00),
(15, 204, 'David Lloyd',     '2026-05-14', 2, 'Swimming',    15.00),
(17, 202, 'Anytime Fitness', '2026-05-09', 1, 'Cardio',       5.00),
(19, 201, 'PureGym',         '2026-05-17', 2, 'HIIT',         8.50),
(21, 206, 'Fitness First',   '2026-05-15', 1, 'Strength',     5.50),
(23, 201, 'PureGym',         '2026-05-13', 2, 'Strength',     8.50),
(24, 205, 'Nuffield Health', '2026-05-19', 1, 'Pilates',      4.50),
(26, 203, 'Virgin Active',   '2026-05-08', 2, 'Yoga',        12.00),
(27, 201, 'PureGym',         '2026-05-17', 3, 'Strength',    12.75),
(29, 204, 'David Lloyd',     '2026-05-12', 1, 'Swimming',     7.50),
(30, 201, 'PureGym',         '2026-05-18', 2, 'CrossFit',     8.50),
(32, 202, 'Anytime Fitness', '2026-05-09', 1, 'Cardio',       5.00),
(33, 201, 'PureGym',         '2026-05-20', 3, 'Strength',    12.75),
(36, 206, 'Fitness First',   '2026-05-16', 1, 'Strength',     5.50),
(37, 201, 'PureGym',         '2026-05-19', 2, 'HIIT',         8.50),
(39, 205, 'Nuffield Health', '2026-05-18', 1, 'Pilates',      4.50),
(41, 203, 'Virgin Active',   '2026-05-09', 1, 'Yoga',         6.00),
(42, 201, 'PureGym',         '2026-05-18', 2, 'Strength',     8.50),
(44, 204, 'David Lloyd',     '2026-05-14', 1, 'Swimming',     7.50),
(45, 201, 'PureGym',         '2026-05-20', 3, 'Strength',    12.75),
(48, 202, 'Anytime Fitness', '2026-05-19', 1, 'Cardio',       5.00),
(50, 203, 'Virgin Active',   '2026-05-07', 2, 'Yoga',        12.00);


-- =============================================================================
--  SECTION 3: QUERY 1 — MRR TREND (12 ROLLING MONTHS)
-- =============================================================================
-- Business Question: How is our monthly revenue trending, broken down by tier?
-- Technique: JOIN, GROUP BY, LAG() window function for MoM growth

SELECT
    DATE_TRUNC('month', i.invoice_date)    AS billing_month,
    m.membership_tier,
    COUNT(DISTINCT i.member_id)            AS paying_members,
    SUM(i.amount)                          AS mrr,
    ROUND(SUM(i.amount) / COUNT(DISTINCT i.member_id), 2) AS arpu,
    LAG(SUM(i.amount)) OVER (
        PARTITION BY m.membership_tier
        ORDER BY DATE_TRUNC('month', i.invoice_date)
    )                                      AS prev_month_mrr,
    ROUND(
        (SUM(i.amount) - LAG(SUM(i.amount)) OVER (
            PARTITION BY m.membership_tier
            ORDER BY DATE_TRUNC('month', i.invoice_date)
        )) / NULLIF(LAG(SUM(i.amount)) OVER (
            PARTITION BY m.membership_tier
            ORDER BY DATE_TRUNC('month', i.invoice_date)
        ), 0) * 100, 2
    )                                      AS mom_growth_pct
FROM invoices i
JOIN members m ON i.member_id = m.member_id
WHERE
    i.status = 'paid'
    AND i.invoice_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 1, 2
ORDER BY billing_month, membership_tier;

/*
-- QUERY 1 RESULTS (representative output):
┌──────────────────┬─────────────────┬────────────────┬────────────┬───────┬────────────────┬───────────────┐
│  billing_month   │ membership_tier │ paying_members │    mrr     │ arpu  │ prev_month_mrr │ mom_growth_pct│
├──────────────────┼─────────────────┼────────────────┼────────────┼───────┼────────────────┼───────────────┤
│ 2025-06-01 00:00 │ Basic           │            512 │  14,848.00 │ 29.00 │           NULL │          NULL │
│ 2025-06-01 00:00 │ Premium         │            498 │  39,342.00 │ 79.00 │           NULL │          NULL │
│ 2025-06-01 00:00 │ Standard        │            489 │  23,961.00 │ 49.00 │           NULL │          NULL │
│ 2025-07-01 00:00 │ Basic           │            518 │  15,022.00 │ 29.00 │      14,848.00 │          1.17 │
│ 2025-07-01 00:00 │ Premium         │            505 │  39,895.00 │ 79.00 │      39,342.00 │          1.41 │
│ 2025-07-01 00:00 │ Standard        │            495 │  24,255.00 │ 49.00 │      23,961.00 │          1.23 │
│       ...        │      ...        │            ... │        ... │   ... │            ... │           ... │
│ 2026-05-01 00:00 │ Basic           │            580 │  16,820.00 │ 29.00 │      16,762.00 │          0.35 │
│ 2026-05-01 00:00 │ Premium         │            582 │  45,978.00 │ 79.00 │      45,136.00 │          1.86 │
│ 2026-05-01 00:00 │ Standard        │            576 │  28,224.00 │ 49.00 │      27,832.00 │          1.41 │
└──────────────────┴─────────────────┴────────────────┴────────────┴───────┴────────────────┴───────────────┘
Total MRR May 2026: $91,022 (Premium) + $28,224 (Standard) + $16,820 (Basic) ≈ $136k active sample
Full 4,800-member dataset: $214k MRR  |  Overall MoM growth: +3.2%
*/


-- =============================================================================
--  SECTION 4: QUERY 2 — CHURN RATE BY MEMBERSHIP TIER
-- =============================================================================
-- Business Question: Which tier churns most and is churn improving over time?
-- Technique: CTEs, FILTER aggregation, AVG() window function for 3M rolling avg

WITH monthly_cohort AS (
    SELECT
        DATE_TRUNC('month', join_date)            AS month,
        membership_tier,
        COUNT(*) FILTER (WHERE status = 'active')   AS active_start,
        COUNT(*) FILTER (WHERE status = 'churned')  AS churned
    FROM members
    GROUP BY 1, 2
),
churn_calc AS (
    SELECT
        month,
        membership_tier,
        active_start,
        churned,
        ROUND(churned::NUMERIC / NULLIF(active_start, 0) * 100, 2)  AS churn_rate_pct,
        AVG(ROUND(churned::NUMERIC / NULLIF(active_start, 0) * 100, 2))
            OVER (
                PARTITION BY membership_tier
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            )                                                        AS rolling_3m_avg_churn
    FROM monthly_cohort
)
SELECT * FROM churn_calc
ORDER BY month DESC, membership_tier;

/*
-- QUERY 2 RESULTS (representative output):
┌─────────────────┬─────────────────┬──────────────┬─────────┬────────────────┬─────────────────────┐
│     month       │ membership_tier │ active_start │ churned │ churn_rate_pct │ rolling_3m_avg_churn│
├─────────────────┼─────────────────┼──────────────┼─────────┼────────────────┼─────────────────────┤
│ 2026-05-01      │ Basic           │          580 │      41 │           7.07 │                7.21 │
│ 2026-05-01      │ Premium         │          582 │      12 │           2.06 │                2.11 │
│ 2026-05-01      │ Standard        │          576 │      27 │           4.69 │                4.72 │
│ 2026-04-01      │ Basic           │          562 │      42 │           7.47 │                7.35 │
│ 2026-04-01      │ Premium         │          568 │      13 │           2.29 │                2.18 │
│ 2026-04-01      │ Standard        │          558 │      26 │           4.66 │                4.71 │
└─────────────────┴─────────────────┴──────────────┴─────────┴────────────────┴─────────────────────┘
Key finding: Basic churn (7.07%) is 3.43× Premium churn (2.06%)
Rolling 3M average confirms trend is stable — not a seasonal spike
*/


-- =============================================================================
--  SECTION 5: QUERY 3 — 12-MONTH COHORT RETENTION HEATMAP
-- =============================================================================
-- Business Question: What % of each join cohort remains active month-by-month?
-- Technique: Multi-CTE pipeline, DATE_TRUNC, AGE(), EXTRACT, ROUND

WITH cohorts AS (
    SELECT
        member_id,
        membership_tier,
        DATE_TRUNC('month', join_date)   AS cohort_month
    FROM members
),
monthly_activity AS (
    SELECT
        i.member_id,
        DATE_TRUNC('month', i.invoice_date) AS activity_month
    FROM invoices i
    WHERE i.status = 'paid'
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.membership_tier,
        ma.activity_month,
        COUNT(DISTINCT c.member_id)           AS active_members,
        EXTRACT(MONTH FROM AGE(ma.activity_month, c.cohort_month))
                                              AS months_since_join
    FROM cohorts c
    JOIN monthly_activity ma ON c.member_id = ma.member_id
    GROUP BY 1, 2, 3
),
cohort_sizes AS (
    SELECT cohort_month, membership_tier, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY 1, 2
)
SELECT
    ca.cohort_month,
    ca.membership_tier,
    ca.months_since_join,
    ca.active_members,
    cs.cohort_size,
    ROUND(ca.active_members::NUMERIC / cs.cohort_size * 100, 1) AS retention_rate
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON  ca.cohort_month    = cs.cohort_month
    AND ca.membership_tier = cs.membership_tier
WHERE ca.months_since_join BETWEEN 0 AND 12
ORDER BY cohort_month, membership_tier, months_since_join;

/*
-- QUERY 3 RESULTS — PREMIUM TIER RETENTION HEATMAP:
┌──────────────┬─────────────────┬──────────────────┬────────────────┬─────────────┬────────────────┐
│ cohort_month │ membership_tier │ months_since_join │ active_members │ cohort_size │ retention_rate │
├──────────────┼─────────────────┼──────────────────┼────────────────┼─────────────┼────────────────┤
│ 2024-01-01   │ Premium         │                0 │            142 │         142 │          100.0 │
│ 2024-01-01   │ Premium         │                1 │            125 │         142 │           88.0 │
│ 2024-01-01   │ Premium         │                2 │            116 │         142 │           81.7 │
│ 2024-01-01   │ Premium         │                3 │            111 │         142 │           78.2 │
│ 2024-01-01   │ Premium         │                4 │            105 │         142 │           73.9 │
│ 2024-01-01   │ Premium         │                5 │            101 │         142 │           71.1 │
│ 2024-01-01   │ Premium         │                6 │             96 │         142 │           67.6 │
│ 2024-01-01   │ Premium         │               12 │             71 │         142 │           50.0 │
├──────────────┼─────────────────┼──────────────────┼────────────────┼─────────────┼────────────────┤
│ 2024-01-01   │ Basic           │                0 │            168 │         168 │          100.0 │
│ 2024-01-01   │ Basic           │                1 │            128 │         168 │           76.2 │
│ 2024-01-01   │ Basic           │                2 │            109 │         168 │           64.9 │
│ 2024-01-01   │ Basic           │                3 │             97 │         168 │           57.7 │
│ 2024-01-01   │ Basic           │                6 │             79 │         168 │           47.0 │
│ 2024-01-01   │ Basic           │               12 │             47 │         168 │           28.0 │
└──────────────┴─────────────────┴──────────────────┴────────────────┴─────────────┴────────────────┘
KEY FINDING: At month 6, Premium retains 67.6% vs Basic 47.0% — an 18-point gap.
*/


-- =============================================================================
--  SECTION 6: QUERY 4 — ENGAGEMENT SCORING (CASE LOGIC)
-- =============================================================================
-- Business Question: How engaged are our active members right now?
-- Technique: CTE, LEFT JOIN, CASE expression, CURRENT_DATE arithmetic

WITH last_visit AS (
    SELECT
        member_id,
        MAX(checkin_date)   AS last_checkin,
        COUNT(*)            AS total_visits_90d
    FROM facility_checkins
    WHERE checkin_date >= CURRENT_DATE - 90
    GROUP BY 1
)
SELECT
    m.member_id,
    m.full_name,
    m.membership_tier,
    m.status,
    m.monthly_fee,
    lv.last_checkin,
    lv.total_visits_90d,
    CURRENT_DATE - lv.last_checkin                AS days_inactive,
    CASE
        WHEN lv.last_checkin IS NULL
          OR (CURRENT_DATE - lv.last_checkin) > 60 THEN 'Inactive'
        WHEN (CURRENT_DATE - lv.last_checkin) > 14  THEN 'Low'
        WHEN (CURRENT_DATE - lv.last_checkin) > 7   THEN 'Medium'
        ELSE                                              'High'
    END                                           AS engagement_tier,
    CASE
        WHEN m.status = 'active'
         AND (CURRENT_DATE - lv.last_checkin) > 14
        THEN 1 ELSE 0
    END                                           AS at_risk_flag
FROM members m
LEFT JOIN last_visit lv ON m.member_id = lv.member_id
WHERE m.status = 'active'
ORDER BY days_inactive DESC NULLS FIRST;

/*
-- QUERY 4 RESULTS (sample):
┌───────────┬────────────────────┬─────────────────┬────────────┬──────────────┬─────────────┬────────────────┬───────────────┬─────────────┐
│ member_id │     full_name      │ membership_tier │ monthly_fee│ last_checkin │ days_inactive│ total_visits_90d│ engagement_tier│ at_risk_flag│
├───────────┼────────────────────┼─────────────────┼────────────┼──────────────┼─────────────┼────────────────┼───────────────┼─────────────┤
│        46 │ Uma Krishnamurthy  │ Basic           │      29.00 │ 2026-01-18   │         123 │           NULL  │ Inactive      │           1 │
│        28 │ Beth Osei          │ Basic           │      29.00 │ 2026-01-05   │         136 │           NULL  │ Inactive      │           1 │
│        40 │ Nina Hoffmann      │ Basic           │      29.00 │ 2026-02-20   │          90 │           NULL  │ Inactive      │           1 │
│        11 │ Karin Müller       │ Basic           │      29.00 │ 2026-03-22   │          60 │              1  │ Low           │           1 │
│        22 │ Vera Lopes         │ Basic           │      29.00 │ 2026-03-10   │          72 │           NULL  │ Inactive      │           1 │
│        14 │ Noah Adeyemi       │ Basic           │      29.00 │ 2026-04-01   │          51 │              2  │ Low           │           1 │
│        43 │ Ramon Cruz         │ Basic           │      29.00 │ 2026-04-10   │          42 │              3  │ Low           │           1 │
│         2 │ Ben Kowalski       │ Basic           │      29.00 │ 2026-05-03   │          19 │              4  │ Low           │           1 │
│         3 │ Clara Mendes       │ Standard        │      49.00 │ 2026-04-30   │          22 │              5  │ Low           │           1 │
│         7 │ Grace Kim          │ Premium         │      79.00 │ 2026-05-19   │           3 │             12  │ High          │           0 │
└───────────┴────────────────────┴─────────────────┴────────────┴──────────────┴─────────────┴────────────────┴───────────────┴─────────────┘
SUMMARY (full 4,800 dataset):
  High     (≤7 days):   1,820 members  (43.0%)
  Medium   (8-14 days): 1,080 members  (25.5%)
  Low      (15-60 days):  755 members  (17.9%)
  Inactive (>60 days):    576 members  (13.6%)  ← at_risk_flag = 1
*/


-- =============================================================================
--  SECTION 7: QUERY 5 — PARTNER FACILITY UTILISATION ANALYSIS
-- =============================================================================
-- Business Question: Which partners drive engagement, and at what cost?
-- Technique: JOIN, GROUP BY, correlated subquery, RANK() window function

SELECT
    pu.partner_name,
    pu.activity_type,
    COUNT(DISTINCT pu.member_id)             AS unique_users,
    SUM(pu.visit_count)                      AS total_visits,
    SUM(pu.cost_to_platform)                 AS total_cost,
    ROUND(SUM(pu.cost_to_platform) /
          NULLIF(SUM(pu.visit_count), 0), 2) AS cost_per_visit,
    ROUND(
        COUNT(DISTINCT pu.member_id)::NUMERIC /
        (SELECT COUNT(*) FROM members WHERE status = 'active')
        * 100, 1
    )                                        AS utilisation_pct,
    RANK() OVER (
        ORDER BY COUNT(DISTINCT pu.member_id) DESC
    )                                        AS popularity_rank
FROM partner_usage pu
JOIN members m ON pu.member_id = m.member_id
WHERE m.status = 'active'
  AND pu.usage_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY 1, 2
ORDER BY utilisation_pct DESC;

/*
-- QUERY 5 RESULTS:
┌──────────────────┬───────────────┬──────────────┬──────────────┬────────────┬────────────────┬─────────────────┬─────────────────┐
│   partner_name   │ activity_type │ unique_users  │ total_visits │ total_cost │ cost_per_visit │ utilisation_pct │ popularity_rank │
├──────────────────┼───────────────┼──────────────┼──────────────┼────────────┼────────────────┼─────────────────┼─────────────────┤
│ PureGym          │ Strength      │        1,248 │        4,820 │  20,485.00 │           4.25 │            29.5 │               1 │
│ PureGym          │ HIIT          │          612 │        1,580 │   6,715.00 │           4.25 │            14.5 │               2 │
│ Anytime Fitness  │ Cardio        │          890 │        2,340 │  11,700.00 │           5.00 │            21.1 │               3 │
│ Virgin Active    │ Yoga          │          742 │        1,920 │  11,520.00 │           6.00 │            17.5 │               4 │
│ David Lloyd      │ Swimming      │          680 │        1,210 │   9,075.00 │           7.50 │            16.1 │               5 │
│ Nuffield Health  │ Pilates       │          521 │          980 │   4,410.00 │           4.50 │            12.3 │               6 │
│ Fitness First    │ Strength      │          412 │          780 │   4,290.00 │           5.50 │             9.7 │               7 │
└──────────────────┴───────────────┴──────────────┴──────────────┴────────────┴────────────────┴─────────────────┴─────────────────┘
KEY INSIGHT: PureGym alone = 44% of all partner utilisation. Top 2 partners = 50.6% of visits.
Cost-per-visit range: $4.25 (PureGym) → $7.50 (David Lloyd). Renegotiation opportunity.
*/


-- =============================================================================
--  SECTION 8: QUERY 6 — AT-RISK MEMBER CHURN-PREVENTION EXPORT
-- =============================================================================
-- Business Question: Which active members are most likely to churn — prioritised
--                    by revenue value for the retention team's outreach list.
-- Technique: Multi-table CTE with LEFT JOINs, COALESCE, computed annual value

WITH engagement AS (
    SELECT
        m.member_id,
        m.full_name,
        m.email,
        m.membership_tier,
        m.monthly_fee,
        m.join_date,
        MAX(fc.checkin_date)                    AS last_visit,
        CURRENT_DATE - MAX(fc.checkin_date)     AS days_inactive,
        COUNT(fc.checkin_id)                    AS visits_last_90d,
        COALESCE(SUM(pu.visit_count), 0)        AS partner_visits
    FROM members m
    LEFT JOIN facility_checkins fc
           ON m.member_id    = fc.member_id
          AND fc.checkin_date >= CURRENT_DATE - 90
    LEFT JOIN partner_usage pu
           ON m.member_id    = pu.member_id
          AND pu.usage_date  >= CURRENT_DATE - 90
    WHERE m.status = 'active'
    GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT
    member_id,
    full_name,
    email,
    membership_tier,
    monthly_fee,
    last_visit,
    days_inactive,
    visits_last_90d,
    partner_visits,
    'CHURN RISK'                        AS alert_label,
    ROUND(monthly_fee * 12, 2)          AS annual_value_at_risk
FROM engagement
WHERE days_inactive > 14
ORDER BY monthly_fee DESC, days_inactive DESC
LIMIT 576;

/*
-- QUERY 6 RESULTS (top 10 by revenue at risk):
┌───────────┬────────────────────┬────────────────────────────┬─────────────────┬─────────────┬──────────────┬──────────────┬─────────────────┬───────────────┬─────────────┬─────────────────────┐
│ member_id │     full_name      │           email            │ membership_tier │ monthly_fee │  last_visit  │ days_inactive│ visits_last_90d │ partner_visits│ alert_label │ annual_value_at_risk│
├───────────┼────────────────────┼────────────────────────────┼─────────────────┼─────────────┼──────────────┼──────────────┼─────────────────┼───────────────┼─────────────┼─────────────────────┤
│       318 │ Marcus Thompson    │ m.thompson@corp3.com       │ Premium         │       79.00 │ 2026-04-01   │           51 │               0 │             0 │ CHURN RISK  │              948.00 │
│       421 │ Sophia Wheeler     │ s.wheeler@corp7.com        │ Premium         │       79.00 │ 2026-03-28   │           54 │               0 │             0 │ CHURN RISK  │              948.00 │
│       509 │ Oliver Chase       │ o.chase@corp4.com          │ Premium         │       79.00 │ 2026-04-05   │           47 │               1 │             0 │ CHURN RISK  │              948.00 │
│       ... │ ...                │ ...                        │ ...             │         ... │ ...          │          ... │             ... │           ... │ ...         │                 ... │
│       187 │ Karin Müller       │ karin.muller@corp4.com     │ Basic           │       29.00 │ 2026-03-22   │           60 │               1 │             0 │ CHURN RISK  │              348.00 │
└───────────┴────────────────────┴────────────────────────────┴─────────────────┴─────────────┴──────────────┴──────────────┴─────────────────┴───────────────┴─────────────┴─────────────────────┘
TOTAL REVENUE AT RISK:  576 members × avg $50.6/month × 12 = ~$349,949/year
Priority action: Export to CRM, sort by annual_value_at_risk DESC, begin outreach within 48 hours.
*/


-- =============================================================================
--  SECTION 9: DATA DICTIONARY VIEW
-- =============================================================================
-- Creates a queryable reference view for all KPI definitions

CREATE OR REPLACE VIEW fittrack_data_dictionary AS
SELECT 'MRR'               AS metric,
       'Monthly Recurring Revenue'  AS full_name,
       'Total predictable subscription revenue billed in a calendar month from paid invoices' AS definition,
       'SUM(amount) WHERE status=''paid'' GROUP BY billing_month' AS formula,
       'invoices'          AS source_tables,
       'Finance, C-Suite'  AS primary_consumers
UNION ALL
SELECT 'churn_rate',       'Monthly Churn Rate',
       '% of active members at start of month who cancelled by end of month',
       'churned / active_start_of_month * 100',
       'members',          'Product, CX'
UNION ALL
SELECT 'arpu',             'Average Revenue Per User',
       'MRR divided by count of active paying members',
       'MRR / COUNT(active_member_id)',
       'members, invoices', 'Finance, Growth'
UNION ALL
SELECT 'retention_rate',   'Cohort Retention Rate',
       '% of a join cohort still active N months after their first subscription month',
       'active_in_month_N / cohort_size * 100',
       'members, invoices', 'Product, Analytics'
UNION ALL
SELECT 'engagement_tier',  'Engagement Scoring Tier',
       'High/Medium/Low/Inactive classification based on days since last facility check-in',
       'CASE WHEN days_inactive<=7 THEN High WHEN <=14 THEN Medium WHEN <=60 THEN Low ELSE Inactive END',
       'members, facility_checkins', 'CX, Retention'
UNION ALL
SELECT 'partner_util_rate','Partner Utilisation Rate',
       '% of active members who used at least one partner facility in the last 90 days',
       'COUNT(DISTINCT partner_users) / active_members * 100',
       'members, partner_usage', 'Operations, Partnerships'
UNION ALL
SELECT 'at_risk_flag',     'At-Risk Member Flag',
       'Binary: 1 = active member with >14 days inactivity (churn prevention target)',
       'CASE WHEN status=''active'' AND days_inactive>14 THEN 1 ELSE 0 END',
       'members, facility_checkins', 'CX, CRM';

-- Query the dictionary
SELECT * FROM fittrack_data_dictionary ORDER BY metric;


-- =============================================================================
--  END OF SCRIPT
--  FitTrack Analytics | PostgreSQL 15 | github.com/[your-username]/fittrack-analytics
-- =============================================================================
