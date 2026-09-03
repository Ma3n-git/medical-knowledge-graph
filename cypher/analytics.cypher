// Core analytics for the verified healthcare graph schema.
// Labels: Patient, Condition, Medication, Encounter, Provider
// Relationships: HAS_CONDITION, PRESCRIBED, WITH_PROVIDER

// Patient and condition counts
MATCH (p:Patient)
RETURN count(p) AS patients;

MATCH (c:Condition)
RETURN count(c) AS conditions;

// Conditions with the greatest patient coverage
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
RETURN c.code AS condition_code, c.description AS condition,
       count(DISTINCT p) AS patient_count
ORDER BY patient_count DESC;

// Medication prevalence
MATCH (p:Patient)-[:PRESCRIBED]->(m:Medication)
RETURN m.code AS medication_code, m.description AS medication,
       count(DISTINCT p) AS patient_count
ORDER BY patient_count DESC;

// Patient degree centrality: number of connected clinical entities
MATCH (p:Patient)
OPTIONAL MATCH (p)-->(connected)
RETURN p.id AS patient_id, count(DISTINCT connected) AS degree
ORDER BY degree DESC;

// Patients with multiple conditions
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
WITH p, count(DISTINCT c) AS condition_count
WHERE condition_count > 1
RETURN p.id AS patient_id, condition_count
ORDER BY condition_count DESC;

// Patients with multiple prescribed medications (polypharmacy indicator)
MATCH (p:Patient)-[:PRESCRIBED]->(m:Medication)
WITH p, count(DISTINCT m) AS medication_count
WHERE medication_count >= 5
RETURN p.id AS patient_id, medication_count
ORDER BY medication_count DESC;

// Condition co-occurrence through shared patients
MATCH (c1:Condition)<-[:HAS_CONDITION]-(p:Patient)-[:HAS_CONDITION]->(c2:Condition)
WHERE elementId(c1) < elementId(c2)
RETURN c1.code AS condition_a, c2.code AS condition_b,
       count(DISTINCT p) AS shared_patient_count
ORDER BY shared_patient_count DESC;

// Providers ranked by connected encounters
MATCH (e:Encounter)-[:WITH_PROVIDER]->(provider:Provider)
RETURN provider.id AS provider_id, count(DISTINCT e) AS encounter_count
ORDER BY encounter_count DESC;// =============================================================================
// Healthcare Knowledge Graph - Analytics Queries
// Neo4j Cypher Query Library
// =============================================================================

// =============================================================================
// PATIENT SIMILARITY ANALYSIS (without projection)
// =============================================================================
MATCH (p1:Patient {id: '<patient_A_id>'}),
      (p2:Patient {id: '<patient_B_id>'}),
      path = shortestPath(
          (p1)-[:HAS_CONDITION*]-(p2)
      )
RETURN [n IN nodes(path) |
        coalesce(n.description, n.id)] AS chain,
       length(path)                    AS hops

// Find patients with similar condition profiles (Jaccard similarity)
MATCH (p1:Patient)-[:HAS_CONDITION]->(c:Condition)<-[:HAS_CONDITION]-(p2:Patient)
WHERE p1 < p2
WITH p1, p2, count(c) AS sharedConditions
MATCH (p1)-[:HAS_CONDITION]->(c1:Condition)
WITH p1, p2, sharedConditions, collect(DISTINCT c1) AS conditions1
MATCH (p2)-[:HAS_CONDITION]->(c2:Condition)
WITH p1, p2, sharedConditions, conditions1, collect(DISTINCT c2) AS conditions2
WITH p1, p2, sharedConditions, conditions1 + conditions2 AS allConditions
WITH p1, p2, sharedConditions, size(conditions1) AS size1, size(conditions2) AS size2, allConditions
WITH p1, p2, sharedConditions, size1, size2, size(DISTINCT allConditions) AS totalConditions
WHERE totalConditions > 0
RETURN p1.id AS patient1, p2.id AS patient2,
       sharedConditions,
       size1, size2, totalConditions,
       toFloat(sharedConditions) / totalConditions AS jaccardSimilarity
