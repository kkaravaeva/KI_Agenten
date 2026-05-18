import json, re

with open('v16_metrics.json') as f:
    data = json.load(f)

steps_data = {}
with open('v16_steps.log') as f:
    for line in f:
        m = re.search(r'Step:\s*(\d+)\.\s*Time Elapsed:\s*([\d.]+)\s*s\.\s*Mean Reward:\s*(-?\d+\.\d+)\.\s*Std of Reward:\s*(\d+\.\d+)', line)
        if m:
            steps_data[int(m.group(1))] = {
                'time': float(m.group(2)),
                'mean_reward': float(m.group(3)),
                'std_reward': float(m.group(4))
            }

all_steps = sorted(steps_data.keys())
total_steps = all_steps[-1]
total_time = steps_data[total_steps]['time']
steps_per_sec = total_steps / total_time

def get(tag, step):
    if tag not in data: return None
    for s, v in data[tag]:
        if s == step:
            return v
    return None

out = []
out.append('# v16 Training Snapshot Report')
out.append('')
out.append(f'**Run-ID:** v16  |  **Config:** labyrinth_transformer.yaml  |  **Builds:** 6 headless --no-graphics')
out.append(f'**Stand:** Step {total_steps:,} nach {total_time:.0f}s ({total_time/60:.1f} min)')
out.append(f'**Throughput:** {steps_per_sec:.0f} steps/s (gesamt)')
out.append(f'**Datenpunkte:** {len(all_steps)} Summary-Flushes (alle 20k Steps)')
out.append('')

out.append('## 1. Reward-Verlauf (Mean Reward aus Log)')
out.append('| Step | Time (s) | Mean Reward | Std Reward |')
out.append('|---:|---:|---:|---:|')
for s in all_steps:
    d = steps_data[s]
    out.append(f'| {s:>7,} | {d["time"]:.1f} | {d["mean_reward"]:+.3f} | {d["std_reward"]:.3f} |')
out.append('')

out.append('## 2. Reward-Komponenten (Decomposition pro Episode)')
reward_tags = ['Reward/Goal', 'Reward/Death', 'Reward/Timeout', 'Reward/Step', 'Reward/PBRS', 'Reward/LavaJump', 'Reward/LavaCross', 'Reward/WallClimb']
out.append('| Step | ' + ' | '.join([t.replace('Reward/','') for t in reward_tags]) + ' |')
out.append('|---:|' + '---:|'*len(reward_tags))
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in reward_tags:
        v = get(tag, s)
        row.append(f'{v:+.3f}' if v is not None else '-')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

out.append('## 3. Curriculum & SuccessRate')
out.append('| Step | Phase | Sampled | SuccessRate | SR_P0 | EMA_P0 | SR_P1 | EMA_P1 |')
out.append('|---:|---:|---:|---:|---:|---:|---:|---:|')
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in ['Custom/CurriculumPhase','Custom/CurriculumPhaseSampled','Custom/SuccessRate','Custom/SuccessRate_P0','Custom/SuccessRateEMA_P0','Custom/SuccessRate_P1','Custom/SuccessRateEMA_P1']:
        v = get(tag, s)
        row.append(f'{v:.3f}' if v is not None else '-')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

out.append('## 4. Episoden-Metriken')
out.append('| Step | Episode Length | TerminalReason | PathDist Init | PathDist Final | PathDist Delta |')
out.append('|---:|---:|---:|---:|---:|---:|')
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in ['Environment/Episode Length','Custom/TerminalReason','Custom/PathDistInit','Custom/PathDistFinal','Custom/PathDistDelta']:
        v = get(tag, s)
        row.append(f'{v:.3f}' if v is not None else '-')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

out.append('## 5. Lava-Verhalten (Custom Metrics)')
out.append('| Step | JumpsTotal | JumpsNearLava | LJ Attempts | LJ Successful | LJ Failed |')
out.append('|---:|---:|---:|---:|---:|---:|')
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in ['Custom/JumpsTotal','Custom/JumpsNearLava','Custom/LavaJumps/Attempted','Custom/LavaJumps/Successful','Custom/LavaJumps/Failed']:
        v = get(tag, s)
        row.append(f'{v:.3f}' if v is not None else '-')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

out.append('## 6. Policy & Losses (ab Step 80k)')
out.append('| Step | Entropy | Policy Loss | Value Loss | Curio Fwd | Curio Inv | LR | Beta | Epsilon |')
out.append('|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in ['Policy/Entropy','Losses/Policy Loss','Losses/Value Loss','Losses/Curiosity Forward Loss','Losses/Curiosity Inverse Loss','Policy/Learning Rate','Policy/Beta','Policy/Epsilon']:
        v = get(tag, s)
        if v is None:
            row.append('-')
        elif tag == 'Policy/Learning Rate':
            row.append(f'{v:.2e}')
        else:
            row.append(f'{v:.4f}')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

out.append('## 7. Value Estimates & Curiosity')
out.append('| Step | Extrinsic Reward | Extrinsic V-Est | Curiosity Reward | Curiosity V-Est |')
out.append('|---:|---:|---:|---:|---:|')
for s in all_steps:
    row = [f'{s:>7,}']
    for tag in ['Policy/Extrinsic Reward','Policy/Extrinsic Value Estimate','Policy/Curiosity Reward','Policy/Curiosity Value Estimate']:
        v = get(tag, s)
        row.append(f'{v:+.4f}' if v is not None else '-')
    out.append('| ' + ' | '.join(row) + ' |')
out.append('')

with open('v16_snapshot.md','w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print(f'Written: v16_snapshot.md ({len(out)} lines)')
