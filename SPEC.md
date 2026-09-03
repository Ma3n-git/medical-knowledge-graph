# Project Specification

## Aim

Design, implement, and evaluate a reproducible healthcare knowledge graph based on synthetic Synthea patient records, with a comparison against relational SQLite queries.

## Objectives

1. Inspect and validate Synthea CSV data.
2. Transform clinical records into stable node and relationship representations.
3. Load patients, conditions, medications, encounters, and providers into Neo4j.
4. Apply graph analytics for similarity, clustering, embeddings, and patient risk exploration.
5. Implement semantically comparable SQLite queries.
6. Measure execution time across 5K and 10K datasets with repeat runs and timeout protection.
7. Produce dissertation-ready tables, charts, and limitations.

## Data model

| Node | Identifier |
|---|---|
| Patient | `id` |
| Condition | `code` |
| Medication | `code` |
| Encounter | `id` |
| Provider | `id` |

| Relationship | Direction |
|---|---|
| HAS_CONDITION | Patient -> Condition |
| PRESCRIBED | Patient -> Medication |
| WITH_PROVIDER | Encounter -> Provider |

## Evaluation

The benchmark records elapsed wall-clock time, query family, system, dataset, status, and errors. Each query should be repeated under the same conditions. Expensive self-joins and cross-patient overlap queries must have a hard timeout and be reported as timed out rather than silently omitted.

Primary comparison families:

- degree or centrality ranking
- condition prevalence
- patient similarity
- high-risk patient identification
- polypharmacy
- condition co-occurrence and communities

## Limitations

Synthea is synthetic and does not represent the full complexity of clinical practice. Query timings depend on hardware, cache state, database configuration, indexes, Neo4j and GDS versions, and the exact loaded dataset. A faster query is not by itself evidence of better clinical insight.

## Ethical considerations

The project uses synthetic data only. Results must not be interpreted as clinical advice or as evidence about real patients.
