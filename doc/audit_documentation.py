#!/usr/bin/env python3
"""Audit the TeX manual, explicit API inventory, terminology, and notation contracts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.dont_write_bytecode = True

import generate_inventory
import generate_terminology


DOC = Path(__file__).resolve().parent
ROOT = DOC.parent

CHAPTER_ORDER = [
    "release-history.tex", "workflow-introduction.tex", "workflow-constraints.tex",
    "installation.tex", "pdbase.tex", "pdmat.tex", "pdvar.tex", "pdlmi.tex",
    "helpers.tex", "examples.tex", "bernstein-mathematics.tex", "certificate-mathematics.tex"
]

EXCLUDED_ENVIRONMENTS = {
    "lstlisting", "verbatim", "Verbatim", "tikzpicture", "thebibliography", "quote",
    "equation", "equation*", "align", "align*", "aligned", "gather", "gather*",
    "multline", "multline*", "displaymath", "split", "cases", "bmatrix", "pmatrix"
}

NEGATIVE = re.compile(r"\b(?:not|no|without|cannot|does\s+not|is\s+not|rather\s+than)\b", re.IGNORECASE)
BANNED = re.compile(r"\b(?:delve|tapestry|myriad|groundbreaking|game-changing|seamless|seamlessly|transformative|intricate|multifaceted|holistic|revolutionary|unlock|unlocks|unlocking)\b", re.IGNORECASE)
ACRONYM = re.compile(r"\b[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+\b|\b[A-Z]{2,}\b")

GENERAL_OR_EXTERNAL = {
    "API", "HTML", "PDF", "SVG", "MATLAB", "YALMIP", "MOSEK", "COPT", "SEDUMI",
    "SDPT3", "LMILAB", "IEEE", "SIAM", "DOI", "JSTOR", "TOC", "USA", "RGB", "LMIA", "TERM"
}

def class_block_names(path: Path, block_pattern: str) -> set[str]:
    """Read simple prototype/property names from one classdef declaration block."""
    names: set[str] = set()
    active = False
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not active:
            active = re.fullmatch(block_pattern, line, re.IGNORECASE) is not None
            continue
        if line == "end":
            active = False
            continue
        line = re.sub(r"%.*$", "", line).strip()
        if not line:
            continue
        match = re.search(r"(?:\[[^\]]+\]|[A-Za-z]\w*)\s*=\s*([A-Za-z]\w*)\s*\(|^([A-Za-z]\w*)\b", line)
        if match:
            names.add(match.group(1) or match.group(2))
    return names


def public_method_files(owner: str) -> set[str]:
    class_dir = ROOT / f"@{owner}"
    methods = {path.stem for path in class_dir.glob("*.m")}
    protected = class_block_names(
        class_dir / f"{owner}.m",
        r"methods\s*\([^)]*Access\s*=\s*protected[^)]*\)",
    )
    return methods - protected


def public_properties(owner: str) -> set[str]:
    return class_block_names(
        ROOT / f"@{owner}" / f"{owner}.m",
        r"properties\s*\([^)]*SetAccess\s*=\s*private[^)]*\)",
    )


def expected_ids() -> set[str]:
    """Derive the callable surface from the current MATLAB source tree."""
    pdbase_methods = public_method_files("pdbase")
    result = {f"pdbase.{name}" for name in pdbase_methods | public_properties("pdbase")}
    inherited = pdbase_methods - {"pdbase"}
    result |= {f"pdmat.{name}" for name in public_method_files("pdmat") | inherited | public_properties("pdmat")}
    result |= {f"pdvar.{name}" for name in public_method_files("pdvar") | inherited | public_properties("pdvar")}
    result |= {f"pdlmi.{name}" for name in public_method_files("pdlmi") | public_properties("pdlmi")}
    result |= {f"helper.{path.stem}" for path in (ROOT / "+helper").glob("*.m")}
    if (ROOT / "install_pd_lmi.m").exists():
        result.add("root.install_pd_lmi")
    return result


def remove_macro(text: str, name: str, arguments: int = 1) -> str:
    pattern = re.compile(r"\\" + re.escape(name) + r"(?:\[[^\]]*\])?" + r"\{[^{}]*\}" * arguments)
    previous = None
    while previous != text:
        previous = text
        text = pattern.sub(" ", text)
    return text


def strip_inline_math(text: str) -> str:
    text = re.sub(r"\\\(.*?\\\)", " ", text)
    text = re.sub(r"\$[^$]*\$", " ", text)
    return text


def author_prose(path: Path) -> list[tuple[int, str]]:
    result: list[tuple[int, str]] = []
    stack: list[str] = []
    display_math = False
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = re.sub(r"(?<!\\)%.*$", "", raw)
        begins = re.findall(r"\\begin\{([^}]+)\}", line)
        ends = re.findall(r"\\end\{([^}]+)\}", line)
        excluded_before = any(item in EXCLUDED_ENVIRONMENTS for item in stack)
        if line.strip() == r"\[":
            display_math = True
            continue
        if line.strip() == r"\]":
            display_math = False
            continue
        for environment in begins:
            stack.append(environment)
        excluded_now = excluded_before or display_math or any(item in EXCLUDED_ENVIRONMENTS for item in stack)
        if not excluded_now:
            cleaned = line
            for macro, arguments in (("codeerr", 2), ("code", 1), ("href", 2), ("url", 1), ("index", 1), ("label", 1), ("cite", 1)):
                cleaned = remove_macro(cleaned, macro, arguments)
            cleaned = strip_inline_math(cleaned)
            cleaned = re.sub(r"\\(?:cref|Cref|ref|pageref|hyperref)(?:\[[^\]]*\])?\{[^{}]*\}", " ", cleaned)
            cleaned = re.sub(r"\\(?:termdef|term)\{[^{}]*\}", " TERM ", cleaned)
            cleaned = re.sub(r"\\[A-Za-z@]+\*?(?:\[[^\]]*\])?", " ", cleaned)
            cleaned = cleaned.replace(r"\&", "and").replace("&", " ").replace(r"\\", " ")
            if re.search(r"[A-Za-z]", cleaned):
                result.append((number, cleaned.strip()))
        for environment in ends:
            if environment in stack:
                reverse_index = len(stack) - 1 - stack[::-1].index(environment)
                stack.pop(reverse_index)
    return result


def manual_files() -> list[Path]:
    return [DOC / "manual.tex", *(DOC / "chapters" / name for name in CHAPTER_ORDER)]


def audit_generated(errors: list[str]) -> None:
    if (DOC / "terminology.tex").read_text(encoding="utf-8") != generate_terminology.render():
        errors.append("terminology.tex is stale")
    if (DOC / "documentation-inventory.json").read_text(encoding="utf-8") != generate_inventory.render():
        errors.append("documentation-inventory.json is stale")
    if (DOC / "api-index.tex").read_text(encoding="utf-8") != generate_inventory.render_index():
        errors.append("api-index.tex is stale")


def audit_inventory(errors: list[str]) -> Counter:
    data = json.loads((DOC / "documentation-inventory.json").read_text(encoding="utf-8"))
    records = data.get("records", [])
    required = {"id", "owner", "symbol", "kind", "source_evidence", "test_evidence", "call_forms_options", "inputs", "return_type_shape", "validation_errors", "supported_scope", "tex_anchor", "tex_index", "tex_example_evidence", "web_route_or_anchor", "web_example_evidence", "executable_example"}
    ids = {record.get("id") for record in records}
    missing_ids = sorted(expected_ids() - ids)
    extra_ids = sorted(ids - expected_ids())
    if missing_ids:
        errors.append(f"inventory misses public ids: {missing_ids}")
    if extra_ids:
        errors.append(f"inventory has unexpected public ids: {extra_ids}")
    all_tex = "\n".join(path.read_text(encoding="utf-8") for path in manual_files())
    index_text = (DOC / "api-index.tex").read_text(encoding="utf-8")
    for record in records:
        absent = sorted(field for field in required if field not in record or record[field] in (None, "", []))
        if absent:
            errors.append(f"{record.get('id', '<unknown>')} misses fields: {absent}")
            continue
        source = ROOT / record["source_evidence"][0]
        if not source.exists():
            errors.append(f"{record['id']} source evidence is absent: {source.relative_to(ROOT)}")
        for test in record["test_evidence"]:
            if not (ROOT / test).exists():
                errors.append(f"{record['id']} test evidence is absent: {test}")
        if f"\\label{{{record['tex_anchor']}}}" not in all_tex:
            errors.append(f"{record['id']} TeX anchor is absent: {record['tex_anchor']}")
        if f"% inventory-id: {record['id']}" not in index_text:
            errors.append(f"{record['id']} generated TeX index evidence is absent")
        if "{member}" in record["tex_index"]:
            errors.append(f"{record['id']} has a templated TeX index")
        example_path = record["tex_example_evidence"].split("#", 1)[0]
        if not (ROOT / example_path).exists():
            errors.append(f"{record['id']} TeX example file is absent: {example_path}")
    return Counter(record["owner"] for record in records)


def audit_terminology(errors: list[str]) -> None:
    registry = json.loads((DOC / "terminology.json").read_text(encoding="utf-8"))
    required = {"id", "abbreviation", "expansion", "aliases", "tex_index_key", "web_definition_anchor", "auto_link"}
    terms = registry["terms"]
    for term in terms:
        absent = sorted(required - term.keys())
        if absent:
            errors.append(f"terminology {term.get('id', '<unknown>')} misses {absent}")
    reading = "\n".join((DOC / "manual.tex").read_text(encoding="utf-8").split(r"\begin{document}", 1)[-1].split(r"\include{chapters/release-history}", 1)[0:1])
    reading += "\n" + "\n".join((DOC / "chapters" / name).read_text(encoding="utf-8") for name in CHAPTER_ORDER)
    registered = {term["abbreviation"].upper(): term for term in terms}
    for term in terms:
        if term["auto_link"] and f"\\termdef{{{term['id']}}}" not in reading:
            errors.append(f"terminology {term['id']} has no first-use termdef")
        if term["auto_link"]:
            definition = reading.find(f"\\termdef{{{term['id']}}}")
            raw_match = re.search(r"(?<![A-Za-z0-9-])" + re.escape(term["abbreviation"]) + r"(?![A-Za-z0-9-])", reading)
            raw = raw_match.start() if raw_match else -1
            ordinary = reading.find(f"\\term{{{term['id']}}}")
            earlier = [position for position in (raw, ordinary) if position >= 0]
            if earlier and min(earlier) < definition:
                errors.append(f"terminology {term['id']} is used before termdef")
    prose = "\n".join(text for path in manual_files() for _, text in author_prose(path))
    for token in sorted(set(ACRONYM.findall(prose))):
        upper = token.upper()
        if upper in GENERAL_OR_EXTERNAL:
            continue
        if upper == "PSD-LMI":
            errors.append("unregistered composite acronym in author prose: PSD-LMI")
            continue
        if upper not in registered and token not in {"GriD-LMIA"}:
            errors.append(f"unregistered domain/package acronym in author prose: {token}")


def audit_tex(errors: list[str]) -> None:
    for path in manual_files():
        source = path.read_text(encoding="utf-8")
        for command in (r"\mathbf", r"\boldsymbol", r"\vec"):
            if re.search(re.escape(command) + r"(?![A-Za-z])", source):
                errors.append(f"{path.relative_to(ROOT)} uses legacy semantic vector command {command}")
        vector_source = source.replace(r"\newcommand{\vect}[1]{\boldsymbol{#1}}", "")
        for match in re.finditer(r"\vect(?!\{)", vector_source):
            line = vector_source.count("\n", 0, match.start()) + 1
            errors.append(f"{path.relative_to(ROOT)}:{line} uses unbraced semantic vector command")
        prose_lines = author_prose(path)
        for number, text in prose_lines:
            negative = NEGATIVE.search(text)
            if negative:
                errors.append(f"{path.relative_to(ROOT)}:{number} negative construction `{negative.group(0)}`")
            banned = BANNED.search(text)
            if banned:
                errors.append(f"{path.relative_to(ROOT)}:{number} banned promotional term `{banned.group(0)}`")
            if ";" in text:
                errors.append(f"{path.relative_to(ROOT)}:{number} semicolon in author prose")
        prose_numbers = {number for number, _ in prose_lines}
        source_lines = source.splitlines()
        for number in sorted(prose_numbers):
            if number + 1 in prose_numbers:
                first = source_lines[number - 1].strip()
                second = source_lines[number].strip()
                plain_first = bool(re.match(r"^[A-Z][^\\{}&]*[.!?]$", first))
                plain_second = bool(re.match(r"^[A-Z][^\\{}&]*", second))
                if plain_first and plain_second:
                    errors.append(f"{path.relative_to(ROOT)}:{number}-{number + 1} prose paragraph spans physical source lines")
    style = (DOC / "manual-style.tex").read_text(encoding="utf-8")
    if r"\newcommand{\vect}[1]{\boldsymbol{#1}}" not in style:
        errors.append("manual-style.tex misses the semantic vector definition")
    manual = (DOC / "manual.tex").read_text(encoding="utf-8")
    if "Version v1.3.2" not in manual:
        errors.append("manual metadata is not v1.3.2")
    history = (DOC / "chapters" / "release-history.tex").read_text(encoding="utf-8")
    if "v1.3.2" not in history:
        errors.append("release history misses v1.3.2")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the TeX manual against the generated API, terminology, notation, and prose contracts."
    )
    parser.parse_args()
    errors: list[str] = []
    audit_generated(errors)
    counts = audit_inventory(errors)
    audit_terminology(errors)
    audit_tex(errors)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"documentation audit failed with {len(errors)} finding(s)")
        return 1
    total = sum(counts.values())
    summary = ", ".join(f"{owner}={count}" for owner, count in sorted(counts.items()))
    print(f"documentation audit passed: {total} per-symbol API records ({summary})")
    print("terminology, first-use definitions, generated index evidence, semantic vectors, affirmative prose, and style checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
