"""Condition co-occurrence and GDS clustering helpers."""

from __future__ import annotations

from src.utils.connection import neo4j_session


def condition_cooccurrence(limit: int = 50) -> list[dict]:
    query = """
    MATCH (c1:Condition)<-[:HAS_CONDITION]-(p:Patient)-[:HAS_CONDITION]->(c2:Condition)
    WHERE c1.code < c2.code
    RETURN c1.code AS condition_1, c2.code AS condition_2,
           count(DISTINCT p) AS shared_patients
    ORDER BY shared_patients DESC LIMIT $limit
    """
    with neo4j_session() as session:
        return [record.data() for record in session.run(query, limit=limit)]


if __name__ == "__main__":
    print(condition_cooccurrence(10))
