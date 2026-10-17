const CYCLE_SECONDS: f32 = 1200.0;
const START_LOOK: f32 = 3.0;
const HOLD: f32 = 0.35;

const USE_GAME_SUN: bool = true;
const SUN_EAST: vec3f = vec3f(1.0, 0.0, 0.0);

const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_SHIFT: f32 = 0.0;
const FACE_SHADOW: f32 = 1.0;

const BLOCK_SHINE: f32 = 0.20;
const BLOCK_SHINE_POWER: f32 = 40.0;

const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);
const LOOKS: i32 = 5;

struct Look {
    sun: vec3f,
    sunColour: vec3f,
    sky: vec3f,
    warm: vec3f,
    fog: vec3f,
    water: vec3f,
    waterReflect: vec3f,
    shadeMin: f32,
    exposure: f32,
    direct: f32,
    saturation: f32,
    fogMix: f32,
    blockBoost: f32,
    glintPower: f32,
    glintStrength: f32,
    glare: f32,
    shStrength: f32,
    shLow: f32,
    shHigh: f32,
    shColour: vec3f,
}

fn lookAt(i: i32) -> Look {
    var k: Look;
    switch i {
        case 0: {
            k = Look(
                vec3f(0.30, 0.80, -0.50), vec3f(0.60, 0.70, 1.00), vec3f(0.72, 0.80, 1.00), vec3f(0.85, 0.92, 1.08),
                vec3f(0.04, 0.07, 0.18), vec3f(0.03, 0.08, 0.22), vec3f(0.15, 0.20, 0.38),
                0.75, 0.95, 0.08, 0.95, 0.60, 0.60, 48.0, 0.6, 0.05,
                0.30, 12.8, 14.2, vec3f(0.78, 0.82, 0.98));
        }
        case 1: {
            k = Look(
                vec3f(-0.85, 0.12, 0.25), vec3f(1.00, 0.74, 0.46), vec3f(0.78, 0.80, 1.00), vec3f(1.18, 0.95, 0.76),
                vec3f(1.00, 0.74, 0.58), vec3f(0.22, 0.55, 0.78), vec3f(1.00, 0.70, 0.55),
                0.48, 0.95, 0.45, 1.15, 0.45, 0.30, 40.0, 1.6, 0.35,
                0.90, 14.30, 14.98, vec3f(0.62, 0.58, 0.82));
        }
        case 2: {
            k = Look(
                vec3f(-0.75, 0.30, 0.30), vec3f(1.00, 0.82, 0.65), vec3f(0.85, 0.90, 1.00), vec3f(1.10, 0.98, 0.88),
                vec3f(0.95, 0.82, 0.85), vec3f(0.20, 0.70, 0.85), vec3f(0.95, 0.85, 0.85),
                0.55, 1.00, 0.30, 1.10, 0.40, 0.30, 32.0, 1.3, 0.40,
                0.95, 13.90, 14.80, vec3f(0.62, 0.66, 0.88));
        }
        case 3: {
            k = Look(
                vec3f(0.35, 0.85, 0.40), vec3f(1.00, 0.96, 0.88), vec3f(0.82, 0.90, 1.00), vec3f(1.08, 1.03, 0.94),
                vec3f(0.75, 0.88, 1.00), vec3f(0.10, 0.75, 0.95), vec3f(0.70, 0.85, 1.00),
                0.55, 1.00, 0.25, 1.15, 0.30, 0.30, 24.0, 1.5, 0.50,
                1.00, 13.40, 14.60, vec3f(0.56, 0.63, 0.84));
        }
        default: {
            k = Look(
                vec3f(0.80, 0.16, 0.35), vec3f(1.00, 0.68, 0.38), vec3f(0.80, 0.85, 1.00), vec3f(1.15, 0.92, 0.72),
                vec3f(1.00, 0.62, 0.40), vec3f(0.12, 0.40, 0.62), vec3f(0.95, 0.45, 0.30),
                0.45, 1.00, 0.40, 1.00, 0.35, 0.30, 48.0, 1.6, 0.25,
                0.95, 14.30, 14.98, vec3f(0.68, 0.50, 0.74));
        }
    }
    return k;
}

