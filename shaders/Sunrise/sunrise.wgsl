const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_LOW: f32 = 13.6;
const SHADOW_LEVEL_HIGH: f32 = 14.95;
const SHADOW_COLOUR: vec3f = vec3f(0.62, 0.60, 0.82);

fn rawSkyLevel(encoded: f32) -> f32 {
    let base = 1.0 - pow(max(1.0 - clamp(encoded, 0.0, 1.0), 0.0), 1.0 / 3.0);
    return 45.0 * base / max(1.0 + 2.0 * base, 0.0001);
}

fn daylight() -> f32 {
    let g = bloxdSunDirection();
    if (dot(g, g) <= 0.25) {
        return 1.0;
    }
    return smoothstep(-0.08, 0.18, g.y);
}

const SUN_RAW: vec3f = vec3f(-0.85, 0.12, 0.25);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.74, 0.46);
const SKY_COLOUR: vec3f = vec3f(0.78, 0.80, 1.00);
const WARM_COLOUR: vec3f = vec3f(1.18, 0.95, 0.76);
const FOG_COLOUR: vec3f = vec3f(1.00, 0.74, 0.58);
const WATER_COLOUR: vec3f = vec3f(0.22, 0.55, 0.78);
const WATER_REFLECT: vec3f = vec3f(1.00, 0.70, 0.55);
const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);
const SHADE_MIN: f32 = 0.48;
const EXPOSURE: f32 = 0.95;
const DIRECT: f32 = 0.45;
const SATURATION: f32 = 1.15;
const FOG_MIX: f32 = 0.45;
const BLOCK_BOOST: f32 = 0.3;
const GLINT_POWER: f32 = 40.0;
const GLINT_STRENGTH: f32 = 1.6;
const GLARE_STRENGTH: f32 = 0.35;

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn gradeLight(s: BloxdSurface, l: BloxdLightIn, shadowed: bool) -> vec3f {
    var sunVis = 1.0;
    if (shadowed) {
        let seen = smoothstep(SHADOW_LEVEL_LOW, SHADOW_LEVEL_HIGH, rawSkyLevel(l.skyLight));
        sunVis = mix(1.0, seen, daylight() * SHADOW_STRENGTH);
    }
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    let tint = mix(SKY_COLOUR, WARM_COLOUR, wrap);
    let shade = mix(SHADE_MIN, 1.0, clamp(facing * 1.5 + 0.3, 0.0, 1.0));
    var lit = l.litColour * tint * shade * EXPOSURE;

    lit = lit + s.colour * SUN_COLOUR * ndl * DIRECT * l.skyLight * sunVis;
    lit = lit + s.colour * (l.blockLight + l.heldLight) * BLOCK_BOOST;

    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, SATURATION);

    lit = lit * mix(SHADOW_COLOUR, vec3f(1.0), sunVis);

    let fogCol = mix(l.fogColour, FOG_COLOUR, FOG_MIX);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = gradeLight(s, l, true);
    return result;
}

fn bloxdLiquidSurface(s: BloxdSurfaceIn) -> BloxdSurface {
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
    let glint = pow(clamp(dot(refl, sunDir()), 0.0, 1.0), GLINT_POWER);

    let drift = sin(w.x * 0.45 + t * 0.25) * sin(w.z * 0.40 - t * 0.20 + sin(w.x * 0.2) * 2.0);
    let patches = smoothstep(0.1, 0.7, 0.5 + 0.5 * drift);
    let glare = patches * (0.3 + 0.7 * fresnel);

    result.colour = mix(result.colour, WATER_COLOUR, 0.6);
    result.colour = mix(result.colour, WATER_REFLECT, fresnel * 0.55);
    result.emission = SUN_COLOUR * glint * GLINT_STRENGTH + WATER_REFLECT * glare * GLARE_STRENGTH;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = gradeLight(s, l, false);
    return result;
}
