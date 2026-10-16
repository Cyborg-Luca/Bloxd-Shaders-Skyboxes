// ===== Day Cycle : Night -> Sunrise -> Morning -> Day -> Sunset -> Night =====
// Regle ici la duree du cycle. Doit diviser 3600 (bloxdTimeWrap) pour que la boucle soit sans coupure :
// 600 = 10 min, 900 = 15 min, 1200 = 20 min, 1800 = 30 min, 3600 = 1 h
// POUR TESTER VITE : mets 60.0 (un tour complet en 1 minute, chaque ambiance dure ~12 s), puis remets 1200.0.
const CYCLE_SECONDS: f32 = 1200.0;
// Ambiance au demarrage du cycle : 0 Night, 1 Sunrise, 2 Morning, 3 Day, 4 Sunset
const START_LOOK: f32 = 3.0;
// 0 = chaque ambiance dure pareil et se fond doucement dans la suivante ; 1 = fondu tres court
const HOLD: f32 = 0.35;

// Suivre le vrai soleil du jeu (bloxdSunDirection) : le shader reste synchro avec l'heure du jeu.
// Si le soleil du jeu est introuvable, le shader retombe tout seul sur l'horloge (CYCLE_SECONDS).
const USE_GAME_SUN: bool = true;
// Direction de l'EST dans le monde (la ou le soleil se leve). Si le MATIN ressemble au SOIR dans le jeu,
// essaie une autre valeur : vec3f(1.0, 0.0, 0.0)  ou  vec3f(0.0, 0.0, 1.0)  ou  vec3f(0.0, 0.0, -1.0)
const SUN_EAST: vec3f = vec3f(-1.0, 0.0, 0.0);

const LUMA: vec3f = vec3f(0.299, 0.587, 0.114);
const LOOKS: i32 = 5;

struct Look {
    sun: vec3f,
    sunColour: vec3f,
    sky: vec3f,
    warm: vec3f,
    fog: vec3f,
    water: vec3f,
    waterReflect: vec3f,
    shadeMin: f32,
    exposure: f32,
    direct: f32,
    saturation: f32,
    fogMix: f32,
    blockBoost: f32,
    glintPower: f32,
    glintStrength: f32,
    glare: f32,
}

fn lookAt(i: i32) -> Look {
    var k: Look;
    switch i {
        // 0 : Night
        case 0: {
            k = Look(
                vec3f(0.30, 0.80, -0.50), vec3f(0.60, 0.70, 1.00), vec3f(0.72, 0.80, 1.00), vec3f(0.85, 0.92, 1.08),
                vec3f(0.04, 0.07, 0.18), vec3f(0.03, 0.08, 0.22), vec3f(0.15, 0.20, 0.38),
                0.75, 0.95, 0.08, 0.95, 0.60, 0.60, 48.0, 0.6, 0.05);
        }
        // 1 : Sunrise
        case 1: {
            k = Look(
                vec3f(-0.85, 0.12, 0.25), vec3f(1.00, 0.74, 0.46), vec3f(0.78, 0.80, 1.00), vec3f(1.18, 0.95, 0.76),
                vec3f(1.00, 0.74, 0.58), vec3f(0.22, 0.55, 0.78), vec3f(1.00, 0.70, 0.55),
                0.48, 0.95, 0.45, 1.15, 0.45, 0.30, 40.0, 1.6, 0.35);
        }
        // 2 : Morning
        case 2: {
            k = Look(
                vec3f(-0.75, 0.30, 0.30), vec3f(1.00, 0.82, 0.65), vec3f(0.85, 0.90, 1.00), vec3f(1.10, 0.98, 0.88),
                vec3f(0.95, 0.82, 0.85), vec3f(0.20, 0.70, 0.85), vec3f(0.95, 0.85, 0.85),
                0.55, 1.00, 0.30, 1.10, 0.40, 0.30, 32.0, 1.3, 0.40);
        }
        // 3 : Day
        case 3: {
            k = Look(
                vec3f(0.35, 0.85, 0.40), vec3f(1.00, 0.96, 0.88), vec3f(0.82, 0.90, 1.00), vec3f(1.08, 1.03, 0.94),
                vec3f(0.75, 0.88, 1.00), vec3f(0.10, 0.75, 0.95), vec3f(0.70, 0.85, 1.00),
                0.55, 1.00, 0.25, 1.15, 0.30, 0.30, 24.0, 1.5, 0.50);
        }
        // 4 : Sunset
        default: {
            k = Look(
                vec3f(0.80, 0.16, 0.35), vec3f(1.00, 0.68, 0.38), vec3f(0.80, 0.85, 1.00), vec3f(1.15, 0.92, 0.72),
                vec3f(1.00, 0.62, 0.40), vec3f(0.12, 0.40, 0.62), vec3f(0.95, 0.45, 0.30),
                0.45, 1.00, 0.40, 1.00, 0.35, 0.30, 48.0, 1.6, 0.25);
        }
    }
    return k;
}

fn mixLook(a: Look, b: Look, t: f32) -> Look {
    return Look(
        mix(a.sun, b.sun, t), mix(a.sunColour, b.sunColour, t), mix(a.sky, b.sky, t), mix(a.warm, b.warm, t),
        mix(a.fog, b.fog, t), mix(a.water, b.water, t), mix(a.waterReflect, b.waterReflect, t),
        mix(a.shadeMin, b.shadeMin, t), mix(a.exposure, b.exposure, t), mix(a.direct, b.direct, t),
        mix(a.saturation, b.saturation, t), mix(a.fogMix, b.fogMix, t), mix(a.blockBoost, b.blockBoost, t),
        mix(a.glintPower, b.glintPower, t), mix(a.glintStrength, b.glintStrength, t), mix(a.glare, b.glare, t));
}

