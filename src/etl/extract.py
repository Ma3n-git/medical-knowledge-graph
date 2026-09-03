"""Read Synthea CSV files into pandas data frames."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

DEFAULT_INPUT = Path("data/synthea_output")
REQUIRED_FILES = ("patients.csv", "conditions.csv", "medications.csv", "encounters.csv", "providers.csv")


def extract_tables(input_dir: str | Path = DEFAULT_INPUT) -> dict[str, pd.DataFrame]:
    directory = Path(input_dir)
    tables = {}
    for filename in REQUIRED_FILES:
        path = directory / filename
        if path.exists():
            tables[path.stem] = pd.read_csv(path)
    return tables


def validate_tables(tables: dict[str, pd.DataFrame]) -> list[str]:
    errors = []
    for name, frame in tables.items():
        if frame.empty:
            errors.append(f"{name} is empty")
    return errors


if __name__ == "__main__":
    data = extract_tables()
    print(f"Extracted {len(data)} tables")
    for error in validate_tables(data):
        print(f"ERROR: {error}")
