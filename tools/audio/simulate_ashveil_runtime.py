import random, json, math

# Use same curve control points as in controller defaults
roar_vol_pts = [(0.0,0.0),(0.5,0.12),(0.75,0.6),(0.9,0.7),(1.0,1.0)]
roar_pitch_pts = [(0.0,0.0),(0.5,0.48),(1.0,1.0)]
creak_vol_pts = [(0.0,0.0),(0.4,0.35),(0.7,0.75),(1.0,1.0)]
creak_pitch_pts = [(0.0,0.0),(0.8,0.03),(1.0,0.12)]

roar_db_range = (-20.0, -9.0)
creak_db_range = (-20.0, -10.0)
roar_pitch_range = (0.8, 1.05)
creak_pitch_range = (0.95, 1.05)

min_roar_interval = 22.0
max_roar_interval = 55.0
min_creak_interval = 6.0
max_creak_interval = 14.0

timing_intensity_bias = 0.35

# load bindings
with open('c:/Users/Hunter/Repos/Cell/tools/audio/autobind_result.json','r', encoding='utf-8-sig') as f:
    mapping = json.load(f)

players_roar = ['CollapsePlayer1']
players_creak = ['MidPlayer1','MidPlayer2']
players_event = ['EventPlayer1']
base_player = 'BasePlayer'

# helpers
def sample_curve(pts, t):
    if t <= pts[0][0]:
        return pts[0][1]
    for i in range(1,len(pts)):
        x0,y0 = pts[i-1]
        x1,y1 = pts[i]
        if t <= x1:
            u = (t - x0) / (x1 - x0) if x1!=x0 else 0
            return y0 + (y1 - y0) * u
    return pts[-1][1]

def map_range(val, a, b):
    return a + (b-a)*val

# deterministic RNG
rng = random.Random(42)

# Simulate intensity timeline: low -> ramp -> high -> hold -> decay
def intensity_at(t):
    # timeline: 0-20 low(0.1), 20-40 ramp to 0.8, 40-80 hold 0.9, 80-110 decay to 0.2
    if t < 20:
        return 0.1
    if t < 40:
        return 0.1 + (t-20)/20 * (0.8 - 0.1)
    if t < 80:
        return 0.9
    if t < 110:
        return 0.9 - (t-80)/30 * (0.7)
    return 0.2

# scheduling
time = 0.0
end_time = 120.0
next_roar = time + rng.uniform(min_roar_interval, max_roar_interval)
next_creak = time + rng.uniform(min_creak_interval, max_creak_interval)
log = []

while time <= end_time:
    intensity = intensity_at(time)
    # adjust intervals by timing bias
    # we will check events at current time
    if time >= next_creak - 1e-6:
        # pick creak player
        p = rng.choice(players_creak)
        cv = sample_curve(creak_vol_pts, intensity)
        cp = sample_curve(creak_pitch_pts, intensity)
        creak_db = map_range(cv, creak_db_range[0], creak_db_range[1])
        creak_pitch = map_range(cp, creak_pitch_range[0], creak_pitch_range[1])
        log.append({'time': round(time,2), 'type':'CREAK', 'player': p, 'db': round(creak_db,2), 'pitch': round(creak_pitch,3), 'intensity': round(intensity,3)})
        shrink = max(0.3, 1.0 - intensity * timing_intensity_bias * 0.5)
        next_creak = time + rng.uniform(min_creak_interval*shrink, max_creak_interval*shrink)
    if time >= next_roar - 1e-6:
        p = rng.choice(players_roar)
        rv = sample_curve(roar_vol_pts, intensity)
        rp = sample_curve(roar_pitch_pts, intensity)
        roar_db = map_range(rv, roar_db_range[0], roar_db_range[1])
        roar_pitch = map_range(rp, roar_pitch_range[0], roar_pitch_range[1])
        log.append({'time': round(time,2), 'type':'ROAR', 'player': p, 'db': round(roar_db,2), 'pitch': round(roar_pitch,3), 'intensity': round(intensity,3)})
        shrink = max(0.2, 1.0 - intensity * timing_intensity_bias)
        next_roar = time + rng.uniform(min_roar_interval*shrink, max_roar_interval*shrink)
    time += 1.0

# print summary
print('Simulated events:')
for e in log:
    print(e)

# Simple analysis: count events by phase
phases = {'low':0,'ramp':0,'hold':0,'decay':0}
for e in log:
    t = e['time']
    if t < 20:
        phases['low'] += 1
    elif t < 40:
        phases['ramp'] += 1
    elif t < 80:
        phases['hold'] += 1
    elif t < 110:
        phases['decay'] += 1
    else:
        phases['low'] += 1
print('\nEvent counts by phase:', phases)

# Show bindings
print('\nBindings used:')
for k in mapping:
    print(k, '->', mapping[k].split('\\')[-1])
