# Healthcare Knowledge Graph

This project builds and evaluates a patient-centric healthcare knowledge graph from Synthea synthetic health records. It uses Python for ETL, Neo4j for graph storage, Cypher and Graph Data Science for analysis, and SQLite queries as a relational comparison.

## Scope

The project investigates whether graph modelling makes connected healthcare analysis easier to express and more useful than equivalent relational queries. The main analysis areas are patient-condition centrality, condition prevalence, patient similarity, condition communities, embeddings, and polypharmacy patterns.

Only synthetic Synthea data is used. No real patient information is included.

## Verified graph schema

Nodes include `Patient`, `Condition`, `Medication`, `Encounter`, and `Provider`.

Relationships used by the current loader and query library are:

- `HAS_CONDITION`
- `PRESCRIBED`
- `WITH_PROVIDER`

## Repository layout

```text
cypher/                 Neo4j schema, GDS, analytics, and relational queries
src/etl/                Synthea extraction, transformation, and loading
src/analysis/           Similarity, clustering, and embedding helpers
src/utils/              Neo4j connection and benchmark utilities
results/                Locally generated metrics and figures
requirements.txt        Python dependencies
SPEC.md                 Project specification
```

## Setup

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Set connection values in a local `.env` file:

```text
NEO4J_URI=bolt://127.0.0.1:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=change-me
NEO4J_DATABASE=neo4j
```

## Running

Prepare Synthea CSV files, load the graph, and then run analysis modules:

```powershell
python -m src.etl.extract
python -m src.etl.transform
python -m src.etl.load
python -m src.analysis.similarity
python -m src.analysis.clustering
python -m src.analysis.embeddings
```

The Cypher files in `cypher/` can also be run in Neo4j Browser. The benchmark scripts write timestamped results and are intended for local experiments only.

## Reproducibility

Record the Synthea version, patient count, Neo4j version, GDS version, machine details, query text, timeout, and repeat count for every performance run. Timings should be compared only when the query semantics, dataset, and warm-up procedure are equivalent.
