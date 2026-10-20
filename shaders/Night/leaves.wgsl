const LEAF_SWAY: f32 = 0.07;
const LEAF_WIND_DIR: vec2f = vec2f(0.80, 0.60);

const TAU: f32 = 6.2831853;

fn sf(freq: f32) -> f32 {
    let k = max(round(freq * TIME_WRAP / TAU), 1.0);
    return k * TAU / TIME_WRAP;
}

fn isLeaf(flags: u32) -> bool {
    return (flags & bloxdBlockFlagVegetation) != 0u && (flags & bloxdBlockFlagDirt) == 0u;
}

#ifndef BLOXD_STRICT
fn bloxdTerrainVertex(v: BloxdVertexIn) -> BloxdVertex {
    var result = bloxdDefaultVertex(v);
    if (isLeaf(v.blockFlags)) {
        let w = bloxdWorldPosition(v.position);
        let t = packTime();
        let along = dot(w.xz, LEAF_WIND_DIR);
        let wave = sin(along * 0.10 - t * sf(1.1));
        let flutter = sin(t * sf(2.3) + w.x * 1.3 + w.y * 0.9 + w.z * 1.1);
        let push = LEAF_SWAY * (0.8 * wave + 0.2 * flutter);
        let lift = LEAF_SWAY * 0.25 * sin(t * sf(1.7) + along * 0.10);
        result.position = v.position + vec3f(LEAF_WIND_DIR.x * push, lift, LEAF_WIND_DIR.y * push);
    }
    return result;
}
#endif