ORDER BY jaccardSimilarity DESC
LIMIT 100;

// Find similar patients for a specific patient
MATCH (target:Patient {id: $patientId})-[:HAS_CONDITION]->(c:Condition)<-[:HAS_CONDITION]-(similar:Patient)
WHERE target <> similar
WITH target, similar, count(c) AS sharedConditions
MATCH (target)-[:HAS_CONDITION]->(tc:Condition)
WITH target, similar, sharedConditions, collect(tc.description) AS targetConditions
MATCH (similar)-[:HAS_CONDITION]->(sc:Condition)
WITH target, similar, sharedConditions, targetConditions, collect(sc.description) AS similarConditions
WITH target, similar, sharedConditions, targetConditions, similarConditions,
     targetConditions + similarConditions AS allConditions
RETURN similar.id AS similarPatientId,
       sharedConditions,
       targetConditions,
       similarConditions,
       toFloat(sharedConditions) / size(DISTINCT allConditions) AS jaccardSimilarity
ORDER BY sharedConditions DESC
LIMIT 20;

// =============================================================================
// CONDITION CO-OCCURRENCE AND CLUSTERING
// =============================================================================

// Find top condition co-occurrences
MATCH (c1:Condition)-[:CO_OCCURS]-(c2:Condition)
WHERE c1.code < c2.code
RETURN c1.description AS condition1,
       c2.description AS condition2,
       r.cooccurrence_count AS cooccurrenceCount,
       r.cooccurrence_score AS cooccurrenceScore
ORDER BY cooccurrenceCount DESC
LIMIT 50;

// Find conditions by category
MATCH (c:Condition)
WHERE c.category = $category
RETURN c.code AS code, c.description AS description
ORDER BY c.description;

// Find related conditions (co-occur with a given condition)
MATCH (target:Condition {code: $conditionCode})-[:CO_OCCURS]-(related:Condition)
WHERE target <> related
RETURN related.description AS relatedCondition,
       r.cooccurrence_count AS cooccurrenceCount
ORDER BY cooccurrenceCount DESC
LIMIT 10;

// Count conditions per category
MATCH (c:Condition)
RETURN c.category AS category, count(c) AS conditionCount
ORDER BY conditionCount DESC;

// =============================================================================
// PATIENT COHORT ANALYSIS
// =============================================================================

// Find patients with multiple chronic conditions
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
WHERE c.category = 'problem-list-item' OR c.category = 'condition'
WITH p, count(DISTINCT c) AS chronicConditionCount
WHERE chronicConditionCount >= $minConditions
RETURN p.id AS patientId,
       chronicConditionCount,
       collect(c.description) AS conditions
ORDER BY chronicConditionCount DESC
LIMIT 50;

// Find patients by age group and condition
WITH [
    {name: '0-17', min: 0, max: 17},
    {name: '18-34', min: 18, max: 34},
    {name: '35-49', min: 35, max: 49},
    {name: '50-64', min: 50, max: 64},
    {name: '65+', min: 65, max: 120}
] AS ageGroups
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition {code: $conditionCode})
UNWIND ageGroups AS ageGroup
WITH p, c, ageGroup
WHERE duration.between(p.birth_date, date()).years >= ageGroup.min
  AND duration.between(p.birth_date, date()).years <= ageGroup.max
RETURN ageGroup.name AS ageGroup,
       count(DISTINCT p) AS patientCount
ORDER BY ageGroup.min;

// Find high-risk patients (multiple conditions + multiple medications)
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
WITH p, count(DISTINCT c) AS conditionCount
MATCH (p)-[:TAKES_MEDICATION]->(m:Medication)
WITH p, conditionCount, count(DISTINCT m) AS medicationCount
WHERE conditionCount >= 3 AND medicationCount >= 3
RETURN p.id AS patientId,
       conditionCount,
       medicationCount,
       conditionCount + medicationCount AS totalRiskFactors
