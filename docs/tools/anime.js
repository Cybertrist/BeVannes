/**
 * Les schémas animés du README.
 *
 * Des SVG plutôt que des GIF : quelques kilo-octets, nets à toute taille,
 * et GitHub les joue même chargés par une balise <img>. Les animations sont
 * en SMIL (<animate>, <animateTransform>, <animateMotion>), la seule forme
 * d'animation qu'un SVG garde dans une <img>. Aucune police externe : une
 * image n'a pas le droit d'aller chercher quoi que ce soit sur le réseau.
 *
 * Chaque schéma boucle sur une durée fixe D ; un instant du scénario s'écrit
 * comme une fraction de D, et tout reste synchronisé d'un tour à l'autre.
 *
 *   node docs/tools/anime.js              rend le français dans docs/schemas/
 *   LANGUE=en node docs/tools/anime.js    rend l'anglais dans docs/en/schemas/
 */
const fs = require('node:fs');
const path = require('node:path');

const LG = process.env.LANGUE === 'en' ? 'en' : 'fr';
const t = (fr, en) => (LG === 'en' ? en : fr);
const OUT = path.join(__dirname, '..', LG === 'en' ? 'en/schemas' : 'schemas');

const SANS = 'system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif';
const MONO = 'ui-monospace,SFMono-Regular,Menlo,Consolas,monospace';

// La palette des autres figures du README, avec l'accent du logo.
const C = {
  bg: '#0C1117',
  card: '#121A21',
  card2: '#17222A',
  line: '#1F2C33',
  title: '#F1F5F9',
  text: '#94A3B0',
  faint: '#5E6E75',
  accent: '#39D2C0',
  pale: '#A7F3E6',
  deep: '#1C8F83',
  soft: '#0F2B27',
  flame: '#FF8A4C',
  gold: '#F5C451',
  night: '#02221E',
};

// --- Outils ---------------------------------------------------------------

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const k = (x) => Math.max(0, Math.min(1, Math.round(x * 1000) / 1000));

/** Complète une liste [instant, valeur] pour qu'elle couvre 0 à 1. */
function bornes(steps) {
  const pts = [...steps].sort((a, b) => a[0] - b[0]);
  if (pts[0][0] !== 0) pts.unshift([0, pts[0][1]]);
  if (pts.at(-1)[0] !== 1) pts.push([1, pts.at(-1)[1]]);
  return pts;
}

/** Une animation d'attribut qui boucle sur D secondes. */
function anim(D, attr, steps, { discrete = false } = {}) {
  const pts = bornes(steps);
  return `<animate attributeName="${attr}" dur="${D}s" repeatCount="indefinite" calcMode="${discrete ? 'discrete' : 'linear'}" keyTimes="${pts.map((p) => k(p[0])).join(';')}" values="${pts.map((p) => p[1]).join(';')}"/>`;
}

/** Un déplacement (translate x y) qui boucle sur D secondes. */
function move(D, steps) {
  const pts = bornes(steps);
  return `<animateTransform attributeName="transform" type="translate" dur="${D}s" repeatCount="indefinite" calcMode="linear" keyTimes="${pts.map((p) => k(p[0])).join(';')}" values="${pts.map((p) => p[1]).join(';')}"/>`;
}

/** Apparition en fondu à `from`, disparition à `to` (fractions de D). */
function appear(D, from, to = 0.96, fade = 0.025) {
  return anim(D, 'opacity', [
    [0, 0],
    [from, 0],
    [Math.min(from + fade, to), 1],
    [to, 1],
    [Math.min(to + fade, 1), 0],
  ]);
}

/** Un groupe invisible au départ, qui apparaît de `from` à `to`. */
const pendant = (D, from, to, contenu, fade) => `<g opacity="0">${appear(D, from, to, fade)}${contenu}</g>`;

function text(x, y, content, { size = 14, color = C.text, weight = 400, anchor = 'start', font = SANS, extra = '' } = {}) {
  return `<text x="${x}" y="${y}" font-family="${font}" font-size="${size}" font-weight="${weight}" fill="${color}" text-anchor="${anchor}" ${extra}>${esc(content)}</text>`;
}

function svg(width, height, body, label) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="${esc(label)}">
<defs>
  <linearGradient id="degrade" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${C.pale}"/><stop offset="1" stop-color="${C.accent}"/></linearGradient>
  <radialGradient id="halo"><stop offset="0" stop-color="${C.accent}" stop-opacity=".35"/><stop offset="1" stop-color="${C.accent}" stop-opacity="0"/></radialGradient>
