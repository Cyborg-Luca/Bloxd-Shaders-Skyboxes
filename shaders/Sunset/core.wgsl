const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_SHIFT: f32 = 0.0;
const FACE_SHADOW: f32 = 1.0;
const SH_STRENGTH: f32 = 0.95;
const SH_LOW: f32 = 14.3;
const SH_HIGH: f32 = 14.98;
const SH_COLOUR: vec3f = vec3f(0.68, 0.50, 0.74);

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

const SUN_RAW: vec3f = vec3f(0.80, 0.16, 0.35);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.68, 0.38);
const SKY_COLOUR: vec3f = vec3f(0.80, 0.85, 1.00);
const FOG_COLOUR: vec3f = vec3f(1.00, 0.62, 0.40);

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
        lit = lit + sunShine(s.colour, l.normal, l.position, sun, SUN_COLOUR, facing, sunVis);
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
