const WATER_REFLECT: vec3f = vec3f(0.95, 0.45, 0.30);

fn bloxdLiquidSurface(s: BloxdSurfaceIn) -> BloxdSurface {
    var result = bloxdDefaultSurface(s);
    let w = bloxdWorldPosition(s.position);
    let t = packTime();

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
