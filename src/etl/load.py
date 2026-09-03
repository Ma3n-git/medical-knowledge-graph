"""Batch-load normalized healthcare records into Neo4j."""

from __future__ import annotations

from typing import Iterable

from src.utils.connection import neo4j_session


def load_patients(session, rows: Iterable[dict]) -> None:
    session.run("UNWIND $rows AS row MERGE (p:Patient {id: row.id}) SET p += row", rows=list(rows)).consume()


def load_conditions(session, rows: Iterable[dict]) -> None:
    session.run("UNWIND $rows AS row MERGE (p:Patient {id: row.patient}) MERGE (c:Condition {code: row.code}) SET c.description = row.description MERGE (p)-[:HAS_CONDITION]->(c)", rows=list(rows)).consume()


def load_medications(session, rows: Iterable[dict]) -> None:
    session.run("UNWIND $rows AS row MERGE (p:Patient {id: row.patient}) MERGE (m:Medication {code: row.code}) SET m.description = row.description MERGE (p)-[:PRESCRIBED]->(m)", rows=list(rows)).consume()


def main() -> None:
    with neo4j_session() as session:
        session.run("RETURN 1").consume()
        print("Connected to Neo4j")


if __name__ == "__main__":
    main()
