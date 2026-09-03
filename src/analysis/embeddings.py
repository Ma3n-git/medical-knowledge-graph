"""FastRP projection and embedding helpers."""

from __future__ import annotations

from src.utils.connection import neo4j_session


def create_projection(name: str = "patient-condition-graph") -> dict:
    query = """
    CALL gds.graph.project($name, ['Patient', 'Condition'],
      {HAS_CONDITION: {orientation: 'UNDIRECTED'}})
    YIELD graphName, nodeCount, relationshipCount
    RETURN graphName, nodeCount, relationshipCount
    """
    with neo4j_session() as session:
        return session.run(query, name=name).single().data()


def write_fastrp(name: str = "patient-condition-graph", dimension: int = 128) -> dict:
    query = """
    CALL gds.fastRP.mutate($name, {embeddingDimension: $dimension,
      mutateProperty: 'fastrp_embedding'})
    YIELD nodePropertiesWritten
    RETURN nodePropertiesWritten
    """
    with neo4j_session() as session:
        return session.run(query, name=name, dimension=dimension).single().data()