// p : position dans le cycle (0..5 = une boucle). Partie entiere = ambiance, partie decimale = fondu vers la suivante.
fn lookBlend(p: f32) -> Look {
    let i0 = i32(floor(p)) % LOOKS;
    let i1 = (i0 + 1) % LOOKS;
    let t = smoothstep(0.0, 1.0, fract(p));
    return mixLook(lookAt(i0), lookAt(i1), t);
}

// Position dans le cycle d'apres l'horloge de Bloxd.
fn clockPhase() -> f32 {
    let q = bloxdTime() / CYCLE_SECONDS * f32(LOOKS) + START_LOOK;
    let k = floor(q);
    // chaque ambiance reste stable puis se fond vite dans la suivante
    return k + smoothstep(HOLD, 1.0 - HOLD, fract(q));
}

// Reglages du rythme de la journee, en angle du soleil depuis l'horizon est :
// 0 = soleil a l'horizon est (lever), 1.57 = tout en haut (midi), 3.14 = horizon ouest (coucher).
// Plus la valeur est PETITE, plus l'ambiance arrive TOT. Valeurs conseillees entre 0.0 et 3.14, dans l'ordre croissant.
const A_SUNRISE: f32 = 0.10;   // look Sunrise atteint
const A_MORNING: f32 = 0.45;   // look Morning atteint
const A_DAY: f32 = 1.25;       // look Day atteint (augmente pour retarder le plein midi)
const A_DAY_END: f32 = 1.70;   // fin du plein jour, le fondu vers Sunset commence
const A_SUNSET: f32 = 2.40;    // look Sunset atteint (diminue pour un soir plus tot)

// Position dans le cycle d'apres le soleil du jeu.
fn sunPhase(s: vec3f) -> f32 {
    let a = atan2(s.y, dot(s, SUN_EAST));  // 0 = soleil a l'horizon est, pi/2 = zenith, +-pi = horizon ouest
    let pi = 3.14159265;
    if (a < -pi + 0.35) { return 4.0 + (a + pi) / 0.35; }                                // sunset -> night
    if (a < -0.35)      { return 5.0; }                                                  // night
    if (a < A_SUNRISE)  { return 5.0 + (a + 0.35) / (A_SUNRISE + 0.35); }                // night -> sunrise
    if (a < A_MORNING)  { return 6.0 + (a - A_SUNRISE) / (A_MORNING - A_SUNRISE); }      // sunrise -> morning
    if (a < A_DAY)      { return 7.0 + (a - A_MORNING) / (A_DAY - A_MORNING); }          // morning -> day
    if (a < A_DAY_END)  { return 8.0; }                                                  // day
    if (a < A_SUNSET)   { return 8.0 + (a - A_DAY_END) / (A_SUNSET - A_DAY_END); }       // day -> sunset
    return 9.0;                                                                          // sunset
}

fn currentLook() -> Look {
    var p = clockPhase();
    var realSun = vec3f(0.0);
    var haveSun = false;
    if (USE_GAME_SUN) {
        let g = bloxdSunDirection();
        if (length(g) > 0.01) {
            realSun = normalize(g);
            haveSun = true;
            p = sunPhase(realSun);
        }
    }
    var k = lookBlend(p);
    if (haveSun) {
        // de jour, l'ombrage suit le vrai soleil ; de nuit on garde la direction de la lune
        k.sun = normalize(mix(k.sun, realSun, smoothstep(-0.05, 0.10, realSun.y)));
    }
    return k;
}

fn grade(s: BloxdSurface, l: BloxdLightIn, k: Look) -> vec3f {
    let sun = normalize(k.sun);
    let facing = dot(l.normal, sun);
    let ndl = max(facing, 0.0);
    let wrap = clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    let tint = mix(k.sky, k.warm, wrap);
    let shade = mix(k.shadeMin, 1.0, clamp(facing * 1.45 + 0.3, 0.0, 1.0));
    var lit = l.litColour * tint * shade * k.exposure;

    lit = lit + s.colour * k.sunColour * ndl * k.direct * l.skyLight;
    lit = lit + s.colour * (l.blockLight + l.heldLight) * k.blockBoost;

    let grey = dot(lit, LUMA);
    lit = mix(vec3f(grey), lit, k.saturation);

    let fogCol = mix(l.fogColour, k.fog, k.fogMix);
    let fogged = mix(fogCol, lit, l.fogVisibility);

    return fogged + s.emission * l.fogVisibility;
}

fn bloxdTerrainLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = grade(s, l, currentLook());
    return result;
}

fn bloxdLiquidSurface(s: BloxdSurfaceIn) -> BloxdSurface {
    let k = currentLook();
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
    let glint = pow(clamp(dot(refl, normalize(k.sun)), 0.0, 1.0), k.glintPower);

    let drift = sin(w.x * 0.45 + t * 0.25) * sin(w.z * 0.40 - t * 0.20 + sin(w.x * 0.2) * 2.0);
    let patches = smoothstep(0.1, 0.7, 0.5 + 0.5 * drift);
    let glare = patches * (0.3 + 0.7 * fresnel);

    result.colour = mix(result.colour, k.water, 0.6);
    result.colour = mix(result.colour, k.waterReflect, fresnel * 0.5);
    result.emission = k.sunColour * glint * k.glintStrength + k.waterReflect * glare * k.glare;
    return result;
}

fn bloxdLiquidLight(s: BloxdSurface, l: BloxdLightIn) -> BloxdLight {
    var result = bloxdDefaultLight(s, l);
    result.colour = grade(s, l, currentLook());
    return result;
}
