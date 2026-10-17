const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_SHIFT: f32 = 0.0;
const FACE_SHADOW: f32 = 1.0;
const SH_STRENGTH: f32 = 0.95;
const SH_LOW: f32 = 14.3;
const SH_HIGH: f32 = 14.98;
const SH_COLOUR: vec3f = vec3f(0.68, 0.50, 0.74);
const BLOCK_SHINE: f32 = 0.20;
const BLOCK_SHINE_POWER: f32 = 40.0;
const SHINE_DIRECT: f32 = 0.4;

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

const SUN_RAW: vec3f = vec3f(0.80, 0.16, 0.35);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.68, 0.38);
const SKY_COLOUR: vec3f = vec3f(0.80, 0.85, 1.00);
const FOG_COLOUR: vec3f = vec3f(1.00, 0.62, 0.40);
const WATER_REFLECT: vec3f = vec3f(0.95, 0.45, 0.30);

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn sunsetGrade(s: BloxdSurface, l: BloxdLightIn, shadowed: bool) -> vec3f {
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    var sunVis = 1.0;
    if (shadowed) {
        let low = SH_LOW + SHADOW_LEVEL_SHIFT;
        let high = min(SH_HIGH + SHADOW_LEVEL_SHIFT, 14.99);
        let seen = smoothstep(low, max(high, low + 0.01), rawSkyLevel(l.skyLight));
        let faceLit = mix(1.0, smoothstep(0.0, 0.25, facing), FACE_SHADOW);
        sunVis = mix(1.0, seen * faceLit, clamp(SH_STRENGTH * SHADOW_STRENGTH, 0.0, 1.0));
    }

    let tint = mix(SKY_COLOUR, vec3f(1.15, 0.92, 0.72), wrap);
    var lit = l.litColour * tint;

    let shade = mix(0.45, 1.0, clamp(facing * 1.5 + 0.35, 0.0, 1.0));
    lit = lit * shade;

    lit = lit + s.colour * SUN_COLOUR * ndl * 0.4 * l.skyLight * sunVis;

    lit = lit + s.colour * (l.blockLight + l.heldLight) * 0.3;

    if (shadowed) {
        let view = normalize(bloxdEyePosition() - l.position);
        let half = normalize(view + sun);
        let spec = pow(max(dot(normalize(l.normal), half), 0.0), BLOCK_SHINE_POWER) * step(0.0, facing);
        lit = lit + mix(vec3f(1.0), s.colour, 0.3) * SUN_COLOUR * spec * BLOCK_SHINE * (0.5 + SHINE_DIRECT * 2.0) * sunVis;
    }

    lit = lit * mix(SH_COLOUR, vec3f(1.0), sunVis);
    let fogCol = mix(l.fogColour, FOG_COLOUR, 0.35);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = sunsetGrade(s, l, true);
    return result;
}

fn bloxdLiquidSurface(s: BloxdSurfaceIn) -> BloxdSurface {
    var result = bloxdDefaultSurface(s);
    let w = bloxdWorldPosition(s.position);
    let t = bloxdTime();

    let ripple = vec3f(sin(w.x * 2.0 + t * 1.5) * 0.08, 0.0, cos(w.z * 2.3 + t * 1.2) * 0.08);
    let n = normalize(s.normal + ripple);
    let view = normalize(bloxdEyePosition() - s.position);

    let fresnel = pow(1.0 - clamp(dot(n, view), 0.0, 1.0), 3.0);
    let refl = reflect(-view, n);
    let glint = pow(clamp(dot(refl, sunDir()), 0.0, 1.0), 48.0);

    result.colour = mix(result.colour, WATER_REFLECT, fresnel * 0.6);
    result.emission = SUN_COLOUR * glint * 1.6 + vec3f(0.5, 0.2, 0.1) * fresnel * 0.25;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = sunsetGrade(s, l, false);
    return result;
}

const LEAF_SWAY: f32 = 0.07;
const LEAF_WIND_DIR: vec2f = vec2f(0.80, 0.60);

const TAU: f32 = 6.2831853;

fn sf(freq: f32) -> f32 {
    let k = max(round(freq * bloxdTimeWrap / TAU), 1.0);
    return k * TAU / bloxdTimeWrap;
}

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
