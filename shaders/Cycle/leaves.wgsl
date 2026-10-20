const TAU: f32 = 6.2831853;

fn sf(freq: f32) -> f32 {
    let k = max(round(freq * bloxdTimeWrap / TAU), 1.0);
    return k * TAU / bloxdTimeWrap;
}

const LEAF_SWAY: f32 = 0.07;
const LEAF_WIND_DIR: vec2f = vec2f(0.80, 0.60);

fn isLeaf(id: u32) -> bool {
    switch id {
        case 100u, 491u, 493u, 911u, 102u, 492u, 101u, 2021u, 2020u, 1636u, 2019u, 2085u, 1226u, 653u, 103u, 1969u, 2023u, 2022u, 2025u, 2024u, 208u, 209u, 210u, 211u, 494u, 495u, 496u, 654u, 938u, 1259u, 1663u, 1996u, 2086u: {
            return true;
        }
        default: {
            return false;
        }
    }
}

#ifndef BLOXD_STRICT
fn bloxdTerrainVertex(v: BloxdVertexIn) -> BloxdVertex {
    var result = bloxdDefaultVertex(v);
    if (isLeaf(v.blockId)) {
        let w = bloxdWorldPosition(v.position);
        let t = bloxdTime();
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
