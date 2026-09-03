"""Run the Neo4j 10K query set independently from other benchmarks."""

from __future__ import annotations

import csv
import os
import time
from datetime import datetime
from pathlib import Path

from neo4j import GraphDatabase

ROOT = Path(__file__).resolve().parents[2]
METRICS = ROOT / "results" / "metrics"
TIMEOUT_SECONDS = float(os.getenv("BENCHMARK_TIMEOUT_SECONDS", "30"))
REPEATS = int(os.getenv("BENCHMARK_REPEATS", "5"))

QUERIES = {
    "centrality_degree_ranking": "MATCH (p:Patient)-[:HAS_CONDITION]->(:Condition) RETURN p.id AS patient, count(*) AS degree ORDER BY degree DESC LIMIT 20",
    "condition_frequency_top_20": "MATCH (c:Condition)<-[:HAS_CONDITION]-(:Patient) RETURN c.code AS code, count(*) AS condition_count ORDER BY condition_count DESC LIMIT 20",
    "high_risk_patients": "MATCH (p:Patient)-[:HAS_CONDITION]->(:Condition) WITH p, count(*) AS condition_count WHERE condition_count >= 5 RETURN p.id AS patient, condition_count ORDER BY condition_count DESC LIMIT 20",
    "polypharmacy_patients": "MATCH (p:Patient)-[:PRESCRIBED]->(:Medication) WITH p, count(*) AS medication_count WHERE medication_count >= 5 RETURN p.id AS patient, medication_count ORDER BY medication_count DESC LIMIT 20",
}


def main() -> None:
    METRICS.mkdir(parents=True, exist_ok=True)
    uri = os.getenv("NEO4J_URI", "bolt://127.0.0.1:7687")
    auth = (os.getenv("NEO4J_USER", "neo4j"), os.getenv("NEO4J_PASSWORD", ""))
    database = os.getenv("NEO4J_DATABASE", "neo4j")
    rows = []
    driver = GraphDatabase.driver(uri, auth=auth)
    try:
        with driver.session(database=database) as session:
            session.run("RETURN 1").consume()
            for query_name, query in QUERIES.items():
                for repeat in range(1, REPEATS + 1):
                    started = time.perf_counter()
                    status = "ok"
                    error = ""
                    try:
                        session.run(query, timeout=TIMEOUT_SECONDS).consume()
                    except Exception as exc:
                        status, error = "error", str(exc)
                    rows.append({"system": "Neo4j", "database": "Neo4j_10K", "dataset_size": "10K", "query_name": query_name, "repeat": repeat, "elapsed_ms": round((time.perf_counter() - started) * 1000, 3), "status": status, "error": error})
    finally:
        driver.close()

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    raw_path = METRICS / f"neo4j_10k_results_{stamp}.csv"
    summary_path = METRICS / f"neo4j_10k_summary_{stamp}.csv"
    fields = list(rows[0]) if rows else ["system", "database", "dataset_size", "query_name", "repeat", "elapsed_ms", "status", "error"]
    with raw_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    summary_rows = []
    for query_name in QUERIES:
        timings = [
            row["elapsed_ms"] for row in rows
            if row["query_name"] == query_name and row["status"] == "ok"
        ]
        if timings:
            summary_rows.append({
                "system": "Neo4j",
                "database": "Neo4j_10K",
                "dataset_size": "10K",
                "query_name": query_name,
                "avg_elapsed_ms": round(sum(timings) / len(timings), 3),
                "successful_repeats": len(timings),
            })
    with summary_path.open("w", newline="", encoding="utf-8") as handle:
        summary_fields = ["system", "database", "dataset_size", "query_name", "avg_elapsed_ms", "successful_repeats"]
        writer = csv.DictWriter(handle, fieldnames=summary_fields)
        writer.writeheader()
        writer.writerows(summary_rows)
    print(f"Raw results: {raw_path}")
    print(f"Summary results: {summary_path}")


if __name__ == "__main__":
    main()
