from math import isnan
# Default curve points
roar_vol_pts = [(0.0,0.0),(0.5,0.12),(0.75,0.6),(0.9,0.85),(1.0,1.0)]
roar_pitch_pts = [(0.0,0.0),(0.5,0.48),(1.0,1.0)]
creak_vol_pts = [(0.0,0.0),(0.4,0.45),(0.7,0.75),(1.0,1.0)]
creak_pitch_pts = [(0.0,0.0),(0.8,0.03),(1.0,0.12)]

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

def map_range(val, r0, r1):
    return r0 + (r1 - r0) * val

print('Preview tuning sweep (t, roar_db, roar_pitch, creak_db, creak_pitch)')
steps = 6
for i in range(steps):
    t = float(i) / float(max(1, steps-1))
    rv = sample_curve(roar_vol_pts, t)
    rp = sample_curve(roar_pitch_pts, t)
    cv = sample_curve(creak_vol_pts, t)
    cp = sample_curve(creak_pitch_pts, t)
    roar_db = map_range(rv, -18.0, -6.0)
    roar_pitch = map_range(rp, 0.8,1.1)
    creak_db = map_range(cv, -20.0,-10.0)
    creak_pitch = map_range(cp, 0.95,1.05)
    print(f"t={t:.2f} -> roar_db={roar_db:.2f} dB, roar_pitch={roar_pitch:.3f}, creak_db={creak_db:.2f} dB, creak_pitch={creak_pitch:.3f}")

# Show binding mapping (from earlier simulation file)
import json
with open(r'c:\Users\Hunter\Repos\Cell\tools\audio\autobind_result.json','r') as f:
    mapping = json.load(f)
print('\nAuto-bind mapping simulation:')
for k in mapping:
    print(f"{k} -> {mapping[k].split('\\')[-1]}")