fn mixLook(a: Look, b: Look, t: f32) -> Look {
    return Look(
        mix(a.sun, b.sun, t), mix(a.sunColour, b.sunColour, t), mix(a.sky, b.sky, t), mix(a.warm, b.warm, t),
        mix(a.fog, b.fog, t), mix(a.water, b.water, t), mix(a.waterReflect, b.waterReflect, t),
        mix(a.shadeMin, b.shadeMin, t), mix(a.exposure, b.exposure, t), mix(a.direct, b.direct, t),
        mix(a.saturation, b.saturation, t), mix(a.fogMix, b.fogMix, t), mix(a.blockBoost, b.blockBoost, t),
        mix(a.glintPower, b.glintPower, t), mix(a.glintStrength, b.glintStrength, t), mix(a.glare, b.glare, t),
        mix(a.shStrength, b.shStrength, t), mix(a.shLow, b.shLow, t), mix(a.shHigh, b.shHigh, t),
        mix(a.shColour, b.shColour, t));
}

fn lookBlend(p: f32) -> Look {
    let i0 = i32(floor(p)) % LOOKS;
    let i1 = (i0 + 1) % LOOKS;
    let t = smoothstep(0.0, 1.0, fract(p));
    return mixLook(lookAt(i0), lookAt(i1), t);
}

fn clockPhase() -> f32 {
    let q = bloxdTime() / CYCLE_SECONDS * f32(LOOKS) + START_LOOK;
    let k = floor(q);
    return k + smoothstep(HOLD, 1.0 - HOLD, fract(q));
}

const A_SUNRISE: f32 = 0.10;
const A_MORNING: f32 = 0.45;
const A_DAY: f32 = 1.20;
const A_DAY_END: f32 = 2.05;
const A_SUNSET: f32 = 2.80;

fn sunPhase(s: vec3f) -> f32 {
    let a = atan2(s.y, dot(s, SUN_EAST));
    let pi = 3.14159265;
    if (a < -pi + 0.35) { return 4.0 + (a + pi) / 0.35; }
    if (a < -0.35)      { return 5.0; }
    if (a < A_SUNRISE)  { return 5.0 + (a + 0.35) / (A_SUNRISE + 0.35); }
    if (a < A_MORNING)  { return 6.0 + (a - A_SUNRISE) / (A_MORNING - A_SUNRISE); }
    if (a < A_DAY)      { return 7.0 + (a - A_MORNING) / (A_DAY - A_MORNING); }
    if (a < A_DAY_END)  { return 8.0; }
    if (a < A_SUNSET)   { return 8.0 + (a - A_DAY_END) / (A_SUNSET - A_DAY_END); }
    return 9.0;
}

fn currentLook() -> Look {
    var p = clockPhase();
    var realSun = vec3f(0.0);
    var haveSun = false;
    if (USE_GAME_SUN) {
        let g = bloxdSunDirection();
        if (length(g) > 0.01) {
            realSun = normalize(g);
            haveSun = true;
            p = sunPhase(realSun);
        }
    }
    var k = lookBlend(p);
    if (haveSun) {
        k.sun = normalize(mix(k.sun, realSun, smoothstep(-0.05, 0.10, realSun.y)));
    }
    return k;
}

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

fn grade(s: BloxdSurface, l: BloxdLightIn, k: Look, shadowed: bool) -> vec3f {
    let sun = normalize(k.sun);
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    var sunVis = 1.0;
    if (shadowed) {
        let low = k.shLow + SHADOW_LEVEL_SHIFT;
        let high = min(k.shHigh + SHADOW_LEVEL_SHIFT, 14.99);
        let seen = smoothstep(low, max(high, low + 0.01), rawSkyLevel(l.skyLight));
        let faceLit = mix(1.0, smoothstep(0.0, 0.25, facing), FACE_SHADOW);
        sunVis = mix(1.0, seen * faceLit, clamp(k.shStrength * SHADOW_STRENGTH, 0.0, 1.0));
    }

    let tint = mix(k.sky, k.warm, wrap);
    let shade = mix(k.shadeMin, 1.0, clamp(facing * 1.45 + 0.3, 0.0, 1.0));
    var lit = l.litColour * tint * shade * k.exposure;

    lit = lit + s.colour * k.sunColour * ndl * k.direct * l.skyLight * sunVis;
    lit = lit + s.colour * (l.blockLight + l.heldLight) * k.blockBoost;

    if (shadowed) {
        let view = normalize(bloxdEyePosition() - l.position);
        let half = normalize(view + sun);
        let spec = pow(max(dot(normalize(l.normal), half), 0.0), BLOCK_SHINE_POWER) * step(0.0, facing);
        lit = lit + mix(vec3f(1.0), s.colour, 0.3) * k.sunColour * spec * BLOCK_SHINE * (0.5 + k.direct * 2.0) * sunVis;
    }

    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, k.saturation);
    lit = lit * mix(k.shColour, vec3f(1.0), sunVis);

    let fogCol = mix(l.fogColour, k.fog, k.fogMix);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = grade(s, l, currentLook(), true);
    return result;
}