ORDER BY totalRiskFactors DESC
LIMIT 30;

// =============================================================================
// MEDICATION ANALYSIS
// =============================================================================

// Find medications commonly prescribed together
MATCH (p:Patient)-[:TAKES_MEDICATION]->(m1:Medication)
MATCH (p)-[:TAKES_MEDICATION]->(m2:Medication)
WHERE m1.code < m2.code
WITH m1, m2, count(p) AS patientCount
RETURN m1.name AS medication1,
       m2.name AS medication2,
       patientCount
ORDER BY patientCount DESC
LIMIT 30;

// Find patients with specific medication patterns
MATCH (p:Patient)-[:TAKES_MEDICATION]->(m:Medication)
WHERE m.name CONTAINS $searchTerm
WITH p, collect(m.name) AS medications
RETURN p.id AS patientId,
       medications,
       size(medications) AS medicationCount
ORDER BY medicationCount DESC
LIMIT 20;

// Find medication-to-condition relationships
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
MATCH (p)-[:TAKES_MEDICATION]->(m:Medication)
WITH m, c, count(p) AS patientCount
WHERE patientCount >= $minPatients
RETURN m.name AS medication,
       c.description AS condition,
       patientCount
ORDER BY patientCount DESC
LIMIT 50;

// =============================================================================
// ENCOUNTER ANALYSIS
// =============================================================================

// Find encounter patterns by type
MATCH (p:Patient)-[:EXPERIENCED]->(e:Encounter)
WHERE e.class_code = $encounterType
WITH e, count(p) AS patientCount, collect(DISTINCT p.id) AS patients
RETURN e.description AS encounterType,
       patientCount,
       patients
ORDER BY patientCount DESC
LIMIT 20;

// Find frequent encounter sequences (transitions)
MATCH (p:Patient)-[:EXPERIENCED]->(e1:Encounter)-[:NEXT*1..3]->(e2:Encounter)
WHERE e1.start_date < e2.start_date
WITH e1.class_code AS fromClass, e2.class_code AS toClass, count(*) AS sequenceCount
RETURN fromClass, toClass, sequenceCount
ORDER BY sequenceCount DESC
LIMIT 30;

// Find patients with high encounter frequency
MATCH (p:Patient)-[:EXPERIENCED]->(e:Encounter)
WITH p, count(e) AS encounterCount
WHERE encounterCount >= $minEncounters
RETURN p.id AS patientId,
       encounterCount
ORDER BY encounterCount DESC
LIMIT 30;

// =============================================================================
// CENTRALITY ANALYSIS
// =============================================================================

// Find most connected conditions (degree centrality)
// First get the maximum degree
CALL {
  CALL gds.degree.stream('condCommunities')
  YIELD score
  RETURN max(score) AS maxDegree
}
    // Then get the ranked list and calculate the percentage
    CALL gds.degree.stream('condCommunities')
    YIELD nodeId, score AS degree
    RETURN 
    gds.util.asNode(nodeId).description AS Condition,
    gds.util.asNode(nodeId).code AS Code,
    degree AS CoOccurrenceConnections,
    round(100.0 * degree / maxDegree, 1) AS PercentOfMax
    ORDER BY degree DESC
    LIMIT 20;

// Find conditions that bridge different categories (betweenness approximation)
// First calculate the maximum betweenness
CALL {
  CALL gds.betweenness.stream('condCommunities')
  YIELD score
  RETURN max(score) AS maxBetweenness
}
    // Then return the top results with percentage
    CALL gds.betweenness.stream('condCommunities')
    YIELD nodeId, score AS betweenness
    RETURN 
    gds.util.asNode(nodeId).description AS Condition,
    gds.util.asNode(nodeId).code AS Code,
    betweenness,
    round(100.0 * betweenness / maxBetweenness, 1) AS PercentOfMax
    ORDER BY betweenness DESC
    LIMIT 20;

