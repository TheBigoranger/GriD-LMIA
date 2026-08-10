#!/usr/bin/env python3
"""Generate explicit per-symbol documentation inventory records from the seed."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SUPPORT = ROOT / "support"
SEED = ROOT / "documentation-inventory.seed.json"
OUTPUT = ROOT / "documentation-inventory.json"
INDEX_OUTPUT = SUPPORT / "api-index.tex"
CODE_LINK_OUTPUT = SUPPORT / "api-code-links.tex"


def unique(values: list[str]) -> list[str]:
    return list(dict.fromkeys(values))


def web_location(owner: str, symbol: str, kind: str, has_case_collision: bool) -> str:
    slug = symbol.lower()
    if has_case_collision and "property" in kind:
        slug += "-property"
    if owner == "root":
        return f"/documents/getting-started/installation/#api-{slug}"
    if owner == "helper":
        return f"/documents/reference/helpers/#api-{slug}"
    return f"/documents/reference/{owner}/#api-{slug}"


def expand() -> dict:
    seed = json.loads(SEED.read_text(encoding="utf-8"))
    casefold_counts = Counter(
        (group["owner"], member["name"].casefold())
        for group in seed["groups"]
        for member in group["members"]
    )
    records: list[dict] = []
    presentation_groups: list[dict] = []
    for group in seed["groups"]:
        names: list[str] = []
        for member in group["members"]:
            symbol = member["name"]
            names.append(symbol)
            tex_index = group["tex_index"].replace("{member}", symbol)
            location = web_location(
                group["owner"],
                symbol,
                member["kind"],
                casefold_counts[(group["owner"], symbol.casefold())] > 1,
            )
            record = {
                "id": f"{group['owner']}.{symbol}",
                "owner": group["owner"],
                "symbol": symbol,
                "kind": member["kind"],
                "category": group["category"],
                "inherited_from": member.get("inherited_from"),
                "source_evidence": unique([member["source"], *group["source_evidence"]]),
                "test_evidence": group["test_evidence"],
                "call_forms_options": group["call_forms_options"],
                "inputs": group["inputs"],
                "return_type_shape": group["returns"],
                "validation_errors": group["validation_errors"],
                "supported_scope": group["supported_scope"],
                "tex_anchor": group["tex_anchor"],
                "tex_index": tex_index,
                "tex_example_evidence": group["example_evidence"],
                "web_route_or_anchor": location,
                "web_example_evidence": location + "-example",
                "executable_example": group["executable_example"]
            }
            records.append(record)
        presentation_groups.append({"id": group["id"], "owner": group["owner"], "members": names})
    identifiers = [record["id"] for record in records]
    if len(identifiers) != len(set(identifiers)):
        duplicates = sorted({item for item in identifiers if identifiers.count(item) > 1})
        raise ValueError(f"duplicate per-symbol ids: {duplicates}")
    for field in ["web_route_or_anchor", "web_example_evidence"]:
        targets = [record[field] for record in records]
        if len(targets) != len(set(targets)):
            duplicates = sorted({item for item in targets if targets.count(item) > 1})
            raise ValueError(f"duplicate {field} targets: {duplicates}")
    return {
        "schema_version": 2,
        "version": seed["version"],
        "authority": seed["authority"],
        "record_contract": "Every public symbol is one complete record. Shared family evidence is copied into every applicable record.",
        "exclusions": seed["exclusions"],
        "records": records,
        "presentation_groups": presentation_groups
    }


def render() -> str:
    return json.dumps(expand(), indent=2, ensure_ascii=False) + "\n"


def tex_text(value: str) -> str:
    return value.replace("_", r"\_")


def canonical_symbol_records(records: list[dict]) -> dict[str, dict]:
    """Choose the first inventory record for each case-sensitive symbol."""
    result: dict[str, dict] = {}
    for record in records:
        result.setdefault(record["symbol"], record)
    return result


def code_link_aliases(records: list[dict]) -> dict[str, str]:
    """Map exact code literals to a canonical reference-section label."""
    canonical = canonical_symbol_records(records)
    aliases = {symbol: record["tex_anchor"] for symbol, record in canonical.items()}
    for record in records:
        visible = record["tex_index"]
        if "!" not in visible and "." in visible:
            aliases.setdefault(visible, canonical[record["symbol"]]["tex_anchor"])
    return aliases


def index_line(record: dict) -> str:
    key = record["tex_index"]
    if "!" in key:
        owner, symbol = key.split("!", 1)
        entry = f"{owner}@\\texttt{{{tex_text(owner)}}}!{symbol}@\\texttt{{{tex_text(symbol)}}}"
    else:
        entry = f"{key}@\\texttt{{{tex_text(key)}}}"
    return f"% inventory-id: {record['id']}\n\\index{{{entry}}}"


def render_code_links() -> str:
    records = expand()["records"]
    lines = ["% Generated by generate_inventory.py from documentation-inventory.seed.json. Do not edit directly."]
    for literal, destination in code_link_aliases(records).items():
        lines.append(f"\\DeclareApiCodeLink{{{literal}}}{{{destination}}}")
    return "\n".join(lines) + "\n"


def render_index() -> str:
    records = expand()["records"]
    lines = ["% Generated by generate_inventory.py from documentation-inventory.seed.json. Do not edit directly."]
    lines.extend(index_line(record) for record in records)
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when documentation-inventory.json is stale")
    args = parser.parse_args()
    expected = render()
    expected_index = render_index()
    expected_code_links = render_code_links()
    if args.check:
        actual = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        actual_index = INDEX_OUTPUT.read_text(encoding="utf-8") if INDEX_OUTPUT.exists() else ""
        actual_code_links = CODE_LINK_OUTPUT.read_text(encoding="utf-8") if CODE_LINK_OUTPUT.exists() else ""
        if actual != expected or actual_index != expected_index or actual_code_links != expected_code_links:
            print("inventory artifacts are stale; run: python doc/generate_inventory.py")
            return 1
        count = len(json.loads(expected)["records"])
        print(f"documentation inventory is current ({count} per-symbol records)")
        return 0
    OUTPUT.write_text(expected, encoding="utf-8", newline="\n")
    INDEX_OUTPUT.write_text(expected_index, encoding="utf-8", newline="\n")
    CODE_LINK_OUTPUT.write_text(expected_code_links, encoding="utf-8", newline="\n")
    print(f"wrote {OUTPUT}, {INDEX_OUTPUT}, and {CODE_LINK_OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
