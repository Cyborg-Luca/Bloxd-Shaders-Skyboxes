# Bloxd Shaders & Skyboxes

Shaders (WGSL) and skyboxes for **Bloxd.io**, by **Cyborg_Luca**.

Five moods, each with a shader and a matching skybox:

| Mood | Shader | Skybox | Horizon preview |
|---|---|---|---|
| **Day** – bright daylight | `shaders/Day` | `skyboxes/Day` | ![Day](previews/Day.png) |
| **Morning** – fresh morning, peach-pink | `shaders/Morning` | `skyboxes/Morning` | ![Morning](previews/Morning.png) |
| **Sunrise** – golden sunrise | `shaders/Sunrise` | `skyboxes/Sunrise` | ![Sunrise](previews/Sunrise.png) |
| **Sunset** – orange sunset | `shaders/Sunset` | `skyboxes/Sunset` | ![Sunset](previews/Sunset.png) |
| **Night** – moonlit night | `shaders/Night` | `skyboxes/Night` | ![Night](previews/Night.png) |
| **Cycle** – all 5 moods in a single shader | `shaders/Cycle` | (none, see below) | |

## Contents

```
shaders/<Mood>/
    pack.json          (apiVersion 2)
    core.wgsl          light, colours, shadows        (required)
    reflections.wgsl   sun reflections on blocks      (required)
    water.wgsl         water                          (optional)
    lava.wgsl          lava                           (optional)
    leaves.wgsl        swaying leaves                 (optional)
skyboxes/<Mood>/skyBoxes/default/
    px.jpg nx.jpg py.jpg ny.jpg pz.jpg nz.jpg     (1024x1024)
previews/              horizon preview of each skybox
tools/make_sky.py      script that generates the skyboxes
```

## Shaders

- Format: Bloxd shader API **version 2** (`apiVersion: 2`), written in WGSL.
- They modify the terrain light (`bloxdTerrainLight`), the water (`bloxdLiquidSurface`, `bloxdLiquidLight`), the lava (`bloxdTerrainSurface`) and the leaves (`bloxdTerrainVertex`).
- Each shader has its own sun direction and colour (`SUN_RAW`, `SUN_COLOUR`), fog colour and shading.
- A shader cannot draw the sky: the API has no function for it. That is why the skyboxes are separate.

### Files and what you can remove

Bloxd joins all `.wgsl` files of a pack into one module, in an unspecified order, and each hook can only be defined once. So every optional file defines its own hook and depends on nothing but `core.wgsl`.

| File | Content | Can be deleted? |
|---|---|---|
| `core.wgsl` | light, colours, fog, shadows | No |
| `reflections.wgsl` | sun reflections on blocks | No (set `BLOCK_SHINE` to `0.0` to turn them off) |
| `water.wgsl` | water colour, ripples, sun glint | Yes: water falls back to the normal terrain look |
| `lava.wgsl` | animated glowing lava | Yes: lava keeps its normal texture |
| `leaves.wgsl` | swaying leaves | Yes: leaves stay still |

Shadows live in `core.wgsl` and share the same light hook as the rest, so they cannot be deleted either: set `SHADOW_STRENGTH` to `0.0` instead.

To remove a module, delete its file from the pack and load the pack again in Settings → Shader Pack.

## Shadows

All shaders (Day, Morning, Sunrise, Sunset, Night and Cycle) add shadows to blocks:

- **Sky shadow**: a block is darker and tinted when it cannot see the sky (under a tree, under a roof). It comes from `skyLight`.
- **Dark side of blocks**: the face of each block turned away from the sun is darkened, on every block, even a cube sitting on the ground.

Settings at the top of `core.wgsl`:

- `SHADOW_STRENGTH`: shadow strength (1 = normal, 0 = disabled).
- `SHADOW_LEVEL_SHIFT`: size of the sky shadows (higher = larger, lower = smaller).
- `FACE_SHADOW`: dark side of blocks (1 = normal, 0 = disabled).
- `SH_STRENGTH`, `SH_LOW`, `SH_HIGH`, `SH_COLOUR`: strength, size and colour of the shadows specific to each mood (in Cycle, these 4 values are at the end of each look in `lookAt`).

Limits: the Bloxd shader API provides neither neighbouring blocks nor a shadow map, so there are no cast shadows on the ground. The shadow under a tree does not rotate with the sun; only the dark side of blocks follows it. In Day, Morning, Sunrise, Sunset and Night the sun is fixed; in Cycle, the size, strength and colour of the shadows change with the time of day (large and coloured at sunrise and sunset, small at noon, faint at night).

