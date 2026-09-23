"""Run counterbalanced, isolated MATLAB benchmark processes with source proof.

Pass two frozen source roots, an output directory, and the MATLAB executable.
Use --repetitions 21 --names NAME ... to extend inconclusive cases; the original
seven-sample files remain intact. Fixture creation and hashes are not timed.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_proof(root):
    paths = [p for folder in ("@pdbase", "@pdmat", "@pdvar", "@pdlmi", "+helper")
             for p in (root / folder).rglob("*.m")]
    paths.append(root / "install_pd_lmi.m")
    infrastructure = root / "+tests" / "+infrastructure"
    return {
        "RuntimeSHA256": {p.relative_to(root).as_posix(): digest(p) for p in sorted(paths)},
        "HarnessSHA256": digest(infrastructure / "benchmark_operators.m"),
        "ManifestSHA256": digest(infrastructure / "operator_benchmark_manifest.json"),
        "SourceRoot": str(root),
    }


def matlab_string(value):
    return "'" + str(value).replace("'", "''") + "'"


def run(args):
    args.output.mkdir(parents=True, exist_ok=True)
    roots = {"baseline": args.baseline.resolve(), "candidate": args.candidate.resolve()}
    if roots["baseline"] == roots["candidate"]:
        raise ValueError("Use distinct frozen source roots")
    initial = {side: source_proof(root) for side, root in roots.items()}
    for key in ("HarnessSHA256", "ManifestSHA256"):
        if initial["baseline"][key] != initial["candidate"][key]:
            raise ValueError(f"Mismatched {key}")
    manifest = json.loads((roots["candidate"] / "+tests/+infrastructure/operator_benchmark_manifest.json").read_text())
    expected = set(args.names or [case["Name"] for case in manifest["Cases"]])
    if not expected <= {case["Name"] for case in manifest["Cases"]}:
        raise ValueError("Unknown requested cases")
    order = ((1, "baseline"), (1, "candidate"), (2, "candidate"),
             (2, "baseline"), (3, "baseline"), (3, "candidate"))
    for pair, side in order:
        root = roots[side]
        proof = source_proof(root)
        if proof != initial[side]:
            raise RuntimeError("Snapshot changed between processes")
        suffix = "-extended" if args.repetitions == 21 else ""
        stem = f"final-pair{pair}-{side}{suffix}"
        output = (args.output / (stem + ".json")).resolve()
        if output.exists():
            raise FileExistsError(output)
        selected = "{" + ",".join(matlab_string(name) for name in args.names) + "}"
        command = (
            f"clear classes; cd({matlab_string(root)}); addpath(pwd); "
            "assert(strcmp(which('pdvar'),fullfile(pwd,'@pdvar','pdvar.m'))); "
            "assert(strcmp(which('tests.infrastructure.benchmark_operators'),"
            "fullfile(pwd,'+tests','+infrastructure','benchmark_operators.m'))); "
            f"r=tests.infrastructure.benchmark_operators({matlab_string(output)},"
            f"{args.repetitions},{selected}); "
            "r.ResolvedSources=struct('Pdvar',which('pdvar'),'Benchmark',"
            "which('tests.infrastructure.benchmark_operators')); "
            f"f=fopen({matlab_string(output)},'w'); assert(f>=0); "
            "fprintf(f,'%s',jsonencode(r,PrettyPrint=true)); fclose(f);"
        )
        proof["StartedUTC"] = datetime.now(timezone.utc).isoformat()
        print(f"START {stem} {proof['StartedUTC']}", flush=True)
        subprocess.run([str(args.matlab), "-wait", "-logfile",
                        str((args.output / (stem + ".log")).resolve()), "-batch", command],
                       cwd=root, check=True)
        if source_proof(root) != initial[side]:
            raise RuntimeError("Snapshot changed during measurement")
        data = json.loads(output.read_text(encoding="utf-8-sig"))
        if isinstance(data["Cases"], dict):
            data["Cases"] = [data["Cases"]]
        if {case["Name"] for case in data["Cases"]} != expected:
            raise RuntimeError("Incomplete case set")
        proof["FinishedUTC"] = datetime.now(timezone.utc).isoformat()
        proof["VerifiedUnchanged"] = True
        data["SourceProof"] = proof
        output.write_text(json.dumps(data, indent=2), encoding="utf-8")
        print(f"FINISH {stem} {proof['FinishedUTC']}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--matlab", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, choices=(7, 21), default=7)
    parser.add_argument("--names", nargs="*", default=[])
    run(parser.parse_args())
