const LAVA_ID: u32 = 1491u;
const LAVA_HOT: vec3f = vec3f(1.00, 0.55, 0.12);
const LAVA_DARK: vec3f = vec3f(0.55, 0.10, 0.02);
const LAVA_GLOW: f32 = 1.1;

fn lavaSf(freq: f32) -> f32 {
    let k = max(round(freq * bloxdTimeWrap / 6.2831853), 1.0);
    return k * 6.2831853 / bloxdTimeWrap;
}

fn lavaLook(base: BloxdSurface, position: vec3f, glow: f32) -> BloxdSurface {
    var result = base;
    let w = bloxdWorldPosition(position);
    let t = bloxdTime();
    let a = sin(w.x * 1.6 + t * lavaSf(0.5) + sin(w.z * 0.9) * 1.5);
    let b = sin(w.z * 1.9 - t * lavaSf(0.4) + sin(w.x * 0.7) * 1.5);
    let c = sin((w.x + w.y + w.z) * 0.8 + t * lavaSf(0.7));
    let heat = clamp(0.5 + 0.17 * (a + b + c), 0.0, 1.0);
    let colour = mix(LAVA_DARK, LAVA_HOT, smoothstep(0.15, 0.85, heat));
    result.colour = colour;
    result.emission = colour * glow;
    return result;
}

fn bloxdTerrainSurface(s: BloxdSurfaceIn) -> BloxdSurface {
    var result = bloxdDefaultSurface(s);
    if (s.blockId == LAVA_ID) {
        return lavaLook(result, s.position, LAVA_GLOW);
    }
    return result;
}
