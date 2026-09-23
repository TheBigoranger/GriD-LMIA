"""Recheck the 18 original failed gates without replacing historical results.

Reconstruct the retained dirty baseline, verify the unchanged candidate, and
use the existing launcher for three new counterbalanced process pairs. Keep
all new samples and logs in a separate evidence file. Remove the explicitly
chosen temporary snapshot directory only after verifying that evidence.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import runpy
from types import SimpleNamespace


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshots', type=Path, required=True)
    parser.add_argument('--matlab', type=Path, required=True)
    args = parser.parse_args()
    infrastructure = Path(__file__).resolve().parent
    project = infrastructure.parent.parent
    analysis = runpy.run_path(str(infrastructure / 'analyze_operator_benchmarks.py'))
    launcher = runpy.run_path(str(infrastructure / 'launch_operator_benchmarks.py'))
    original_path = infrastructure / 'operator_benchmark_20260922.json'
    original = analysis['read_json'](original_path)
    failed = [case['Name'] for case in original['Cases'] if case['Passed'] is False]
    assert len(failed) == 18
    assert analysis['runtime_files'](project) == original['CandidateSHA256']
    target = args.snapshots.resolve()
    if target.exists():
        raise ValueError('Use a new task-owned temporary directory')
    output = infrastructure / 'operator_recheck_20260922.json'
    if output.exists():
        raise FileExistsError(output)
    target.mkdir(parents=True)
    baseline, candidate = target / 'baseline', target / 'candidate'
    analysis['reconstruct'](SimpleNamespace(
        evidence=original_path, candidate_root=project, reconstruct_baseline=baseline))
    for relative in original['CandidateSHA256']:
        destination = candidate / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((project / relative).read_bytes())
    for name in ('benchmark_operators.m', 'operator_benchmark_manifest.json'):
        destination = candidate / '+tests/+infrastructure' / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((infrastructure / name).read_bytes())
    launcher['run'](SimpleNamespace(baseline=baseline, candidate=candidate,
        output=target / 'runs', matlab=args.matlab, repetitions=21, names=failed))
    raw, sides, environment = [], {}, set()
    for pair in range(1, 4):
        for side in ('baseline', 'candidate'):
            path = target / 'runs' / f'final-pair{pair}-{side}-extended.json'
            data = analysis['read_json'](path)
            assert data['Warmups'] == 3 and data['Repetitions'] == 21
            assert {case['Name'] for case in data['Cases']} == set(failed)
            environment.add((data['Matlab'], data['Computer'], data['Threads'], data['Seed']))
            raw.append({'File': path.name, 'SHA256': analysis['digest'](path), 'Data': data,
                        'Log': path.with_suffix('.log').read_text(encoding='utf-8-sig')})
            sides[pair, side] = {case['Name']: case for case in data['Cases']}
    assert len(environment) == 1
    analysis['verify_source_proofs'](raw, original['BaselineSHA256'],
        original['CandidateSHA256'], original['HarnessSHA256'], original['ManifestSHA256'])
    rows = []
    manifest = original['Manifest']['Cases']
    for index, cfg in enumerate(manifest):
        if cfg['Name'] not in failed:
            continue
        pairs = []
        for pair in range(1, 4):
            entries = [sides[pair, side][cfg['Name']] for side in ('baseline', 'candidate')]
            for entry in entries:
                assert len(entry['Times']) == 21
                assert all(entry[key] == cfg[key] for key in ('Batch', 'Primary', 'ValidComparison'))
                assert all(0 < value < float('inf') for value in entry['Times'])
            pairs.append(tuple(entry['Times'] for entry in entries))
        ratio, lower, upper, session_ratios = analysis['interval'](
            pairs, seed=analysis['SEED'] + index)
        rows.append({'Name': cfg['Name'], 'Ratio': ratio, 'Lower95': lower,
                     'Upper95': upper, 'SessionRatios': session_ratios,
                     'PassedOriginalGate': analysis['gate'](upper, cfg['Primary']),
                     'ClearImprovement': upper < 1})
    assert analysis['runtime_files'](project) == original['CandidateSHA256']
    latest = {row['Name']: row for row in rows}
    counts = {'ValidCases': 0, 'OriginalGatePasses': 0, 'ClearImprovements': 0,
              'PointEstimateImprovements': 0, 'IntervalsEntirelyAbove105': []}
    for old in original['Cases']:
        if not old['ValidComparison']:
            continue
        case = latest.get(old['Name'], old)
        counts['ValidCases'] += 1
        counts['OriginalGatePasses'] += int(case['Upper95'] <= 1.05)
        counts['ClearImprovements'] += int(case['Upper95'] < 1)
        counts['PointEstimateImprovements'] += int(case['Ratio'] < 1)
        if case['Lower95'] > 1.05:
            counts['IntervalsEntirelyAbove105'].append(case['Name'])
    evidence = {'CreatedUTC': datetime.now(timezone.utc).isoformat(),
        'OriginalEvidenceSHA256': analysis['digest'](original_path),
        'RunnerSHA256': analysis['digest'](Path(__file__)),
        'RunnerSource': Path(__file__).read_text(encoding='utf-8'),
        'Protocol': 'Supplemental recheck only: original frozen cases and batches; '
            'B1,C1,C2,B2,B3,C3; 3 warmups; 21 measurements; unchanged bootstrap and seeds. '
            'Historical failures remain retained. Counts use the latest recheck for all 18 '
            'selected cases, including worse results, and historical results for other cases. '
            'Selection was based on original failure, so counts are descriptive, not a new '
            'simultaneous statistical guarantee.',
        'Environment': list(environment)[0], 'Runs': raw, 'Cases': rows,
        'CandidateRuntimeUnchanged': True, 'LatestEvidenceCounts': counts}
    output.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'Output': str(output), 'Counts': counts}), flush=True)


if __name__ == '__main__':
    main()
