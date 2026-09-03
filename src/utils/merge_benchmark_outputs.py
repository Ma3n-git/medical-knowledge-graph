"""Merge compatible benchmark summary CSVs without overwriting sources."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
METRICS = ROOT / "results" / "metrics"


def read_summary(path: Path) -> pd.DataFrame:
    frame = pd.read_csv(path)
    if "avg_elapsed_ms" not in frame.columns and "elapsed_ms" in frame.columns:
        frame = frame.assign(avg_elapsed_ms=frame["elapsed_ms"])
    required = {"system", "database", "query_name", "avg_elapsed_ms"}
    missing = required - set(frame.columns)
    if missing:
        raise ValueError(f"{path} is missing columns: {sorted(missing)}")
    if "dataset_size" not in frame.columns:
        frame["dataset_size"] = frame["database"].astype(str).str.extract(r"(5K|10K)", expand=False).fillna("unknown")
    return frame


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("summaries", nargs="+", type=Path)
    args = parser.parse_args()
    frames = [read_summary(path) for path in args.summaries]
    merged = pd.concat(frames, ignore_index=True).drop_duplicates()
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output = METRICS / f"final_benchmark_summary_{stamp}.csv"
    METRICS.mkdir(parents=True, exist_ok=True)
    merged.to_csv(output, index=False)
    print(f"Merged {len(merged)} rows into {output}")
    print("Source files were not modified.")


if __name__ == "__main__":
    main()