## Reflections

All shaders add a sun reflection on blocks: a glint visible when looking towards the sun, stronger when the sun is low, absent in shadow. Settings are at the top of `reflections.wgsl`:

- `BLOCK_SHINE`: reflection strength (0 = disabled, 0.5 = very shiny).
- `BLOCK_SHINE_POWER`: reflection size (small = wide and soft, large = small sharp dot).
- `SHINE_DIRECT` (except Cycle): sensitivity to the mood's direct light.

## Water

`water.wgsl` keeps the water light and simple: a mood-specific colour (`WATER_COLOUR`, `WATER_REFLECT`), small moving ripples, a Fresnel edge and a sun glint on the surface. The water shape itself does not change: vertex waves were tried but Bloxd merges water faces, which leaves black cracks between them.

## Lava

`lava.wgsl` replaces the lava texture (block id `1491`) with a moving, glowing flow in the terrain surface hook.

- `LAVA_HOT`, `LAVA_DARK`: bright and dark lava colours.
- `LAVA_GLOW`: how strongly the lava glows. It is higher at night and lower at noon: Night 1.6, Sunset 1.2, Sunrise 1.1, Morning 0.9, Day 0.7. In Cycle it blends with the current mood (`lavaGlow` in each look of `lookAt`).

## Swaying leaves

`leaves.wgsl` makes leaves sway gently, as if there were a light wind. It moves the leaf vertices in the vertex hook, for the 33 leaf block ids (including the `|TreeCanopy` variants used by generated trees).

- `LEAF_SWAY`: how far the leaves move (0.07 by default; higher = stronger wind).
- `LEAF_WIND_DIR`: wind direction on the ground plane (x, z).

Limit: vertex hooks are not allowed in "strict" games. In a strict world Bloxd turns the whole shader pack off ("Your shader pack is off in this game"). The code is wrapped in `#ifndef BLOXD_STRICT`, but the pack is still disabled there. Delete `leaves.wgsl` to use the pack in strict worlds.

## Cycle shader (all-in-one)

`shaders/Cycle/core.wgsl` fades Night → Sunrise → Morning → Day → Sunset → Night, based on `bloxdTime()`.

- `CYCLE_SECONDS`: length of a full cycle (must divide 3600: 600, 900, 1200, 1800, 3600).
- `START_LOOK`: mood at start-up (0 Night, 1 Sunrise, 2 Morning, 3 Day, 4 Sunset).
- `HOLD`: how long each mood lasts before moving to the next.
- `USE_GAME_SUN`: `true` by default, the shader follows the game's real sun (`bloxdSunDirection()`) and stays in sync with the time of day. If the world has no sun, it falls back to the clock.
- `SUN_EAST`: direction of east. Measured in-game: the sun rises on the +x side, so `vec3f(1,0,0)`. If morning ever looks like evening, use `vec3f(-1,0,0)`.
- `A_SUNRISE`, `A_MORNING`, `A_DAY`, `A_DAY_END`, `A_SUNSET`: sun angles (0 = sunrise, 1.57 = noon, 3.14 = sunset) that set when each mood arrives during the day (smaller = earlier). `A_DAY`: full daylight is reached; `A_DAY_END`: the fade towards evening begins; `A_SUNSET`: the Sunset look is reached.
- `SHADOW_STRENGTH`, `SHADOW_LEVEL_SHIFT`, `FACE_SHADOW` (in `core.wgsl`), `BLOCK_SHINE`, `BLOCK_SHINE_POWER` (in `reflections.wgsl`): shadows and reflections (see above). The size, strength and colour of each mood's shadows are in `lookAt` and blend from one mood to the next.
- The shader changes the terrain, the water, the lava and the leaves. A skybox is fixed: it does not change with the cycle.

## Skyboxes

- Bloxd format: six `.jpg` faces in `skyBoxes/<name>/` (`px`, `nx`, `py`, `ny`, `pz`, `nz`), as in [bloxdy/texture-packs](https://github.com/bloxdy/texture-packs).
- The face orientation was checked against the game's default skybox (edges line up between faces).
- Each skybox uses the colours and the sun direction (or the moon for Night) of its shader.
- The sun is fixed in the image: it does not follow the game's time.
- The images are generated by `tools/make_sky.py` (Python, `numpy` and `Pillow`):

```bash
pip install numpy pillow
python tools/make_sky.py output            # all 5 skyboxes
python tools/make_sky.py output Sunrise    # just one
```

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE).
