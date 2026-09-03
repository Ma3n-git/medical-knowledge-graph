"""Neo4j connection helpers."""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Iterator

from dotenv import load_dotenv
from neo4j import Driver, GraphDatabase

load_dotenv()


def create_driver() -> Driver:
    return GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://127.0.0.1:7687"),
        auth=(os.getenv("NEO4J_USER", "neo4j"), os.getenv("NEO4J_PASSWORD", "")),
    )


@contextmanager
def neo4j_session() -> Iterator:
    driver = create_driver()
    try:
        with driver.session(database=os.getenv("NEO4J_DATABASE", "neo4j")) as session:
            yield session
    finally:
        driver.close()


if __name__ == "__main__":
    with neo4j_session() as session:
        print(session.run("RETURN 1 AS connected").single()["connected"])
