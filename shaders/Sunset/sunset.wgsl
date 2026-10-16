const SHADOW_STRENGTH: f32 = 1.0;
const SHADOW_LEVEL_LOW: f32 = 13.6;
const SHADOW_LEVEL_HIGH: f32 = 14.95;
const SHADOW_COLOUR: vec3f = vec3f(0.58, 0.52, 0.74);

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

const SUN_RAW: vec3f = vec3f(0.80, 0.16, 0.35);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.68, 0.38);
const SKY_COLOUR: vec3f = vec3f(0.80, 0.85, 1.00);
const FOG_COLOUR: vec3f = vec3f(1.00, 0.62, 0.40);
const WATER_REFLECT: vec3f = vec3f(0.95, 0.45, 0.30);

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn sunsetGrade(s: BloxdSurface, l: BloxdLightIn, shadowed: bool) -> vec3f {
    var sunVis = 1.0;
    if (shadowed) {
        let seen = smoothstep(SHADOW_LEVEL_LOW, SHADOW_LEVEL_HIGH, rawSkyLevel(l.skyLight));
        sunVis = mix(1.0, seen, daylight() * SHADOW_STRENGTH);
    }
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    let tint = mix(SKY_COLOUR, vec3f(1.15, 0.92, 0.72), wrap);
    var lit = l.litColour * tint;

    let shade = mix(0.45, 1.0, clamp(facing * 1.5 + 0.35, 0.0, 1.0));
    lit = lit * shade;

    lit = lit + s.colour * SUN_COLOUR * ndl * 0.4 * l.skyLight * sunVis;

    lit = lit + s.colour * (l.blockLight + l.heldLight) * 0.3;

    lit = lit * mix(SHADOW_COLOUR, vec3f(1.0), sunVis);

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
