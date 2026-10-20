import sys, os
import numpy as np
from PIL import Image

N = 1024
OUT = sys.argv[1]

def face_dirs(face):
    u, v = np.meshgrid(np.linspace(-1, 1, N), np.linspace(-1, 1, N))
    one = np.ones_like(u)
    if face == 'px': d = (one, -v, -u)
    elif face == 'nz': d = (-u, -v, -one)
    elif face == 'nx': d = (-one, -v, u)
    elif face == 'pz': d = (u, -v, one)
    elif face == 'py': d = (u, one, v)
    elif face == 'ny': d = (u, -one, -v)
    d = np.stack(d, -1)
    return d / np.linalg.norm(d, axis=-1, keepdims=True)

def hash3(i, j, k, seed):
    h = (i * 374761393 + j * 668265263 + k * 2147483647 + seed * 1274126177) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = h ^ (h >> 16)
    return (h & 0xFFFFFF) / float(0xFFFFFF)

def vnoise(p, seed=0):
    i = np.floor(p).astype(np.int64)
    f = p - i
    f = f * f * (3 - 2 * f)
    r = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[..., 0] if dx else 1 - f[..., 0]) * (f[..., 1] if dy else 1 - f[..., 1]) * (f[..., 2] if dz else 1 - f[..., 2])
                r = r + w * hash3(i[..., 0] + dx, i[..., 1] + dy, i[..., 2] + dz, seed)
    return r

def fbm(p, octaves=5, seed=0):
    a, s, r = 0.5, 1.0, 0
    for o in range(octaves):
        r = r + a * vnoise(p * s, seed + o)
        s *= 2.03
        a *= 0.5
    return r

def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

def mix(a, b, t):
    return a + (b - a) * t[..., None]

THEMES = {
    'Day': dict(
        sun=(0.35, 0.85, 0.40), sun_col=(1.0, 0.96, 0.88), zenith=(0.22, 0.48, 0.92), mid=(0.45, 0.70, 0.98),
        horizon=(0.75, 0.88, 1.0), cloud_lit=(1.0, 1.0, 1.0), cloud_shade=(0.68, 0.76, 0.90),
        cover=0.50, glow=0.35, stars=0.0, disc=1.0, seed=11),
    'Morning': dict(
        sun=(-0.75, 0.30, 0.30), sun_col=(1.0, 0.82, 0.65), zenith=(0.38, 0.55, 0.92), mid=(0.70, 0.76, 0.95),
        horizon=(0.95, 0.82, 0.85), cloud_lit=(1.0, 0.86, 0.80), cloud_shade=(0.66, 0.62, 0.80),
        cover=0.52, glow=0.65, stars=0.0, disc=1.0, seed=23),
    'Sunset': dict(
        sun=(0.80, 0.16, 0.35), sun_col=(1.0, 0.68, 0.38), zenith=(0.22, 0.25, 0.58), mid=(0.80, 0.42, 0.45),
        horizon=(1.0, 0.62, 0.40), cloud_lit=(1.0, 0.62, 0.42), cloud_shade=(0.45, 0.28, 0.48),
        cover=0.48, glow=1.0, stars=0.0, disc=1.0, seed=37),
    'Sunrise': dict(
        sun=(-0.85, 0.12, 0.25), sun_col=(1.0, 0.74, 0.46), zenith=(0.14, 0.22, 0.56), mid=(0.52, 0.50, 0.80),
        horizon=(1.0, 0.74, 0.56), cloud_lit=(1.0, 0.72, 0.56), cloud_shade=(0.40, 0.36, 0.64),
        cover=0.50, glow=1.0, stars=0.0, disc=1.0, seed=63),
    'Night': dict(
        sun=(0.30, 0.80, -0.50), sun_col=(0.75, 0.82, 1.0), zenith=(0.010, 0.020, 0.075), mid=(0.020, 0.040, 0.130),
        horizon=(0.04, 0.07, 0.18), cloud_lit=(0.20, 0.26, 0.45), cloud_shade=(0.04, 0.06, 0.14),
        cover=0.58, glow=0.30, stars=1.0, disc=1.0, seed=51),
}

