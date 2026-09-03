"""Normalize Synthea tables for Neo4j loading."""

from __future__ import annotations

from typing import Any

import pandas as pd


def _rename_existing(frame: pd.DataFrame, mapping: dict[str, str]) -> pd.DataFrame:
    return frame.rename(columns={key: value for key, value in mapping.items() if key in frame.columns}).copy()


def transform_patients(frame: pd.DataFrame) -> list[dict[str, Any]]:
    result = _rename_existing(frame, {"Id": "id", "ID": "id"})
    return result.dropna(subset=["id"]).drop_duplicates("id").to_dict("records")


def transform_conditions(frame: pd.DataFrame) -> list[dict[str, Any]]:
    result = _rename_existing(frame, {"PATIENT": "patient", "CODE": "code", "DESCRIPTION": "description"})
    columns = [column for column in ("patient", "code", "description") if column in result]
    return result.dropna(subset=["patient", "code"]).drop_duplicates(columns).to_dict("records")


def transform_medications(frame: pd.DataFrame) -> list[dict[str, Any]]:
    result = _rename_existing(frame, {"PATIENT": "patient", "CODE": "code", "DESCRIPTION": "description"})
    columns = [column for column in ("patient", "code", "description") if column in result]
    return result.dropna(subset=["patient", "code"]).drop_duplicates(columns).to_dict("records")