// Find influential patients by connection count
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
WITH p, count(DISTINCT c) AS conditionCount
MATCH (p)-[:TAKES_MEDICATION]->(m:Medication)
WITH p, conditionCount, count(DISTINCT m) AS medicationCount
MATCH (p)-[:EXPERIENCED]->(e:Encounter)
WITH p, conditionCount, medicationCount, count(e) AS encounterCount
RETURN p.id AS patientId,
       conditionCount,
       medicationCount,
       encounterCount,
       conditionCount + medicationCount + encounterCount AS totalConnections
ORDER BY totalConnections DESC
LIMIT 30;

// =============================================================================
// GRAPH DATA SCIENCE ALGORITHMS
// =============================================================================

// Project patient similarity graph for GDS
CALL gds.graph.project(
    'PatientSimilarityGraph',
    'Patient',
    {
        HAS_CONDITION: {
            type: 'HAS_CONDITION',
            orientation: 'UNDIRECTED'
        },
        TAKES_MEDICATION: {
            type: 'TAKES_MEDICATION',
            orientation: 'UNDIRECTED'
        }
    }
);

// PageRank for conditions
CALL gds.pageRank.write(
    'ConditionCooccurrenceGraph',
    {
        writeProperty: 'pageRank',
        relationshipWeightProperty: 'cooccurrence_score'
    }
)
YIELD nodes, relationships, ranIterations;

// =============================================================================
// CLINICAL PATTERN QUERIES
// =============================================================================

// Find patients with diabetes and related complications
MATCH (p:Patient)-[:HAS_CONDITION]->(d:Condition)
WHERE d.description CONTAINS 'Diabetes'
WITH p
MATCH (p)-[:HAS_CONDITION]->(c:Condition)
WHERE c.description CONTAINS 'Hypertension' OR c.description CONTAINS 'Retinopathy'
WITH p, collect(c.description) AS complications
RETURN p.id AS patientId,
       complications,
       size(complications) AS complicationCount
ORDER BY complicationCount DESC;

// Find medication adherence patterns
MATCH (p:Patient)-[:TAKES_MEDICATION]->(m:Medication)
WHERE m.end_date IS NULL
WITH p, collect(m.name) AS currentMedications
WHERE size(currentMedications) >= $minMedications
RETURN p.id AS patientId,
       currentMedications,
       size(currentMedications) AS medicationCount;

// Find seasonal encounter patterns
MATCH (p:Patient)-[:EXPERIENCED]->(e:Encounter)
WITH e.class_code AS encounterType,
     month(datetime(e.start_date)) AS encounterMonth,
     count(*) AS encounterCount
RETURN encounterType,
       encounterMonth,
       encounterCount
ORDER BY encounterType, encounterCount DESC;

// =============================================================================
// REPORTING QUERIES
// =============================================================================

// Summary statistics
CALL {
    MATCH (p:Patient) RETURN count(p) AS patientCount
    UNION
    MATCH (c:Condition) RETURN count(c) AS conditionCount
    UNION
    MATCH (m:Medication) RETURN count(m) AS medicationCount
    UNION
    MATCH (e:Encounter) RETURN count(e) AS encounterCount
}
RETURN patientCount, conditionCount, medicationCount, encounterCount;

// Gender distribution of conditions
MATCH (p:Patient {gender: $gender})-[:HAS_CONDITION]->(c:Condition)
RETURN c.description AS condition,
       count(p) AS patientCount
ORDER BY patientCount DESC
LIMIT 30;

// Top 20 most prevalent conditions
MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition)
WITH c, count(p) AS patientCount
ORDER BY patientCount DESC
LIMIT 20
RETURN c.description AS condition,
       c.category AS category,
       patientCount;