</defs>
<rect width="${width}" height="${height}" fill="${C.bg}"/>
${body}
</svg>
`;
}

/** Le titre d'étape, en petites capitales, en haut à gauche d'un bloc. */
const etape = (x, y, a, b) =>
  text(x, y, a, { size: 11.5, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="1.5"' }) +
  (b ? text(x, y + 20, b, { size: 15, color: C.title, weight: 600 }) : '');

/** Un téléphone vu de face, en traits. */
const telephone = (x, y, w, h, contenu = '') =>
  `<g transform="translate(${x} ${y})"><rect width="${w}" height="${h}" rx="${w * 0.16}" fill="${C.card}" stroke="${C.line}" stroke-width="2"/><rect x="${w / 2 - 14}" y="8" width="28" height="5" rx="2.5" fill="${C.line}"/>${contenu}</g>`;

const LIEUX = [
  'Cathédrale Saint-Pierre',
  'Porte Saint-Vincent',
  "Château de l'Hermine",
  'Lavoirs de la Garenne',
  'Place Henri-IV',
  'La Cohue',
  'Porte Prison',
  'Place des Lices',
  'Pointe de Conleau',
  'Jardin des remparts',
  'Hôtel de Limur',
];

// --- 1. Le tirage du jour -------------------------------------------------

function tirage() {
  const D = 9;
  const W = 1280;
  const H = 380;
  let b = '';

  // La roulette : les noms défilent, ralentissent, et se posent.
  const rx = 70;
  const ry = 120;
  const rw = 470;
  const lh = 58;
  b += etape(rx, 60, t('01 · LE TIRAGE', '01 · THE DRAW'), t('Une graine par jour, un mélange par cycle', 'One seed per day, one shuffle per cycle'));
  b += `<rect x="${rx}" y="${ry}" width="${rw}" height="${lh * 3}" rx="18" fill="${C.card}" stroke="${C.line}"/>`;
  b += `<clipPath id="fenetre"><rect x="${rx}" y="${ry}" width="${rw}" height="${lh * 3}" rx="18"/></clipPath>`;
  const n = LIEUX.length;
  const fin = -(n - 2) * lh; // le dernier nom au centre
  let noms = '';
  LIEUX.forEach((nom, i) => {
    noms += text(rx + rw / 2, ry + lh * (i + 0.5) + 8, nom, {
      size: 22,
      color: i === n - 1 ? C.title : C.text,
      weight: i === n - 1 ? 700 : 500,
      anchor: 'middle',
    });
  });
  b += `<g clip-path="url(#fenetre)"><g>
  <animateTransform attributeName="transform" type="translate" dur="${D}s" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.06;0.46;0.92;1" keySplines="0 0 1 1;0.15 0.55 0.2 1;0 0 1 1;0 0 1 1" values="0 0;0 0;0 ${fin};0 ${fin};0 0"/>
  ${noms}</g></g>`;
  // Le cadre qui désigne la ligne retenue.
  b += `<rect x="${rx + 10}" y="${ry + lh}" width="${rw - 20}" height="${lh}" rx="12" fill="none" stroke="${C.accent}" stroke-width="2">${anim(D, 'stroke-opacity', [[0, 0.35], [0.46, 0.35], [0.49, 1], [0.92, 1], [0.95, 0.35]])}</rect>`;
  b += `<rect x="${rx}" y="${ry}" width="${rw}" height="${lh}" fill="${C.bg}" opacity=".55"/><rect x="${rx}" y="${ry + 2 * lh}" width="${rw}" height="${lh}" fill="${C.bg}" opacity=".55"/>`;
  b += text(rx, ry + lh * 3 + 42, t('Jeudi 24 septembre, jour 20 720', 'Thursday 24 September, day 20,720'), { size: 14, color: C.faint, font: MONO });

  // Trois téléphones, trois joueurs : le même lieu s'allume partout.
  const px = 700;
  b += etape(px, 60, t('02 · PARTOUT PAREIL', '02 · THE SAME EVERYWHERE'), t('Chaque téléphone refait le calcul', 'Every phone does the maths itself'));
  ['Maëlle', 'Yann', t('Toi', 'You')].forEach((qui, i) => {
    const x = px + i * 180;
    const y = 112;
    const contenu =
      text(75, 44, qui, { size: 13, color: C.faint, anchor: 'middle' }) +
      pendant(
        D,
        0.5 + i * 0.03,
        0.93,
        `<circle cx="75" cy="104" r="26" fill="url(#halo)"/><circle cx="75" cy="104" r="9" fill="url(#degrade)"/>` +
          text(75, 160, t('Hôtel de', 'Hôtel de'), { size: 14, color: C.title, weight: 600, anchor: 'middle' }) +
          text(75, 180, 'Limur', { size: 14, color: C.title, weight: 600, anchor: 'middle' }),
      ) +
      pendant(D, 0.02, 0.5, text(75, 118, '…', { size: 26, color: C.faint, anchor: 'middle' }), 0.02);
    b += telephone(x, y, 150, 216, contenu);
  });
  b += pendant(
    D,
    0.56,
    0.93,
    text(px, ry + lh * 3 + 42, t('Aucun serveur ne tire au sort : personne ne peut tricher sur le lieu.', 'No server draws anything: nobody can cheat on the spot.'), { size: 14, color: C.text }),
  );

  return svg(
    W,
    H,
    b,
    t(
      "Animation : une roulette fait défiler les lieux de Vannes, ralentit et s'arrête sur l'Hôtel de Limur. Au même instant, trois téléphones de trois joueurs affichent le même lieu : chacun refait le tirage lui-même, aucun serveur n'intervient.",
      'Animation: a wheel scrolls through the places of Vannes, slows down and stops on Hôtel de Limur. At the same moment, three phones belonging to three players show the same spot: each one redoes the draw itself, no server involved.',
    ),
  );
}

// --- 2. La validation sur place -------------------------------------------

function approche() {
  const D = 10;
  const W = 1280;
  const H = 420;
  let b = '';

  // La carte : quelques rues, la zone de 100 m, le radar.
  const mx = 40;
  const my = 40;
  const mw = 760;
  const mh = 340;
  b += `<rect x="${mx}" y="${my}" width="${mw}" height="${mh}" rx="22" fill="#0A1614" stroke="${C.line}"/>`;
  b += `<clipPath id="carte"><rect x="${mx}" y="${my}" width="${mw}" height="${mh}" rx="22"/></clipPath><g clip-path="url(#carte)" stroke="#16312C" fill="none" stroke-linecap="round">
  <path d="M40 300 C 220 280, 300 200, 520 190 S 760 120, 820 90" stroke-width="16"/>
  <path d="M160 40 L 240 380" stroke-width="10"/><path d="M420 40 C 440 160, 400 260, 470 380" stroke-width="12"/>
  <path d="M600 40 L 640 380" stroke-width="8"/><path d="M40 150 L 820 230" stroke-width="7"/>
  <path d="M700 60 L 800 300" stroke-width="6"/></g>`;
  const cx = 610;
  const cy = 180;
  const zone = 78;
  b += `<circle cx="${cx}" cy="${cy}" r="${zone}" fill="${C.accent}" stroke="${C.accent}" stroke-width="2">${anim(D, 'fill-opacity', [[0, 0.07], [0.62, 0.07], [0.66, 0.2], [0.94, 0.2], [0.97, 0.07]])}${anim(D, 'stroke-opacity', [[0, 0.45], [0.62, 0.45], [0.66, 1], [0.94, 1], [0.97, 0.45]])}</circle>`;
  for (let i = 0; i < 3; i++) {
    b += `<circle cx="${cx}" cy="${cy}" fill="none" stroke="${C.accent}" stroke-width="2"><animate attributeName="r" dur="2.4s" begin="${-i * 0.8}s" repeatCount="indefinite" values="8;${zone}"/><animate attributeName="stroke-opacity" dur="2.4s" begin="${-i * 0.8}s" repeatCount="indefinite" values=".8;0"/></circle>`;
  }
  b += `<circle cx="${cx}" cy="${cy}" r="9" fill="url(#degrade)" stroke="${C.bg}" stroke-width="3"/>`;
  b += text(cx, cy + zone + 24, '100 m', { size: 13, color: C.accent, anchor: 'middle', font: MONO, weight: 700 });

  // Le joueur qui marche vers le lieu.
  const chemin = `M110 330 C 220 300, 300 250, 380 230 S 520 200, ${cx - 26} ${cy + 14}`;
  b += `<path d="${chemin}" fill="none" stroke="#5AA9FF" stroke-opacity=".35" stroke-width="2.5" stroke-dasharray="4 8"/>`;
  b += `<g><animateMotion dur="${D}s" repeatCount="indefinite" path="${chemin}" keyPoints="0;0;1;1;0" keyTimes="0;0.05;0.64;0.96;1" calcMode="linear"/>
  <circle r="16" fill="#5AA9FF" fill-opacity=".22"/><circle r="8" fill="#5AA9FF" stroke="#fff" stroke-width="3"/></g>`;

  // À droite : la jauge, la distance, le bouton.
  const gx = 960;
  const gy = 150;
  const r = 62;
  const tour = 2 * Math.PI * r;
  b += etape(860, 68, t('LA JAUGE', 'THE GAUGE'), t("L'anneau se remplit en approchant", 'The ring fills as you get closer'));
  b += `<circle cx="${gx}" cy="${gy + 20}" r="${r}" fill="none" stroke="${C.card2}" stroke-width="10"/>`;
  b += `<circle cx="${gx}" cy="${gy + 20}" r="${r}" fill="none" stroke="url(#degrade)" stroke-width="10" stroke-linecap="round" stroke-dasharray="${tour.toFixed(1)}" transform="rotate(-90 ${gx} ${gy + 20})">${anim(D, 'stroke-dashoffset', [[0, tour * 0.96], [0.05, tour * 0.96], [0.2, tour * 0.72], [0.36, tour * 0.52], [0.5, tour * 0.3], [0.64, 0], [0.96, 0], [0.99, tour * 0.96]].map(([a, v]) => [a, v.toFixed(1)]))}</circle>`;
  const distances = [
    [0.0, 0.2, '1,2', 'km'],
    [0.2, 0.36, '640', t('mètres', 'metres')],
    [0.36, 0.5, '310', t('mètres', 'metres')],
    [0.5, 0.64, '150', t('mètres', 'metres')],
  ];
  distances.forEach(([a, z, v, u]) => {
    b += pendant(D, a, z, text(gx, gy + 26, v, { size: 30, color: C.title, weight: 700, anchor: 'middle', font: MONO }) + text(gx, gy + 48, u, { size: 12, color: C.faint, anchor: 'middle' }), 0.012);
  });
  b += pendant(D, 0.64, 0.96, `<path d="M${gx - 18} ${gy + 20} l12 12 l24 -26" fill="none" stroke="${C.accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>`, 0.02);

  // Le bouton : verrouillé, puis prêt, avec un reflet qui passe.
  const bx = 850;
  const by = 290;
  const bw = 330;
  b += `<rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14" fill="${C.card2}" stroke="${C.line}"/>`;
  b += pendant(D, 0.02, 0.64, text(bx + bw / 2, by + 33, t('Photo possible à moins de 100 m', 'Photo allowed within 100 m'), { size: 15, color: C.faint, weight: 600, anchor: 'middle' }), 0.015);
  b += `<clipPath id="bouton"><rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14"/></clipPath>`;
  b += pendant(
    D,
    0.65,
    0.96,
    `<rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14" fill="url(#degrade)"/>` +
      text(bx + bw / 2, by + 34, t('Prendre la photo', 'Take the photo'), { size: 17, color: C.night, weight: 700, anchor: 'middle' }) +
      `<g clip-path="url(#bouton)"><rect y="${by}" width="70" height="54" fill="#fff" opacity=".45" transform="skewX(-20)">${anim(D, 'x', [[0, bx - 120], [0.7, bx - 120], [0.78, bx + bw + 60], [1, bx + bw + 60]])}</rect></g>`,
  );

  return svg(
    W,
    H,
    b,
    t(
      "Animation : sur une carte, un joueur marche vers le lieu du jour, entouré d'une zone de cent mètres et d'ondes de radar. À droite, une jauge circulaire se remplit pendant que la distance descend, 1,2 km, 640 m, 310 m, 150 m. Quand le joueur entre dans la zone, la jauge est pleine, une coche apparaît et le bouton « Prendre la photo » se déverrouille.",
      'Animation: on a map, a player walks towards the spot of the day, surrounded by a hundred metre zone and radar waves. On the right, a circular gauge fills up while the distance drops, 1.2 km, 640 m, 310 m, 150 m. When the player enters the zone, the gauge is full, a tick appears and the "Take the photo" button unlocks.',
    ),
  );
}

