const SUN_RAW: vec3f = vec3f(-0.75, 0.30, 0.30);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.82, 0.65);
const SKY_COLOUR: vec3f = vec3f(0.85, 0.90, 1.00);
const WARM_COLOUR: vec3f = vec3f(1.10, 0.98, 0.88);
const FOG_COLOUR: vec3f = vec3f(0.95, 0.82, 0.85);
const WATER_COLOUR: vec3f = vec3f(0.20, 0.70, 0.85);
const WATER_REFLECT: vec3f = vec3f(0.95, 0.85, 0.85);
const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);
const SHADE_MIN: f32 = 0.55;
const EXPOSURE: f32 = 1.0;
const DIRECT: f32 = 0.3;
const SATURATION: f32 = 1.1;
const FOG_MIX: f32 = 0.4;
const BLOCK_BOOST: f32 = 0.3;
const GLINT_POWER: f32 = 32.0;
const GLINT_STRENGTH: f32 = 1.3;
const GLARE_STRENGTH: f32 = 0.4;

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn gradeLight(s: BloxdSurface, l: BloxdLightIn) -> vec3f {
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);
    let tint = mix(SKY_COLOUR, WARM_COLOUR, wrap);
    let shade = mix(SHADE_MIN, 1.0, clamp(facing * 1.4 + 0.3, 0.0, 1.0));
    var lit = l.litColour * tint * shade * EXPOSURE;
    lit = lit + s.colour * SUN_COLOUR * ndl * DIRECT * l.skyLight;
    lit = lit + s.colour * (l.blockLight + l.heldLight) * BLOCK_BOOST;
    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, SATURATION);
    let fogCol = mix(l.fogColour, FOG_COLOUR, FOG_MIX);
    let fogged = mix(fogCol, lit, l.fogVisibility);
    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = gradeLight(s, l);
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
    result.colour = mix(result.colour, WATER_REFLECT, fresnel * 0.5);
    result.emission = SUN_COLOUR * glint * GLINT_STRENGTH + WATER_REFLECT * glare * GLARE_STRENGTH;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = gradeLight(s, l);
    return result;
}
