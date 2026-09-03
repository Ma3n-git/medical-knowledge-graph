"""Timeout-aware SQLite and Neo4j benchmark runner."""

from __future__ import annotations

import csv
import os
import sqlite3
import time
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results" / "metrics"
TIMEOUT_SECONDS = float(os.getenv("BENCHMARK_TIMEOUT_SECONDS", "30"))

SQLITE_TARGETS = {
    "sqlite-5k": os.getenv("SQLITE_5K_PATH", ""),
    "sqlite-10k": os.getenv("SQLITE_10K_PATH", ""),
}

BENCHMARK_QUERIES: dict[str, tuple[str, str]] = {
    "patient_count": (
        "MATCH (p:Patient) RETURN count(p)",
        "SELECT COUNT(*) FROM patients",
    ),
    "condition_prevalence": (
        "MATCH (p:Patient)-[:HAS_CONDITION]->(c:Condition) "
        "RETURN c.code, count(DISTINCT p) ORDER BY count(DISTINCT p) DESC",
        "SELECT code, COUNT(DISTINCT patient) FROM conditions "
        "GROUP BY code ORDER BY COUNT(DISTINCT patient) DESC",
    ),
    "medication_prevalence": (
        "MATCH (p:Patient)-[:PRESCRIBED]->(m:Medication) "
        "RETURN m.code, count(DISTINCT p) ORDER BY count(DISTINCT p) DESC",
        "SELECT code, COUNT(DISTINCT patient) FROM medications "
        "GROUP BY code ORDER BY COUNT(DISTINCT patient) DESC",
    ),
    "patient_degree": (
        "MATCH (p:Patient) OPTIONAL MATCH (p)-->(connected) "
        "RETURN p.id, count(DISTINCT connected) ORDER BY count(DISTINCT connected) DESC",
        "SELECT patient, COUNT(*) FROM (SELECT patient FROM conditions "
        "UNION ALL SELECT patient FROM medications) GROUP BY patient",
    ),
    "polypharmacy": (
        "MATCH (p:Patient)-[:PRESCRIBED]->(m:Medication) "
        "WITH p, count(DISTINCT m) AS medication_count "
        "WHERE medication_count >= 5 RETURN p.id, medication_count",
        "SELECT patient, COUNT(DISTINCT code) FROM medications "
        "GROUP BY patient HAVING COUNT(DISTINCT code) >= 5",
    ),
}


def run_sqlite(path_text: str, dataset: str) -> list[dict[str, Any]]:
    path = Path(path_text)
    if not path_text or not path.exists():
        return [{"system": "sqlite", "dataset": dataset, "status": "missing"}]

    connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    connection.execute(f"PRAGMA busy_timeout={int(TIMEOUT_SECONDS * 1000)}")
    rows: list[dict[str, Any]] = []
    try:
        for name, (_cypher, sql) in BENCHMARK_QUERIES.items():
            started = time.perf_counter()
            status = "ok"
            error = ""
            try:
                connection.execute(sql).fetchall()
            except Exception as exc:
                status, error = "error", str(exc)
            rows.append({
                "system": "sqlite", "dataset": dataset, "query": name,
                "elapsed_seconds": time.perf_counter() - started,
                "status": status, "error": error,
            })
    finally:
        connection.close()
    return rows


def run_neo4j(dataset: str) -> list[dict[str, Any]]:
    from neo4j import GraphDatabase

    driver = GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(os.getenv("NEO4J_USER", "neo4j"), os.getenv("NEO4J_PASSWORD", "")),
    )
    rows: list[dict[str, Any]] = []
    try:
        for name, (cypher, _sql) in BENCHMARK_QUERIES.items():
            started = time.perf_counter()
            status = "ok"
            error = ""
            try:
                with driver.session(database=os.getenv("NEO4J_DATABASE", "neo4j")) as session:
                    session.run(cypher, timeout=TIMEOUT_SECONDS).consume()
            except Exception as exc:
                status, error = "error", str(exc)
            rows.append({
                "system": "neo4j", "dataset": dataset, "query": name,
                "elapsed_seconds": time.perf_counter() - started,
                "status": status, "error": error,
            })
    finally:
        driver.close()
    return rows


def main() -> None:
    rows: list[dict[str, Any]] = []
    for dataset, path in SQLITE_TARGETS.items():
        rows.extend(run_sqlite(path, dataset))
    if os.getenv("RUN_NEO4J", "1") == "1":
        rows.extend(run_neo4j(os.getenv("NEO4J_DATASET", "neo4j")))

    RESULTS.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output = RESULTS / f"benchmark_results_{stamp}.csv"
    fields = ["system", "dataset", "query", "elapsed_seconds", "status", "error"]
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {output}")


if __name__ == "__main__":
    main()
