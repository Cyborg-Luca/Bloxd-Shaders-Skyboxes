const SUN_RAW: vec3f = vec3f(0.35, 0.85, 0.40);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.96, 0.88);
const SKY_COLOUR: vec3f = vec3f(0.82, 0.90, 1.00);
const FOG_COLOUR: vec3f = vec3f(0.75, 0.88, 1.00);
const WATER_COLOUR: vec3f = vec3f(0.10, 0.75, 0.95);
const WATER_REFLECT: vec3f = vec3f(0.70, 0.85, 1.00);
const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn dayGrade(s: BloxdSurface, l: BloxdLightIn) -> vec3f {
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    let tint = mix(SKY_COLOUR, vec3f(1.08, 1.03, 0.94), wrap);
    var lit = l.litColour * tint;

    let shade = mix(0.55, 1.0, clamp(facing * 1.4 + 0.3, 0.0, 1.0));
    lit = lit * shade;

    lit = lit + s.colour * SUN_COLOUR * ndl * 0.25 * l.skyLight;

    lit = lit + s.colour * (l.blockLight + l.heldLight) * 0.3;

    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, 1.15);

    let fogCol = mix(l.fogColour, FOG_COLOUR, 0.3);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = dayGrade(s, l);
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
    let glint = pow(clamp(dot(refl, sunDir()), 0.0, 1.0), 24.0);

    let drift = sin(w.x * 0.45 + t * 0.25) * sin(w.z * 0.40 - t * 0.20 + sin(w.x * 0.2) * 2.0);
    let patches = smoothstep(0.1, 0.7, 0.5 + 0.5 * drift);
    let glare = patches * (0.3 + 0.7 * fresnel);

    result.colour = mix(result.colour, WATER_COLOUR, 0.6);
    result.colour = mix(result.colour, WATER_REFLECT, fresnel * 0.5);
    result.emission = SUN_COLOUR * glint * 1.5 + vec3f(0.9, 0.95, 1.0) * glare * 0.5;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = dayGrade(s, l);
    return result;
}
