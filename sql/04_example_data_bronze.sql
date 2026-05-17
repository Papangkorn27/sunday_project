INSERT INTO bronze.company_list
(company_name, district, province, phone_no, effective_date, expiry_date)
VALUES
('AAA Co', 'Bangrak', 'Bangkok', '02-123-4567', DATE '2021-01-01', DATE '2022-01-01');

INSERT INTO bronze.plan_list (plan_code, description)
VALUES
('A', 'aaaa'),
('B', 'bbbb'),
('C', 'cccc');

INSERT INTO bronze.customer_list
(name, first_name, last_name, national_id, plan_code, gender, district, province, preferred_hospital)
VALUES
('AAA Co', 'Mary', 'One', '01-1111', 'A', 'M', 'Wattana', 'Bangkok', 'Rajvithi'),
('AAA Co', 'Sue', 'Two', '1-1-200', 'A', 'F', 'Jatujak', 'Bkk', 'Siriaj'),
('AAA Co', 'Luke', 'Three', '1-1-300', 'B', 'F', 'Mae Sot', 'Tak', 'Rajvithi'),
('AAA Co', 'Charlie', 'Four', '1-1-400', 'B', 'M', 'Pak Kret', 'Nonthaburi', 'Rama'),
('AAA Co', 'Parker', 'Five', '11115', 'C', 'M', 'Bangrak', 'Bangkok', 'Siriraj');

INSERT INTO bronze.employee_addition
(name, first_name, last_name, national_id, plan_code, gender, district, province, preferred_hospital, effective_date)
VALUES
('AAA Co', 'John', 'Six', '01-11-6', 'A', 'F', 'Prawet', 'BKK', 'Siriraj', DATE '2021-01-31'),
('AAA Co', 'Susan', 'Seven', '0111-7', 'C', 'F', 'Bangna', 'Bangkok', 'Rajvithi', DATE '2021-01-31'),
('AAA Co', 'Luke', 'Eight', '1-1-1111', 'B', 'M', 'Bangrak', 'Bangkok', 'Rama', DATE '2021-01-31');
