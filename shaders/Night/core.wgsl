const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_SHIFT: f32 = 0.0;
const FACE_SHADOW: f32 = 1.0;
const SH_STRENGTH: f32 = 0.3;
const SH_LOW: f32 = 12.8;
const SH_HIGH: f32 = 14.2;
const SH_COLOUR: vec3f = vec3f(0.78, 0.82, 0.98);

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

const SUN_RAW: vec3f = vec3f(0.30, 0.80, -0.50);
const SUN_COLOUR: vec3f = vec3f(0.60, 0.70, 1.00);
const SKY_COLOUR: vec3f = vec3f(0.45, 0.55, 0.95);
const WARM_COLOUR: vec3f = vec3f(0.75, 0.85, 1.10);
const FOG_COLOUR: vec3f = vec3f(0.04, 0.07, 0.18);
const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);
const SHADE_MIN: f32 = 0.6;
const EXPOSURE: f32 = 0.5;
const DIRECT: f32 = 0.15;
const SATURATION: f32 = 0.9;
const FOG_MIX: f32 = 0.6;
const BLOCK_BOOST: f32 = 0.6;

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn gradeLight(s: BloxdSurface, l: BloxdLightIn, shadowed: bool) -> vec3f {
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
    let tint = mix(SKY_COLOUR, WARM_COLOUR, wrap);
    let shade = mix(SHADE_MIN, 1.0, clamp(facing * 1.4 + 0.3, 0.0, 1.0));
    var lit = l.litColour * tint * shade * EXPOSURE;
    lit = lit + s.colour * SUN_COLOUR * ndl * DIRECT * l.skyLight * sunVis;
    lit = lit + s.colour * (l.blockLight + l.heldLight) * BLOCK_BOOST;

    if (shadowed) {
        lit = lit + sunShine(s.colour, l.normal, l.position, sun, SUN_COLOUR, facing, sunVis);
    }
    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, SATURATION);
    lit = lit * mix(SH_COLOUR, vec3f(1.0), sunVis);
    let fogCol = mix(l.fogColour, FOG_COLOUR, FOG_MIX);
    let fogged = mix(fogCol, lit, l.fogVisibility);
    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = gradeLight(s, l, true);
    return result;
}