def render(face, T):
    d = face_dirs(face)
    y = d[..., 1]
    sun = np.array(T['sun']); sun = sun / np.linalg.norm(sun)
    sunc = np.array(T['sun_col'])
    zen, mid, hor = map(np.array, (T['zenith'], T['mid'], T['horizon']))

    e = np.clip(y, 0, 1)
    col = mix(np.broadcast_to(hor, d.shape).copy(), np.broadcast_to(mid, d.shape).copy(), smooth(0.0, 0.25, e) ** 0.8)
    col = mix(col, np.broadcast_to(zen, d.shape).copy(), smooth(0.2, 0.95, e) ** 0.9)
    below = smooth(0.0, -0.35, y)
    col = mix(col, np.broadcast_to(hor * 0.82, d.shape).copy(), below)

    cs = np.clip((d * sun).sum(-1), -1, 1)

    glow = (np.exp(-(1 - cs) * 9) * 0.55 + np.exp(-(1 - cs) * 60) * 0.9) * T['glow']
    col = col + glow[..., None] * sunc * (0.6 if T['stars'] else 1.0)

    if T['stars'] > 0:
        g = d * 180.0
        gi = np.floor(g).astype(np.int64)
        h = hash3(gi[..., 0], gi[..., 1], gi[..., 2], 7)
        fr = g - gi - 0.5
        dist = np.linalg.norm(fr, axis=-1)
        star = (h > 0.985) * np.clip(1 - dist * 2.4, 0, 1) ** 2 * (0.5 + 0.8 * hash3(gi[..., 0], gi[..., 1], gi[..., 2], 9))
        col = col + (star * smooth(-0.02, 0.15, y))[..., None] * np.array([0.9, 0.95, 1.0])
        band = fbm(d * 3.0 + 5, 4, 3)
        mw = np.exp(-((d * np.array([0.4, 0.2, 0.9])).sum(-1) ** 2) * 14) * band
        col = col + (mw * 0.12 * smooth(0.0, 0.2, y))[..., None] * np.array([0.5, 0.6, 1.0])

    h_ = np.clip(y, 0.0, 1) + 0.12
    p = np.stack([d[..., 0] / h_, d[..., 2] / h_, np.full_like(h_, 3.0)], -1) * 1.6
    dens = fbm(p + T['seed'], 6, T['seed'])
    dens2 = fbm(p + T['seed'] + sun[[0, 2, 1]] * 0.25, 6, T['seed'])
    c = smooth(T['cover'], T['cover'] + 0.22, dens)
    c = c * smooth(0.0, 0.10, y) * (1 - 0.0 * y)
    light = np.clip(0.55 + (dens - dens2) * 5.0, 0, 1)
    ccol = mix(np.broadcast_to(np.array(T['cloud_shade']), d.shape).copy(),
               np.broadcast_to(np.array(T['cloud_lit']), d.shape).copy(), light)
    ccol = ccol + (np.exp(-(1 - cs) * 14) * T['glow'] * 0.5)[..., None] * sunc * 0.6
    col = mix(col, ccol, c * 0.95)

    disc = smooth(0.99935 if T['stars'] == 0 else 0.9992, 0.9997, cs)
    discc = np.array([1.0, 0.98, 0.92]) if T['stars'] == 0 else np.array([0.88, 0.92, 1.0])
    if T['stars'] == 0:
        discc = np.minimum(1.0, sunc * 0.5 + 0.6)
    col = mix(col, np.broadcast_to(discc, d.shape).copy(), disc * (1 - c * 0.6))

    haze = np.exp(-np.abs(y) * 9) * 0.35
    col = mix(col, np.broadcast_to(hor, d.shape).copy(), haze * (0.7 if T['stars'] else 1.0))

    col = np.clip(col, 0, 1)
    return Image.fromarray((col * 255 + 0.5).astype(np.uint8))

for name, T in THEMES.items():
    if len(sys.argv) > 2 and name not in sys.argv[2:]:
        continue
    folder = os.path.join(OUT, f'{name}_Skybox', 'skyBoxes', 'default')
    os.makedirs(folder, exist_ok=True)
    for face in ['px', 'nx', 'py', 'ny', 'pz', 'nz']:
        render(face, T).save(os.path.join(folder, face + '.jpg'), quality=95)
    print('done', name)
