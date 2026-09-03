"""Patient similarity queries using shared conditions."""

from __future__ import annotations

from src.utils.connection import neo4j_session

QUERY = """
MATCH (p1:Patient)-[:HAS_CONDITION]->(c:Condition)<-[:HAS_CONDITION]-(p2:Patient)
WHERE p1.id < p2.id
WITH p1, p2, count(DISTINCT c) AS shared
MATCH (p1)-[:HAS_CONDITION]->(c1:Condition)
WITH p1, p2, shared, count(DISTINCT c1) AS total1
MATCH (p2)-[:HAS_CONDITION]->(c2:Condition)
WITH p1, p2, shared, total1, count(DISTINCT c2) AS total2
RETURN p1.id AS patient_1, p2.id AS patient_2, shared,
       toFloat(shared) / (total1 + total2 - shared) AS jaccard
ORDER BY jaccard DESC
LIMIT $limit
"""


def top_similar_patients(limit: int = 50) -> list[dict]:
    with neo4j_session() as session:
        return [record.data() for record in session.run(QUERY, limit=limit)]


if __name__ == "__main__":
    print(top_similar_patients(10))
