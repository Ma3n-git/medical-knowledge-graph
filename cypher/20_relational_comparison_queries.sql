-- Comparable SQLite queries for the graph analytics baseline.

-- Patient count
SELECT COUNT(*) AS patient_count
FROM patients;

-- Condition prevalence by distinct patient
SELECT code AS condition_code,
       description,
       COUNT(DISTINCT patient) AS patient_count
FROM conditions
GROUP BY code, description
ORDER BY patient_count DESC;

-- Medication prevalence by distinct patient
SELECT code AS medication_code,
       description,
       COUNT(DISTINCT patient) AS patient_count
FROM medications
GROUP BY code, description
ORDER BY patient_count DESC;

-- Patient condition-degree ranking
SELECT patient AS patient_id,
       COUNT(DISTINCT code) AS condition_degree
FROM conditions
GROUP BY patient
ORDER BY condition_degree DESC;

-- Polypharmacy indicator: five or more distinct medications
SELECT patient AS patient_id,
       COUNT(DISTINCT code) AS medication_count
FROM medications
GROUP BY patient
HAVING COUNT(DISTINCT code) >= 5
ORDER BY medication_count DESC;

-- Condition pair co-occurrence through shared patients
SELECT c1.code AS condition_a,
       c2.code AS condition_b,
       COUNT(DISTINCT c1.patient) AS shared_patient_count
FROM conditions c1
JOIN conditions c2
  ON c1.patient = c2.patient
 AND c1.code < c2.code
GROUP BY c1.code, c2.code
ORDER BY shared_patient_count DESC;