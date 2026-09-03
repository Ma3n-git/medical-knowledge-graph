// Constraints for the verified healthcare graph schema.
CREATE CONSTRAINT patient_id_unique IF NOT EXISTS
FOR (p:Patient) REQUIRE p.id IS UNIQUE;

CREATE CONSTRAINT condition_code_unique IF NOT EXISTS
FOR (c:Condition) REQUIRE c.code IS UNIQUE;

CREATE CONSTRAINT medication_code_unique IF NOT EXISTS
FOR (m:Medication) REQUIRE m.code IS UNIQUE;

CREATE CONSTRAINT encounter_id_unique IF NOT EXISTS
FOR (e:Encounter) REQUIRE e.id IS UNIQUE;

CREATE CONSTRAINT provider_id_unique IF NOT EXISTS
FOR (p:Provider) REQUIRE p.id IS UNIQUE;