# Bloxd Shaders & Skyboxes

Shaders (WGSL) et skyboxes pour **Bloxd.io**, par **Cyborg_Luca**.
*Shaders (WGSL) and skyboxes for Bloxd.io, by Cyborg_Luca.*

Cinq ambiances, chacune avec un shader et une skybox assortie :

| Ambiance | Shader | Skybox | Aperçu de l'horizon |
|---|---|---|---|
| **Day** – jour lumineux | `shaders/Day` | `skyboxes/Day` | ![Day](previews/Day.png) |
| **Morning** – matin frais, rose-pêche | `shaders/Morning` | `skyboxes/Morning` | ![Morning](previews/Morning.png) |
| **Sunrise** – lever de soleil doré | `shaders/Sunrise` | `skyboxes/Sunrise` | ![Sunrise](previews/Sunrise.png) |
| **Sunset** – coucher de soleil orange | `shaders/Sunset` | `skyboxes/Sunset` | ![Sunset](previews/Sunset.png) |
| **Night** – nuit au clair de lune | `shaders/Night` | `skyboxes/Night` | ![Night](previews/Night.png) |
| **Cycle** – les 5 ambiances en un seul shader | `shaders/Cycle` | (aucune, voir plus bas) | |

## Contenu

```
shaders/<Ambiance>/
    pack.json          (apiVersion 2)
    <ambiance>.wgsl
skyboxes/<Ambiance>/skyBoxes/default/
    px.jpg nx.jpg py.jpg ny.jpg pz.jpg nz.jpg     (1024x1024)
previews/              aperçus de l'horizon de chaque skybox
tools/make_sky.py      script qui génère les skyboxes
```

## Shaders

- Format : API shader Bloxd **version 2** (`apiVersion: 2`), écrits en WGSL.
- Ils modifient le terrain (`bloxdTerrainLight`) et l'eau (`bloxdLiquidSurface`, `bloxdLiquidLight`).
- Chaque shader a sa direction et sa couleur de soleil (`SUN_RAW`, `SUN_COLOUR`), sa couleur de brouillard et son ombrage.
- Un shader ne peut pas dessiner le ciel : l'API n'a pas de fonction pour ça. C'est pour ça qu'il y a des skyboxes à part.

## Ombres

Tous les shaders (Day, Morning, Sunrise, Sunset, Night et Cycle) ont des ombres sur les blocs :

- **Ombre du ciel** : un bloc est plus sombre et teinté s'il ne voit pas le ciel (sous un arbre, sous un toit). Elle vient de `skyLight`.
- **Côté sombre des blocs** : la face de chaque bloc tournée à l'opposé du soleil est assombrie, sur tous les blocs, même un cube posé au sol.

Réglages en haut de chaque fichier :

- `SHADOW_STRENGTH` : force des ombres (1 = normal, 0 = désactivées).
- `SHADOW_LEVEL_SHIFT` : taille des ombres du ciel (plus = plus grandes, moins = plus petites).
- `FACE_SHADOW` : côté sombre des blocs (1 = normal, 0 = désactivé).
- `SH_STRENGTH`, `SH_LOW`, `SH_HIGH`, `SH_COLOUR` : force, taille et couleur des ombres propres à l'ambiance (dans Cycle, ces 4 valeurs sont à la fin de chaque look dans `lookAt`).

Limites : l'API shader de Bloxd ne donne ni les blocs voisins ni de shadow map, donc pas d'ombres projetées sur le sol. L'ombre sous un arbre ne tourne pas avec le soleil ; seul le côté sombre des blocs le suit. Dans Day, Morning, Sunrise, Sunset et Night le soleil est fixe ; dans Cycle, la taille, la force et la couleur des ombres changent avec l'heure (grandes et colorées au lever et au coucher, petites à midi, faibles la nuit).

## Reflets

Tous les shaders ajoutent un reflet du soleil sur les blocs : un éclat visible quand on regarde vers le soleil, plus fort quand il est bas, absent dans l'ombre.

- `BLOCK_SHINE` : force des reflets (0 = désactivés, 0,5 = très brillant).
- `BLOCK_SHINE_POWER` : taille du reflet (petit = large et doux, grand = petit point net).
- `SHINE_DIRECT` (sauf Cycle) : sensibilité à la lumière directe de l'ambiance.

## Shader Cycle (tout en un)

`shaders/Cycle/cycle.wgsl` enchaîne Night → Sunrise → Morning → Day → Sunset → Night en fondu, d'après `bloxdTime()`.

- `CYCLE_SECONDS` : durée d'un cycle complet (doit diviser 3600 : 600, 900, 1200, 1800, 3600).
- `START_LOOK` : ambiance au démarrage (0 Night, 1 Sunrise, 2 Morning, 3 Day, 4 Sunset).
- `HOLD` : durée de chaque ambiance avant de passer à la suivante.
- `USE_GAME_SUN` : `true` par défaut, le shader suit le vrai soleil du jeu (`bloxdSunDirection()`) et reste synchro avec l'heure. Sans soleil dans le monde, il retombe sur l'horloge.
- `SUN_EAST` : direction de l'est. Mesuré sur le jeu : le soleil se lève côté +x, donc `vec3f(1,0,0)`. Si un jour le matin ressemble au soir, mets `vec3f(-1,0,0)`.
- `A_SUNRISE`, `A_MORNING`, `A_DAY`, `A_DAY_END`, `A_SUNSET` : angles du soleil (0 = lever, 1,57 = midi, 3,14 = coucher) qui règlent à quel moment de la journée chaque ambiance arrive (petit = plus tôt). `A_DAY` : le plein jour est atteint ; `A_DAY_END` : le fondu vers le soir commence ; `A_SUNSET` : le look Sunset est atteint.
- `SHADOW_STRENGTH`, `SHADOW_LEVEL_SHIFT`, `FACE_SHADOW`, `BLOCK_SHINE`, `BLOCK_SHINE_POWER` : ombres et reflets (voir plus haut). La taille, la force et la couleur des ombres de chaque ambiance sont dans `lookAt` et se fondent d'une ambiance à l'autre.
- Le shader ne change que le terrain et l'eau. Une skybox est fixe : elle ne change pas avec le cycle.

## Skyboxes

- Format Bloxd : six faces `.jpg` dans `skyBoxes/<nom>/` (`px`, `nx`, `py`, `ny`, `pz`, `nz`), comme dans [bloxdy/texture-packs](https://github.com/bloxdy/texture-packs).
- L'orientation des faces a été vérifiée sur la skybox par défaut du jeu (raccord des bords entre les faces).
- Chaque skybox reprend les couleurs et la direction du soleil (ou de la lune pour Night) de son shader.
- Le soleil est fixe dans l'image : il ne suit pas le temps du jeu.
- Les images sont générées par `tools/make_sky.py` (Python, `numpy` et `Pillow`) :

```bash
pip install numpy pillow
python tools/make_sky.py sortie            # les 5 skyboxes
python tools/make_sky.py sortie Sunrise    # une seule
```

## Licence

MIT, voir [LICENSE](LICENSE).
