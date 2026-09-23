"""Aggregate isolated MATLAB runs without pooling away process variation.

Use --self-test for deterministic gate checks. Final inputs are named
final-pair{1,2,3}-{baseline,candidate}.json. Optional corresponding
*-extended.json files replace only the cases measured again; original samples
remain in the retained evidence. No external Python packages are required.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import statistics


SEED = 20260922
DRAWS = 10000
RUNTIME = ("@pdbase", "@pdmat", "@pdvar", "@pdlmi", "+helper")


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def runtime_files(root):
    paths = [p for folder in RUNTIME for p in (root / folder).rglob("*.m")]
    paths.append(root / "install_pd_lmi.m")
    return {p.relative_to(root).as_posix(): digest(p) for p in sorted(paths)}


def interval(pairs, seed=SEED, draws=DRAWS):
    """Resample process pairs, then independent samples within each side."""
    med = statistics.median
    ratios = [med(candidate) / med(baseline) for baseline, candidate in pairs]
    rng = random.Random(seed)
    simulated = []
    for _ in range(draws):
        session_ratios = []
        for _ in pairs:
            baseline, candidate = pairs[rng.randrange(len(pairs))]
            baseline_indices = [rng.randrange(len(baseline)) for _ in baseline]
            candidate_indices = [rng.randrange(len(candidate)) for _ in candidate]
            session_ratios.append(
                med([candidate[i] for i in candidate_indices])
                / med([baseline[i] for i in baseline_indices])
            )
        simulated.append(med(session_ratios))
    simulated.sort()
    return med(ratios), simulated[int(.025 * draws)], simulated[int(.975 * draws)], ratios


def gate(upper, primary):
    return upper <= 1.05 and (not primary or upper < 1.0)


def verify_source_proofs(raw, before, after, harness_hash, manifest_hash):
    """Bind every measured process to its immutable source and harness."""
    roots = {"baseline": set(), "candidate": set()}
    for run in raw:
        variant = "baseline" if "-baseline" in run["File"] else "candidate"
        data = run["Data"]
        proof = data.get("SourceProof", {})
        expected = before if variant == "baseline" else after
        actual = {key: value.lower() for key, value in proof.get("RuntimeSHA256", {}).items()}
        if proof.get("VerifiedUnchanged") is not True or actual != expected:
            raise ValueError(f"Missing or mismatched immutable runtime proof: {run['File']}")
        if (proof.get("HarnessSHA256", "").lower() != harness_hash
                or proof.get("ManifestSHA256", "").lower() != manifest_hash):
            raise ValueError(f"Benchmark input proof differs: {run['File']}")
        root = Path(proof["SourceRoot"]).resolve()
        roots[variant].add(root)
        resolved = data.get("ResolvedSources", {})
        for key, relative in (("Pdvar", "@pdvar/pdvar.m"),
                              ("Benchmark", "+tests/+infrastructure/benchmark_operators.m")):
            if key not in resolved or Path(resolved[key]).resolve() != (root / relative).resolve():
                raise ValueError(f"MATLAB resolved a different {key} source: {run['File']}")
    if any(len(value) != 1 for value in roots.values()) or roots["baseline"] == roots["candidate"]:
        raise ValueError("Runs must use one distinct immutable snapshot per variant")


def load_runs(directory, names):
    sessions, retained = [], []
    environments = set()
    for pair in range(1, 4):
        sides = []
        for variant in ("baseline", "candidate"):
            stem = f"final-pair{pair}-{variant}"
            path = directory / f"{stem}.json"
            run = read_json(path)
            if run["Warmups"] != 3 or run["Repetitions"] != 7:
                raise ValueError(f"Unexpected measurement protocol: {path}")
            entries = {entry["Name"]: entry for entry in run["Cases"]}
            if len(entries) != len(run["Cases"]) or set(entries) != names:
                raise ValueError(f"Missing, duplicate or extra cases in {path}")
            retained.append({"File": path.name, "SHA256": digest(path), "Data": run})
            environments.add((run["Matlab"], run["Computer"], run["Threads"], run["Seed"]))
            extra = directory / f"{stem}-extended.json"
            if extra.exists():
                extension = read_json(extra)
                if extension["Warmups"] != 3 or extension["Repetitions"] != 21:
                    raise ValueError(f"Unexpected extension protocol: {extra}")
                retained.append({"File": extra.name, "SHA256": digest(extra), "Data": extension})
                environments.add((extension["Matlab"], extension["Computer"],
                                  extension["Threads"], extension["Seed"]))
                for entry in extension["Cases"]:
                    if entry["Name"] not in names or len(entry["Times"]) != 21:
                        raise ValueError(f"Invalid extension case in {extra}")
                    entries[entry["Name"]] = entry
            for entry in entries.values():
                if len(entry["Times"]) not in (7, 21) or not all(
                    math.isfinite(t) and t > 0 for t in entry["Times"]
                ):
                    raise ValueError(f"Invalid timings: {path.name}/{entry['Name']}")
            sides.append(entries)
        sessions.append(sides)
    if len(environments) != 1:
        raise ValueError("MATLAB/environment/threads/seed differ across runs")
    return sessions, retained, list(environments)[0]


def analyze(args):
    candidate = args.candidate_root.resolve()
    baseline = args.baseline_root.resolve()
    infrastructure = candidate / "+tests" / "+infrastructure"
    manifest_path = infrastructure / "operator_benchmark_manifest.json"
    manifest = read_json(manifest_path)
    names = {cfg["Name"] for cfg in manifest["Cases"]}
    sessions, raw, environment = load_runs(args.runs_dir, names)
    before, after = runtime_files(baseline), runtime_files(candidate)
    harness_hash = digest(infrastructure / "benchmark_operators.m")
    manifest_hash = digest(manifest_path)
    verify_source_proofs(raw, before, after, harness_hash, manifest_hash)
    rows = []
    for number, cfg in enumerate(manifest["Cases"]):
        name = cfg["Name"]
        for sides in sessions:
            for side in sides:
                entry = side[name]
                if any(entry[key] != cfg[key] for key in ("Batch", "Primary", "ValidComparison")):
                    raise ValueError(f"Case configuration differs from frozen manifest: {name}")
        pairs = [(sides[0][name]["Times"], sides[1][name]["Times"]) for sides in sessions]
        if any(len(a) != len(b) for a, b in pairs):
            raise ValueError(f"Unmatched repetitions: {name}")
        ratio, lower, upper, session_ratios = interval(pairs, SEED + number)
        valid = cfg["ValidComparison"]
        passed = gate(upper, cfg["Primary"]) if valid else None
        rows.append({"Name": name, "Primary": cfg["Primary"], "ValidComparison": valid,
                     "BaselineMedian": statistics.median(t for a, _ in pairs for t in a),
                     "CandidateMedian": statistics.median(t for _, b in pairs for t in b),
                     "BaselineRange": [min(t for a, _ in pairs for t in a),
                                       max(t for a, _ in pairs for t in a)],
                     "CandidateRange": [min(t for _, b in pairs for t in b),
                                        max(t for _, b in pairs for t in b)],
                     "Ratio": ratio, "Lower95": lower, "Upper95": upper,
                     "SessionRatios": session_ratios, "SamplesPerSession": [len(a) for a, _ in pairs],
                     "Passed": passed})
    changes = []
    for relative in sorted(before.keys() | after.keys()):
        if before.get(relative) != after.get(relative):
            changes.append({"Path": relative,
                            "Before": (baseline / relative).read_bytes().decode("utf-8")
                            if relative in before else None})
    evidence = {"Protocol": {"Seed": SEED, "BootstrapDraws": DRAWS,
                              "Interval": "Hierarchical process-paired percentile 95% with independent within-side resampling (2.5%,97.5%)",
                              "Estimator": "Median of three within-session median ratios",
                              "Order": ["B1", "C1", "C2", "B2", "B3", "C3"],
                              "MaximumUpperRatio": 1.05,
                              "PrimaryUpperRatioStrictlyBelow": 1.0},
                "Environment": environment, "Manifest": manifest,
                "ManifestSHA256": manifest_hash,
                "HarnessSHA256": harness_hash,
                "AnalyzerSHA256": digest(Path(__file__)),
                "LauncherSHA256": digest(infrastructure / "launch_operator_benchmarks.py"),
                "ManifestCorrection": "Unused descriptive fields in the three audited cases "
                    "were corrected to match their originally frozen hardcoded fixtures. "
                    "Case names, kinds, batches, primary flags and executed workloads did not change.",
                "BaselineSHA256": before, "CandidateSHA256": after,
                "BaselineReconstruction": changes, "Runs": raw, "Cases": rows,
                "Passed": all(row["Passed"] for row in rows if row["ValidComparison"])}
    args.output_prefix.with_suffix(".json").write_text(
        json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    lines = ["# Operator performance acceptance", "",
             f"Overall performance gate: **{'PASS' if evidence['Passed'] else 'NOT PASSED'}**.", "",
             f"MATLAB: {environment[0]}; platform: {environment[1]}; "
             f"computation threads: {environment[2]}; deterministic fixture seed: {environment[3]}.", "",
             "Three fresh-process pairs; three warm-ups and seven measured batches per case "
             "(21 when extended). Startup, fixtures, profiling and file output are excluded "
             "except for the explicitly fixture-inclusive pipeline.", "",
             "Ratios are candidate/baseline. Confidence intervals resample process pairs "
             "and independent repetition indices within each side, retaining between-process variation. Every "
             "valid case requires upper95 <= 1.05; each primary additionally requires "
             "upper95 < 1.00. Gains in other cases do not offset a failed gate.", "",
             "| Case | Baseline s | Candidate s | Ratio | 95% CI | Gate |",
             "|---|---:|---:|---:|---:|---|"]
    for row in rows:
        status = "correctness only" if row["Passed"] is None else "PASS" if row["Passed"] else "NOT PASSED"
        comparison = (f"{row['Ratio']:.4f} | [{row['Lower95']:.4f}, {row['Upper95']:.4f}]"
                      if row["ValidComparison"] else "excluded | excluded")
        lines.append(f"| {row['Name']} | {row['BaselineMedian']:.6g} | "
                     f"{row['CandidateMedian']:.6g} | {comparison} | {status} |")
    lines += ["", "Known-incorrect baseline discontinuity cases are excluded from speedup claims. "
              "These measurements cover the frozen manifest, not every possible workload or solver time.", "",
              evidence["ManifestCorrection"], "",
              "## Reproduction", "", "Run `tests.infrastructure.benchmark_operators` in isolated matching source snapshots "
              "in B1,C1,C2,B2,B3,C3 order; keep one MATLAB benchmark process active at a time. "
              "The adjacent JSON retains every run, sample, source hash and changed baseline source. "
              "Use this analyzer's `--reconstruct-baseline` option with the matching final source tree "
              "to reconstruct the old runtime and identical benchmark harness.", "",
              "The retained launcher enforces the process order, resolved MATLAB paths and "
              "unchanged source hashes for every run:", "", "```text",
              "python launch_operator_benchmarks.py --baseline BASELINE --candidate CANDIDATE "
              "--output RUNS --matlab MATLAB_EXECUTABLE", "```", "",
              "In each fresh MATLAB process, change to the intended snapshot, add that root to the "
              "path, and assert that `which('pdvar')` and `which('tests.infrastructure.benchmark_operators')` "
              "resolve there before running:", "", "```matlab",
              "tests.infrastructure.benchmark_operators(outputFile, 7)", "```", "",
              "Use filenames `final-pair1-baseline.json` through `final-pair3-candidate.json`. "
              "An inconclusive case is extended in all six processes using 21 repetitions and "
              "the same selected case names; save corresponding `*-extended.json` files.", "",
              "```text", "python analyze_operator_benchmarks.py --runs-dir RUNS "
              "--baseline-root BASELINE --candidate-root CANDIDATE --output-prefix REPORT",
              "```", ""]
    args.output_prefix.with_suffix(".md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"Passed": evidence["Passed"], "Cases": len(rows),
                      "Failed": [row["Name"] for row in rows if row["Passed"] is False]}))


def reconstruct(args):
    """Create a new isolated runtime; never overwrite an existing directory."""
    evidence = read_json(args.evidence)
    candidate, target = args.candidate_root.resolve(), args.reconstruct_baseline.resolve()
    if runtime_files(candidate) != evidence["CandidateSHA256"]:
        raise ValueError("Candidate source differs from retained evidence")
    infrastructure = candidate / "+tests" / "+infrastructure"
    for name, key in (("benchmark_operators.m", "HarnessSHA256"),
                      ("operator_benchmark_manifest.json", "ManifestSHA256")):
        if digest(infrastructure / name) != evidence[key]:
            raise ValueError(f"Candidate benchmark input differs from retained evidence: {name}")
    if target.exists():
        raise ValueError("Reconstruction target must not exist")
    replacements = {item["Path"]: item["Before"] for item in evidence["BaselineReconstruction"]}
    for relative in evidence["BaselineSHA256"]:
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError("Unsafe relative source path")
        destination = target / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        if relative in replacements:
            destination.write_bytes(replacements[relative].encode("utf-8"))
        else:
            destination.write_bytes((candidate / path).read_bytes())
    if runtime_files(target) != evidence["BaselineSHA256"]:
        raise ValueError("Reconstructed baseline does not match retained byte hashes")
    for name in ("benchmark_operators.m", "operator_benchmark_manifest.json"):
        relative = Path("+tests/+infrastructure") / name
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((candidate / relative).read_bytes())
    print(target)


def extract_runs(args):
    """Restore retained timing data into a new directory for reanalysis."""
    evidence = read_json(args.evidence)
    target = args.extract_runs.resolve()
    if target.exists():
        raise ValueError("Timing extraction target must not exist")
    for run in evidence["Runs"]:
        if Path(run["File"]).name != run["File"]:
            raise ValueError("Unsafe timing filename")
    target.mkdir(parents=True)
    for run in evidence["Runs"]:
        (target / run["File"]).write_text(json.dumps(run["Data"]), encoding="utf-8")
    print(target)


def self_test():
    pairs = [([1.] * 7, [.5] * 7)] * 3
    ratio, lower, upper, _ = interval(pairs, draws=1000)
    assert (ratio, lower, upper) == (.5, .5, .5)
    assert gate(upper, True)
    assert gate(1.05, False) and not gate(1.050001, False)
    assert not gate(1., True) and gate(.999, True)
    # Independent processes do not imply covariance between sample positions.
    varying = [([float(i) for i in range(1, 8)],
                [1.04 * i for i in range(1, 8)])] * 3
    _, low, high, _ = interval(varying, draws=1000)
    assert low < 1.04 < high and not gate(high, False)
    # Session variation must survive even when each session has no timing noise.
    varied = [([1.] * 7, [r] * 7) for r in (.9, 1., 1.2)]
    _, low, high, _ = interval(varied, draws=1000)
    assert low == .9 and high == 1.2 and not gate(high, False)
    raw = []
    for variant, source_hash in (("baseline", "abc"), ("candidate", "def")):
        root = Path(variant).resolve()
        raw.append({"File": f"final-pair1-{variant}.json", "Data": {
            "SourceProof": {"RuntimeSHA256": {"file.m": source_hash},
                            "HarnessSHA256": "123", "ManifestSHA256": "456",
                            "SourceRoot": str(root), "VerifiedUnchanged": True},
            "ResolvedSources": {"Pdvar": str(root / "@pdvar/pdvar.m"),
                                "Benchmark": str(root / "+tests/+infrastructure/benchmark_operators.m")}}})
    verify_source_proofs(raw, {"file.m": "abc"}, {"file.m": "def"}, "123", "456")
    raw[1]["Data"]["SourceProof"]["HarnessSHA256"] = "changed"
    try:
        verify_source_proofs(raw, {"file.m": "abc"}, {"file.m": "def"}, "123", "456")
    except ValueError:
        pass
    else:
        raise AssertionError("Changed measured benchmark input was accepted")
    print("Analyzer deterministic gate checks PASS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--runs-dir", type=Path)
    parser.add_argument("--baseline-root", type=Path)
    parser.add_argument("--candidate-root", type=Path)
    parser.add_argument("--output-prefix", type=Path)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--reconstruct-baseline", type=Path)
    parser.add_argument("--extract-runs", type=Path)
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.reconstruct_baseline:
        if args.evidence is None or args.candidate_root is None:
            parser.error("--reconstruct-baseline requires --evidence and --candidate-root")
        reconstruct(args)
    elif args.extract_runs:
        if args.evidence is None:
            parser.error("--extract-runs requires --evidence")
        extract_runs(args)
    else:
        if any(value is None for value in (args.runs_dir, args.baseline_root,
                                          args.candidate_root, args.output_prefix)):
            parser.error("analysis requires --runs-dir, --baseline-root, --candidate-root and --output-prefix")
        analyze(args)
