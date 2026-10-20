const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_SHIFT: f32 = 0.0;
const FACE_SHADOW: f32 = 1.0;
const SH_STRENGTH: f32 = 1.0;
const SH_LOW: f32 = 13.4;
const SH_HIGH: f32 = 14.6;
const SH_COLOUR: vec3f = vec3f(0.56, 0.63, 0.84);

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

const SUN_RAW: vec3f = vec3f(0.35, 0.85, 0.40);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.96, 0.88);
const SKY_COLOUR: vec3f = vec3f(0.82, 0.90, 1.00);
const FOG_COLOUR: vec3f = vec3f(0.75, 0.88, 1.00);
const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn dayGrade(s: BloxdSurface, l: BloxdLightIn, shadowed: bool) -> vec3f {
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

    let tint = mix(SKY_COLOUR, vec3f(1.08, 1.03, 0.94), wrap);
    var lit = l.litColour * tint;

    let shade = mix(0.55, 1.0, clamp(facing * 1.4 + 0.3, 0.0, 1.0));
    lit = lit * shade;

    lit = lit + s.colour * SUN_COLOUR * ndl * 0.25 * l.skyLight * sunVis;

    lit = lit + s.colour * (l.blockLight + l.heldLight) * 0.3;

    if (shadowed) {
        lit = lit + sunShine(s.colour, l.normal, l.position, sun, SUN_COLOUR, facing, sunVis);
    }

    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, 1.15);

    lit = lit * mix(SH_COLOUR, vec3f(1.0), sunVis);
    let fogCol = mix(l.fogColour, FOG_COLOUR, 0.3);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = dayGrade(s, l, true);
    return result;
}