// --- 3. Le cadre 3:4 ------------------------------------------------------

function cadrage() {
  const D = 8;
  const W = 1280;
  const H = 400;
  let b = '';
  b += etape(70, 60, t('LE CADRE', 'THE FRAME'), t("L'appareil rend ce qu'il veut, le jeu garde du 3:4", 'The camera returns whatever it likes, the game keeps 3:4'));

  // La photo brute, en 4:3 : un ciel, des toits, la Porte Saint-Vincent.
  const x = 150;
  const y = 136;
  const w = 320;
  const h = 240;
  const scene = `<g>
  <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="#1B3B4A"/>
  <rect x="${x}" y="${y}" width="${w}" height="${h * 0.55}" fill="#2B5E6E"/>
  <circle cx="${x + w * 0.8}" cy="${y + 50}" r="22" fill="${C.gold}" fill-opacity=".85"/>
  <path d="M${x} ${y + h} V${y + 160} l40 -30 l40 30 V${y + h} Z" fill="#274048"/>
  <path d="M${x + w} ${y + h} V${y + 150} l-50 -34 l-50 34 V${y + h} Z" fill="#274048"/>
  <path d="M${x + w / 2 - 70} ${y + h} V${y + 110} h140 V${y + h} Z" fill="#6B7F83"/>
  <path d="M${x + w / 2 - 30} ${y + h} V${y + 190} a30 30 0 0 1 60 0 V${y + h} Z" fill="#20343A"/>
  <path d="M${x + w / 2 - 80} ${y + 112} h160 l-20 -26 h-120 Z" fill="#8A9A9C"/>
</g>`;
  b += `<clipPath id="photo"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="16"/></clipPath><g clip-path="url(#photo)">${scene}</g>`;
  b += `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="16" fill="none" stroke="${C.line}" stroke-width="2"/>`;
  b += text(x, y - 14, t('Appareil photo · 4:3', 'Camera · 4:3'), { size: 13, color: C.faint, font: MONO });

  // Les deux bandes qui tombent de chaque côté, le cadre 3:4 qui reste.
  const cw = (h * 3) / 4; // 202,5
  const bande = (w - cw) / 2;
  b += `<rect y="${y}" width="${bande}" height="${h}" fill="${C.bg}" fill-opacity=".82">${anim(D, 'x', [[0, x - bande], [0.18, x - bande], [0.3, x], [0.9, x], [0.96, x - bande]])}</rect>`;
  b += `<rect y="${y}" width="${bande}" height="${h}" fill="${C.bg}" fill-opacity=".82">${anim(D, 'x', [[0, x + w], [0.18, x + w], [0.3, x + w - bande], [0.9, x + w - bande], [0.96, x + w]])}</rect>`;
  b += pendant(D, 0.3, 0.9, `<rect x="${x + bande}" y="${y}" width="${cw}" height="${h}" rx="4" fill="none" stroke="${C.accent}" stroke-width="3"/>`);

  // La flèche, puis la carte 3:4 qui part vers le mur du jour.
  b += pendant(D, 0.36, 0.9, `<path d="M${x + w + 40} ${y + h / 2} h120" stroke="${C.accent}" stroke-width="3" stroke-linecap="round"/><path d="M${x + w + 150} ${y + h / 2 - 10} l12 10 l-12 10" fill="none" stroke="${C.accent}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>`);
  const fx = 760;
  const fy = 90;
  const fw = 225;
  const fh = 300;
  b += `<clipPath id="finale"><rect x="${fx}" y="${fy}" width="${fw}" height="${fh}" rx="18"/></clipPath>`;
  b += pendant(
    D,
    0.42,
    0.9,
    `<g clip-path="url(#finale)"><g transform="translate(${fx - (x + bande) * (fw / cw)} ${fy - y * (fh / h)}) scale(${fw / cw} ${fh / h})">${scene}</g></g><rect x="${fx}" y="${fy}" width="${fw}" height="${fh}" rx="18" fill="none" stroke="${C.accent}" stroke-width="2"/>`,
  );
  b += pendant(D, 0.5, 0.9, text(fx + fw + 36, fy + 110, '3:4', { size: 44, color: C.title, weight: 800 }) + text(fx + fw + 36, fy + 146, '1200 × 1600 · JPEG', { size: 14, color: C.text, font: MONO }) + text(fx + fw + 36, fy + 176, t('Recadrée sur le téléphone,', 'Cropped on the phone,'), { size: 14, color: C.faint }) + text(fx + fw + 36, fy + 196, t('avant l’envoi.', 'before upload.'), { size: 14, color: C.faint }));

  return svg(
    W,
    H,
    b,
    t(
      "Animation : une photo prise en 4:3 montre une porte de ville sous le soleil. Deux bandes sombres tombent de chaque côté et ne laissent qu'un cadre 3:4 en portrait, qui part ensuite vers la droite : 3:4, 1200 × 1600 en JPEG, recadrée sur le téléphone avant l'envoi.",
      'Animation: a photo taken in 4:3 shows a city gate in the sun. Two dark bands drop on either side, leaving only a 3:4 portrait frame, which then moves to the right: 3:4, 1200 × 1600 JPEG, cropped on the phone before upload.',
    ),
  );
}