fn bloxdLiquidSurface(s: BloxdSurfaceIn) -> BloxdSurface {
    let k = currentLook();
    var result = bloxdDefaultSurface(s);
    let w = bloxdWorldPosition(s.position);
    let t = bloxdTime();

    let ripple = vec3f(
        sin(w.x * 2.0 + t * 1.5) * 0.08 + sin(w.z * 4.1 - t * 2.3) * 0.04,
        0.0,
        cos(w.z * 2.3 + t * 1.2) * 0.08 + cos(w.x * 3.7 + t * 2.0) * 0.04
    );
    let n = normalize(s.normal + ripple);
    let view = normalize(bloxdEyePosition() - s.position);

    let fresnel = pow(1.0 - clamp(dot(n, view), 0.0, 1.0), 3.0);
    let refl = reflect(-view, n);
    let glint = pow(clamp(dot(refl, normalize(k.sun)), 0.0, 1.0), k.glintPower);

    let drift = sin(w.x * 0.45 + t * 0.25) * sin(w.z * 0.40 - t * 0.20 + sin(w.x * 0.2) * 2.0);
    let patches = smoothstep(0.1, 0.7, 0.5 + 0.5 * drift);
    let glare = patches * (0.3 + 0.7 * fresnel);

    result.colour = mix(result.colour, k.water, 0.6);
    result.colour = mix(result.colour, k.waterReflect, fresnel * 0.5);
    result.emission = k.sunColour * glint * k.glintStrength + k.waterReflect * glare * k.glare;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = grade(s, l, currentLook(), false);
    return result;
}

const TAU: f32 = 6.2831853;

fn sf(freq: f32) -> f32 {
    let k = max(round(freq * bloxdTimeWrap / TAU), 1.0);
    return k * TAU / bloxdTimeWrap;
}

const LEAF_SWAY: f32 = 0.07;
const LEAF_WIND_DIR: vec2f = vec2f(0.80, 0.60);

fn isLeaf(id: u32) -> bool {
    switch id {
        case 100u, 491u, 493u, 911u, 102u, 492u, 101u, 2021u, 2020u, 1636u, 2019u, 2085u, 1226u, 653u, 103u, 1969u, 2023u, 2022u, 2025u, 2024u, 208u, 209u, 210u, 211u, 494u, 495u, 496u, 654u, 938u, 1259u, 1663u, 1996u, 2086u: {
            return true;
        }
        default: {
            return false;
        }
    }
}

#ifndef BLOXD_STRICT
fn bloxdTerrainVertex(v: BloxdVertexIn) -> BloxdVertex {
    var result = bloxdDefaultVertex(v);
    if (isLeaf(v.blockId)) {
        let w = bloxdWorldPosition(v.position);
        let t = bloxdTime();
        let along = dot(w.xz, LEAF_WIND_DIR);
        let wave = sin(along * 0.10 - t * sf(1.1));
        let flutter = sin(t * sf(2.3) + w.x * 1.3 + w.y * 0.9 + w.z * 1.1);
        let push = LEAF_SWAY * (0.8 * wave + 0.2 * flutter);
        let lift = LEAF_SWAY * 0.25 * sin(t * sf(1.7) + along * 0.10);
        result.position = v.position + vec3f(LEAF_WIND_DIR.x * push, lift, LEAF_WIND_DIR.y * push);
    }
    return result;
}
#endif
