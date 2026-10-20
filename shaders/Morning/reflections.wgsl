const BLOCK_SHINE: f32 = 0.20;
const BLOCK_SHINE_POWER: f32 = 40.0;
const SHINE_DIRECT: f32 = 0.3;

fn sunShine(colour: vec3f, normal: vec3f, position: vec3f, sun: vec3f, sunColour: vec3f, facing: f32, vis: f32) -> vec3f {
    let view = normalize(bloxdEyePosition() - position);
    let half = normalize(view + sun);
    let spec = pow(max(dot(normalize(normal), half), 0.0), BLOCK_SHINE_POWER) * step(0.0, facing);
    return mix(vec3f(1.0), colour, 0.3) * sunColour * spec * BLOCK_SHINE * (0.5 + SHINE_DIRECT * 2.0) * vis;
}