// --- 4. Les points et la série --------------------------------------------

function serie() {
  const D = 9;
  const W = 1280;
  const H = 380;
  let b = '';
  b += etape(70, 60, t('LA SÉRIE', 'THE STREAK'), t('Dix points par lieu, deux de plus par jour de série', 'Ten points per spot, two more per day in a row'));

  const jours = t('LUN MAR MER JEU VEN SAM DIM', 'MON TUE WED THU FRI SAT SUN').split(' ');
  const gains = [10, 12, 14, 16, 18, 20, 20];
  const x0 = 110;
  const pas = 118;
  const base = 320;
  const echelle = 8.5;
  let total = 0;
  const cumuls = [];
  gains.forEach((g, i) => {
    total += g;
    cumuls.push(total);
    const x = x0 + i * pas;
    const hBar = g * echelle;
    const a = 0.06 + i * 0.1;
    // La barre qui monte, du bas vers le haut.
    b += `<rect x="${x}" width="64" rx="10" fill="url(#degrade)">${anim(D, 'y', [[0, base], [a, base], [a + 0.06, base - hBar], [0.93, base - hBar], [0.97, base]])}${anim(D, 'height', [[0, 0], [a, 0], [a + 0.06, hBar], [0.93, hBar], [0.97, 0]])}</rect>`;
    b += text(x + 32, base + 28, jours[i], { size: 13, color: C.faint, anchor: 'middle', font: MONO, weight: 700 });
    b += pendant(D, a + 0.05, 0.93, text(x + 32, base - hBar + 28, `+${g}`, { size: 17, color: C.night, anchor: 'middle', weight: 800, font: MONO }));
    // La flamme de série, qui s'allume à partir du deuxième jour.
    if (i > 0) {
      b += pendant(D, a + 0.05, 0.93, `<path transform="translate(${x + 32} ${base - hBar - 22}) scale(1.1)" d="M0 -13 C 6 -6, 9 -2, 9 3 A 9 9 0 0 1 -9 3 C -9 -1, -6 -4, -4 -8 C -3 -4, -1 -3, 0 -3 C 0 -7, -1 -10, 0 -13 Z" fill="${C.flame}"/>`);
    }
  });
  // Le plafond du bonus.
  const plafond = base - 20 * echelle;
  b += pendant(D, 0.62, 0.93, `<path d="M${x0 - 20} ${plafond - 0.5} H${x0 + 6 * pas + 84}" stroke="${C.gold}" stroke-width="1.5" stroke-dasharray="6 6"/>` + text(x0 + 6 * pas + 92, plafond + 5, t('bonus plafonné', 'bonus capped'), { size: 13, color: C.gold }));

  // Le compteur de droite.
  const kx = 1040;
  b += text(kx, 150, t('TOTAL', 'TOTAL'), { size: 11.5, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="1.5"' });
  cumuls.forEach((c, i) => {
    const a = 0.06 + i * 0.1 + 0.05;
    const z = i < cumuls.length - 1 ? 0.06 + (i + 1) * 0.1 + 0.05 : 0.93;
    b += pendant(D, a, z, text(kx, 210, String(c), { size: 58, color: C.title, weight: 800, font: MONO }), 0.01);
  });
  b += pendant(D, 0.0, 0.11, text(kx, 210, '0', { size: 58, color: C.faint, weight: 800, font: MONO }), 0.01);
  b += text(kx, 240, t('points en une semaine', 'points in one week'), { size: 14, color: C.text });
  b += pendant(D, 0.7, 0.93, text(kx, 280, t('Un jour manqué :', 'Miss a day:'), { size: 14, color: C.faint }) + text(kx, 300, t('la série repart à 1.', 'the streak resets to 1.'), { size: 14, color: C.faint }));

  return svg(
    W,
    H,
    b,
    t(
      "Animation : sept barres montent l'une après l'autre, du lundi au dimanche, +10, +12, +14, +16, +18, +20, +20. Une flamme s'allume au-dessus de chaque jour de série, et un trait marque le plafond du bonus. Le total grimpe jusqu'à 110 points en une semaine ; un jour manqué, la série repart à 1.",
      'Animation: seven bars rise one after another, Monday to Sunday, +10, +12, +14, +16, +18, +20, +20. A flame lights up above every day of the streak, and a line marks the bonus cap. The total climbs to 110 points in one week; miss a day and the streak resets to 1.',
    ),
  );
}

// --- 5. Le mur du jour ----------------------------------------------------

function mur() {
  const D = 9;
  const W = 1280;
  const H = 400;
  let b = '';
  b += etape(70, 60, t('LE MUR DU JOUR', "TODAY'S WALL"), t('Comme BeReal : poster la sienne pour voir celles des autres', 'Like BeReal: post yours to see everyone else’s'));

  const tw = 150;
  const th = 200;
  const y = 120;
  const x0 = 110;
  const pas = 180;
  const teintes = [
    ['#2B5E6E', '#1B3B4A'],
    ['#6B4E7A', '#2E2340'],
    ['#7A6A3E', '#3A3020'],
    ['#3E6B52', '#1F3A2C'],
  ];
  const noms = ['Maëlle', 'Yann', 'Erwan', 'Klervi'];
  const revele = 0.52;
  noms.forEach((nom, i) => {
    const x = x0 + i * pas;
    const [c1, c2] = teintes[i];
    b += `<linearGradient id="p${i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient>`;
    b += `<clipPath id="t${i}"><rect x="${x}" y="${y}" width="${tw}" height="${th}" rx="16"/></clipPath>`;
    // La vraie photo, dessous.
    b += `<g clip-path="url(#t${i})"><rect x="${x}" y="${y}" width="${tw}" height="${th}" fill="url(#p${i})"/><path d="M${x} ${y + th} V${y + 120 + (i % 2) * 14} l${tw * 0.3} -${36 + i * 6} l${tw * 0.25} 22 l${tw * 0.45} -${30 + i * 4} V${y + th} Z" fill="#000" fill-opacity=".28"/><circle cx="${x + tw * 0.72}" cy="${y + 48}" r="16" fill="#fff" fill-opacity=".25"/></g>`;
    // Le voile verrouillé, qui se lève une fois la photo publiée.
    b += `<g>${anim(D, 'opacity', [[0, 1], [revele + i * 0.04, 1], [revele + i * 0.04 + 0.05, 0], [0.93, 0], [0.97, 1]])}
  <rect x="${x}" y="${y}" width="${tw}" height="${th}" rx="16" fill="${C.card2}"/>
  <rect x="${x + tw / 2 - 12}" y="${y + th / 2 - 4}" width="24" height="20" rx="4" fill="${C.faint}"/>
  <path d="M${x + tw / 2 - 7} ${y + th / 2 - 4} v-6 a7 7 0 0 1 14 0 v6" fill="none" stroke="${C.faint}" stroke-width="3"/></g>`;
    b += `<rect x="${x}" y="${y}" width="${tw}" height="${th}" rx="16" fill="none" stroke="${C.line}"/>`;
    b += text(x, y + th + 26, nom, { size: 14, color: C.title, weight: 600 });
    b += text(x + tw, y + th + 26, ['08:41', '09:17', '11:02', '12:26'][i], { size: 13, color: C.faint, anchor: 'end', font: MONO });
  });

  // Sa propre photo, qui arrive dans la dernière case.
  const mx = x0 + 4 * pas + 30;
  b += `<rect x="${mx}" y="${y}" width="${tw}" height="${th}" rx="16" fill="none" stroke="${C.line}" stroke-dasharray="6 7"/>`;
  b += pendant(D, 0.06, 0.3, text(mx + tw / 2, y + th / 2 + 6, '?', { size: 34, color: C.faint, anchor: 'middle', weight: 700 }), 0.02);
  b += `<g opacity="0">${appear(D, 0.3, 0.93, 0.04)}${move(D, [[0, '0 -60'], [0.3, '0 -60'], [0.4, '0 0'], [1, '0 0']])}
  <clipPath id="moi"><rect x="${mx}" y="${y}" width="${tw}" height="${th}" rx="16"/></clipPath>
  <g clip-path="url(#moi)"><rect x="${mx}" y="${y}" width="${tw}" height="${th}" fill="#1E4C4A"/><path d="M${mx} ${y + th} V${y + 100} h${tw * 0.34} v-40 h${tw * 0.32} v40 h${tw * 0.34} V${y + th} Z" fill="#000" fill-opacity=".3"/></g>
  <rect x="${mx}" y="${y}" width="${tw}" height="${th}" rx="16" fill="none" stroke="${C.accent}" stroke-width="3"/>
</g>`;
  b += pendant(D, 0.36, 0.93, text(mx, y + th + 26, t('Toi', 'You'), { size: 14, color: C.accent, weight: 700 }) + text(mx + tw, y + th + 26, '12:48', { size: 13, color: C.faint, anchor: 'end', font: MONO }));

  // La légende qui suit l'histoire.
  b += pendant(D, 0.02, 0.3, text(x0, 372, t('Quatre joueurs sont passés : leurs photos restent verrouillées.', 'Four players have been: their photos stay locked.'), { size: 14, color: C.faint }), 0.02);
  b += pendant(D, 0.3, 0.52, text(x0, 372, t('Tu publies la tienne, prise sur place…', 'You post yours, taken on site…'), { size: 14, color: C.text }), 0.02);
  b += pendant(D, 0.52, 0.93, text(x0, 372, t('…et le mur se dévoile. Storage le vérifie lui-même, pas l’application.', '…and the wall opens up. Storage checks it itself, not the app.'), { size: 14, color: C.title }), 0.02);

  return svg(
    W,
    H,
    b,
    t(
      "Animation : quatre photos du jour, de Maëlle, Yann, Erwan et Klervi, sont verrouillées. Une cinquième photo, la tienne, arrive dans la dernière case. Les verrous sautent alors l'un après l'autre et les quatre photos se dévoilent. C'est Storage qui vérifie, pas l'application.",
      "Animation: four photos of the day, from Maëlle, Yann, Erwan and Klervi, are locked. A fifth photo, yours, drops into the last slot. The locks then come off one after another and the four photos are revealed. Storage does the checking, not the app.",
    ),
  );
}

// --- 6. Le rappel ---------------------------------------------------------

function rappel() {
  const D = 10;
  const W = 1280;
  const H = 380;
  let b = '';
  b += etape(70, 60, t('LE RAPPEL', 'THE REMINDER'), t('Une heure différente chaque jour, la même pour tout le monde', 'A different time every day, the same for everyone'));

  // Les vraies heures de heureDuRappel(), du 23 au 26 septembre 2026.
  const jours = [
    [t('Mercredi', 'Wednesday'), 17, 54],
    [t('Jeudi', 'Thursday'), 14, 43],
    [t('Vendredi', 'Friday'), 13, 18],
    [t('Samedi', 'Saturday'), 17, 51],
  ];
  const cx = 230;
  const cy = 215;
  const r = 92;
  // Le cadran.
  b += `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${C.card}" stroke="${C.line}" stroke-width="2"/>`;
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    const l = i % 3 === 0 ? 12 : 6;
    b += `<path d="M${cx + Math.sin(a) * (r - 8)} ${cy - Math.cos(a) * (r - 8)} L${cx + Math.sin(a) * (r - 8 - l)} ${cy - Math.cos(a) * (r - 8 - l)}" stroke="${i % 3 === 0 ? C.text : C.faint}" stroke-width="${i % 3 === 0 ? 3 : 2}" stroke-linecap="round"/>`;
  }
  // Les aiguilles tournent d'une heure à la suivante.
  const pas = 0.24;
  const angleH = ([, h, m]) => ((h % 12) + m / 60) * 30;
  const angleM = ([, , m]) => m * 6;
  const tours = (f) => {
    const vals = [];
    let cumul = 0;
    let prec = null;
    jours.forEach((j, i) => {
      let a = f(j);
      if (prec !== null) {
        while (a + cumul < prec) cumul += 360;
      }
      a += cumul;
      vals.push([0.02 + i * pas, a], [0.02 + i * pas + 0.08, a]);
      prec = a;
    });
    return vals;
  };
  const rot = (steps) => {
    const pts = bornes(steps);
    return `<animateTransform attributeName="transform" type="rotate" dur="${D}s" repeatCount="indefinite" calcMode="spline" keyTimes="${pts.map((p) => k(p[0])).join(';')}" keySplines="${pts.slice(1).map(() => '0.4 0 0.2 1').join(';')}" values="${pts.map((p) => `${p[1].toFixed(1)} ${cx} ${cy}`).join(';')}"/>`;
  };
  b += `<path d="M${cx} ${cy} V${cy - 50}" stroke="${C.title}" stroke-width="6" stroke-linecap="round">${rot(tours(angleH))}</path>`;
  b += `<path d="M${cx} ${cy} V${cy - 74}" stroke="${C.accent}" stroke-width="4" stroke-linecap="round">${rot(tours(angleM))}</path>`;
  b += `<circle cx="${cx}" cy="${cy}" r="7" fill="${C.accent}" stroke="${C.bg}" stroke-width="3"/>`;

  // Le jour et l'heure, à droite du cadran.
  jours.forEach(([nom, h, m], i) => {
    const a = 0.02 + i * pas + 0.05;
    const z = i < jours.length - 1 ? 0.02 + (i + 1) * pas + 0.05 : 0.96;
    b += pendant(D, a, z, text(360, 190, nom, { size: 16, color: C.faint }) + text(360, 240, `${h} h ${String(m).padStart(2, '0')}`, { size: 46, color: C.title, weight: 800 }), 0.015);
  });

  // Trois téléphones qui vibrent ensemble, la notification qui descend.
  const px = 700;
  ['Maëlle', 'Yann', t('Toi', 'You')].forEach((qui, i) => {
    const x = px + i * 180;
    let notif = '';
    jours.forEach(([, h, m], j) => {
      const a = 0.02 + j * pas + 0.07;
      notif += `<g opacity="0">${appear(D, a, a + 0.14, 0.02)}${move(D, [[0, '0 -18'], [a, '0 -18'], [a + 0.03, '0 0'], [1, '0 0']])}
  <rect x="10" y="40" width="130" height="58" rx="12" fill="${C.card2}" stroke="${C.accent}" stroke-opacity=".6"/>
  ${text(22, 62, 'BeVannes', { size: 12, color: C.accent, weight: 700 })}
  ${text(128, 62, `${h}:${String(m).padStart(2, '0')}`, { size: 11, color: C.faint, anchor: 'end', font: MONO })}
  ${text(22, 84, t("C'est l'heure !", "It's time!"), { size: 13, color: C.title, weight: 600 })}</g>`;
    });
    const secousses = jours
      .map((_, j) => {
        const a = 0.02 + j * pas + 0.07;
        return [
          [a, '0 0'],
          [a + 0.005, '-3 0'],
          [a + 0.01, '3 0'],
          [a + 0.015, '-3 0'],
          [a + 0.02, '0 0'],
        ];
      })
      .flat();
    b += `<g><g>${move(D, [[0, '0 0'], ...secousses])}${telephone(x, 110, 150, 216, text(75, 190, qui, { size: 13, color: C.faint, anchor: 'middle' }) + notif)}</g></g>`;
  });
  b += text(px, 360, t('Calculée sur chaque téléphone : aucune notification ne passe par un serveur.', 'Worked out on each phone: no notification goes through a server.'), { size: 14, color: C.faint });

  return svg(
    W,
    H,
    b,
    t(
      "Animation : les aiguilles d'une horloge sautent d'une heure à l'autre, mercredi 17 h 54, jeudi 14 h 43, vendredi 13 h 18, samedi 17 h 51. À chaque heure, trois téléphones vibrent en même temps et la même notification descend : « C'est l'heure ! ». Le calcul se fait sur chaque téléphone, sans serveur.",
      "Animation: a clock's hands jump from one time to the next, Wednesday 17:54, Thursday 14:43, Friday 13:18, Saturday 17:51. At each time, three phones buzz together and the same notification drops down: \"It's time!\". The maths happens on each phone, no server involved.",
    ),
  );
}

// --- Écriture -------------------------------------------------------------

fs.mkdirSync(OUT, { recursive: true });
for (const [nom, f] of Object.entries({ tirage, approche, cadrage, serie, mur, rappel })) {
  const contenu = f();
  fs.writeFileSync(path.join(OUT, `${nom}.svg`), contenu);
  console.log(`  ${nom}.svg  ${(contenu.length / 1024).toFixed(1)} Ko`);
}
