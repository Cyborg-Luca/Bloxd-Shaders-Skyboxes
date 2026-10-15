const SUN_RAW: vec3f = vec3f(0.80, 0.16, 0.35);
const SUN_COLOUR: vec3f = vec3f(1.00, 0.68, 0.38);
const SKY_COLOUR: vec3f = vec3f(0.80, 0.85, 1.00);
const FOG_COLOUR: vec3f = vec3f(1.00, 0.62, 0.40);
const WATER_REFLECT: vec3f = vec3f(0.95, 0.45, 0.30);

fn sunDir() -> vec3f {
    return normalize(SUN_RAW);
}

fn sunsetGrade(s: BloxdSurface, l: BloxdLightIn) -> vec3f {
    let sun = sunDir();
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    let tint = mix(SKY_COLOUR, vec3f(1.15, 0.92, 0.72), wrap);
    var lit = l.litColour * tint;

    let shade = mix(0.45, 1.0, clamp(facing * 1.5 + 0.35, 0.0, 1.0));
    lit = lit * shade;

    lit = lit + s.colour * SUN_COLOUR * ndl * 0.4 * l.skyLight;

    lit = lit + s.colour * (l.blockLight + l.heldLight) * 0.3;

    let fogCol = mix(l.fogColour, FOG_COLOUR, 0.35);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = sunsetGrade(s, l);
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
    result.colour = sunsetGrade(s, l);
    return result;
}
