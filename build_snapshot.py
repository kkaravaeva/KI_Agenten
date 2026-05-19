"""Snapshot-Generator: parsed events.out.tfevents.* + Step-Log und erstellt Markdown-Report.

Usage: python build_snapshot.py <run-id> [--log <pfad-zur-training-log>]
"""
import json, re, sys, os
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

run_id = sys.argv[1] if len(sys.argv) > 1 else 'v16'
log_path = None
if '--log' in sys.argv:
    log_path = sys.argv[sys.argv.index('--log') + 1]

tb_path = f'results/{run_id}/LabyrinthNavigator'
if not os.path.isdir(tb_path):
    print(f'FEHLER: {tb_path} nicht gefunden')
    sys.exit(1)

ea = EventAccumulator(tb_path, size_guidance={'scalars': 0})
ea.Reload()
data = {tag: [(e.step, e.value) for e in ea.Scalars(tag)] for tag in ea.Tags()['scalars']}

with open(f'{run_id}_metrics.json', 'w') as f:
    json.dump(data, f, indent=2)

steps_data = {}
if log_path and os.path.isfile(log_path):
    with open(log_path) as f:
        for line in f:
            m = re.search(r'Step:\s*(\d+)\.\s*Time Elapsed:\s*([\d.]+)\s*s\.\s*Mean Reward:\s*(-?\d+\.\d+)\.\s*Std of Reward:\s*(\d+\.\d+)', line)
            if m:
                steps_data[int(m.group(1))] = {
                    'time': float(m.group(2)),
                    'mean_reward': float(m.group(3)),
                    'std_reward': float(m.group(4))
                }

all_steps = sorted({s for tag, lst in data.items() for s, _ in lst})

def get(tag, step):
    for s, v in data.get(tag, []):
        if s == step: return v
    return None

out = [f'# {run_id} Training Snapshot Report\n']
if all_steps:
    out.append(f'**Stand:** Step {all_steps[-1]:,}  |  Datenpunkte: {len(all_steps)}\n')

if steps_data:
    out.append('## 1. Reward-Verlauf (Log)')
    out.append('| Step | Time(s) | Mean Reward | Std Reward |')
    out.append('|---:|---:|---:|---:|')
    for s in sorted(steps_data):
        d = steps_data[s]
        out.append(f'| {s:,} | {d["time"]:.1f} | {d["mean_reward"]:+.3f} | {d["std_reward"]:.3f} |')
    out.append('')

groups = {
    '2. Reward-Komponenten': ['Reward/Goal','Reward/Death','Reward/Timeout','Reward/Step','Reward/PBRS','Reward/LavaJump','Reward/LavaCross','Reward/WallClimb'],
    '3. Curriculum & SuccessRate': ['Custom/CurriculumPhase','Custom/CurriculumPhaseSampled','Custom/SuccessRate','Custom/SuccessRate_P0','Custom/SuccessRateEMA_P0','Custom/SuccessRate_P1','Custom/SuccessRateEMA_P1'],
    '4. Episoden': ['Environment/Episode Length','Custom/TerminalReason','Custom/PathDistInit','Custom/PathDistFinal','Custom/PathDistDelta'],
    '5. Lava-Verhalten': ['Custom/JumpsTotal','Custom/JumpsNearLava','Custom/LavaJumps/Attempted','Custom/LavaJumps/Successful','Custom/LavaJumps/Failed'],
    '6. Policy & Losses': ['Policy/Entropy','Losses/Policy Loss','Losses/Value Loss','Losses/Curiosity Forward Loss','Losses/Curiosity Inverse Loss','Policy/Learning Rate','Policy/Beta','Policy/Epsilon'],
    '7. Value Estimates & Curiosity': ['Policy/Extrinsic Reward','Policy/Extrinsic Value Estimate','Policy/Curiosity Reward','Policy/Curiosity Value Estimate'],
}
for title, tags in groups.items():
    out.append(f'## {title}')
    out.append('| Step | ' + ' | '.join(t.split('/')[-1] for t in tags) + ' |')
    out.append('|---:|' + '---:|' * len(tags))
    for s in all_steps:
        row = [f'{s:,}']
        for tag in tags:
            v = get(tag, s)
            row.append(f'{v:.4f}' if v is not None else '-')
        out.append('| ' + ' | '.join(row) + ' |')
    out.append('')

with open(f'{run_id}_snapshot.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print(f'Written: {run_id}_snapshot.md ({len(out)} lines)')
print(f'Written: {run_id}_metrics.json')
