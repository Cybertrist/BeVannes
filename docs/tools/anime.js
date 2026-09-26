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

/** Visible de `from` à `to`, sans fondu : pour les chiffres qui se succèdent. */
const net = (D, from, to, contenu) => `<g opacity="0">${anim(D, 'opacity', [[0, 0], [from, 1], [to, 0]], { discrete: true })}${contenu}</g>`;

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
  const H = 430;
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
  b += text(rx, ry + lh * 3 + 88, t('Jeudi 24 septembre, jour 20 720', 'Thursday 24 September, day 20,720'), { size: 14, color: C.faint, font: MONO });

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
    text(px, ry + lh * 3 + 88, t('Aucun serveur ne tire au sort : personne ne peut tricher sur le lieu.', 'No server draws anything: nobody can cheat on the spot.'), { size: 14, color: C.text }),
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

/** Longueur d'une polyligne, et le point à une fraction de sa longueur. */
function longueur(pts) {
  let l = 0;
  for (let i = 1; i < pts.length; i++) l += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
  return l;
}
function pointA(pts, f) {
  let reste = longueur(pts) * f;
  for (let i = 1; i < pts.length; i++) {
    const [ax, ay] = pts[i - 1];
    const [bx, by] = pts[i];
    const l = Math.hypot(bx - ax, by - ay);
    if (reste <= l) return [ax + ((bx - ax) * reste) / l, ay + ((by - ay) * reste) / l];
    reste -= l;
  }
  return pts.at(-1);
}
const polyligne = (pts) => 'M' + pts.map((p) => p.join(' ')).join(' L');

/** Remplissage de la jauge, la même formule que JaugeApproche dans l'appli. */
const remplissage = (m) => (m <= 100 ? 1 : Math.max(0.04, 1 - Math.log(m / 100) / Math.log(30)));

function approche() {
  const D = 11;
  const W = 1280;
  const H = 420;
  let b = '';

  // La carte : des rues droites, comme un quartier vu d'en haut.
  const mx = 40;
  const my = 40;
  const mw = 760;
  const mh = 340;
  b += `<rect x="${mx}" y="${my}" width="${mw}" height="${mh}" rx="22" fill="#0A1614" stroke="${C.line}"/>`;
  const rues = [
    [[[40, 322], [300, 300], [820, 262]], 18],
    [[[300, 40], [300, 380]], 12],
    [[[40, 190], [300, 170], [560, 140], [820, 110]], 12],
    [[[560, 40], [560, 380]], 11],
    [[[430, 40], [440, 380]], 8],
    [[[690, 40], [705, 380]], 8],
    [[[150, 40], [165, 380]], 7],
  ];
  b += `<clipPath id="carte"><rect x="${mx}" y="${my}" width="${mw}" height="${mh}" rx="22"/></clipPath><g clip-path="url(#carte)" fill="none" stroke-linecap="round" stroke-linejoin="round">`;
  for (const [pts, e] of rues) b += `<path d="${polyligne(pts)}" stroke="#17332E" stroke-width="${e}"/>`;
  b += '</g>';

  // Le lieu, sur la rue verticale, avec sa zone de 100 m et le radar.
  const cx = 560;
  const cy = 212;
  const zone = 78; // 78 px pour 100 m
  const metresParPx = 100 / zone;

  // L'itinéraire : il suit les rues, virage après virage.
  const route = [
    [90, 318],
    [300, 300],
    [300, 170],
    [560, 140],
    [560, cy - 12],
  ];
  const depart = 0.05;
  const arrivee = 0.6;
  b += `<path d="${polyligne(route)}" fill="none" stroke="#5AA9FF" stroke-opacity=".28" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>`;
  b += `<path d="${polyligne(route)}" fill="none" stroke="#5AA9FF" stroke-opacity=".8" stroke-width="2.5" stroke-dasharray="2 9" stroke-linecap="round" stroke-linejoin="round"/>`;

  // Les instants clés, calculés sur la route elle-même.
  const echantillons = Array.from({ length: 61 }, (_, i) => {
    const f = i / 60;
    const [x, y] = pointA(route, f);
    return { t: depart + f * (arrivee - depart), m: Math.hypot(x - cx, y - cy) * metresParPx };
  });
  const entree = echantillons.find((e) => e.m <= 100).t;

  b += `<circle cx="${cx}" cy="${cy}" r="${zone}" fill="${C.accent}" stroke="${C.accent}" stroke-width="2">${anim(D, 'fill-opacity', [[0, 0.07], [entree, 0.07], [entree + 0.03, 0.2], [0.94, 0.2], [0.97, 0.07]])}${anim(D, 'stroke-opacity', [[0, 0.45], [entree, 0.45], [entree + 0.03, 1], [0.94, 1], [0.97, 0.45]])}</circle>`;
  for (let i = 0; i < 3; i++) {
    b += `<circle cx="${cx}" cy="${cy}" fill="none" stroke="${C.accent}" stroke-width="2"><animate attributeName="r" dur="2.4s" begin="${-i * 0.8}s" repeatCount="indefinite" values="8;${zone}"/><animate attributeName="stroke-opacity" dur="2.4s" begin="${-i * 0.8}s" repeatCount="indefinite" values=".8;0"/></circle>`;
  }
  b += `<circle cx="${cx}" cy="${cy}" r="9" fill="url(#degrade)" stroke="${C.bg}" stroke-width="3"/>`;
  b += text(cx + zone + 10, cy + 5, '100 m', { size: 13, color: C.accent, font: MONO, weight: 700 });

  // Le joueur, qui suit exactement l'itinéraire, puis s'efface.
  b += `<g><animateMotion dur="${D}s" repeatCount="indefinite" path="${polyligne(route)}" keyPoints="0;0;1;1" keyTimes="0;${depart};${arrivee};1" calcMode="linear"/>
  ${anim(D, 'opacity', [[0, 0], [0.02, 1], [0.93, 1], [0.97, 0]])}
  <circle r="16" fill="#5AA9FF" fill-opacity=".22"/><circle r="8" fill="#5AA9FF" stroke="#fff" stroke-width="3"/></g>`;

  // À droite : la jauge et la distance, calculées à chaque pas.
  const gx = 960;
  const gy = 170;
  const r = 62;
  const tour = 2 * Math.PI * r;
  b += etape(860, 68, t('LA JAUGE', 'THE GAUGE'), t("L'anneau se remplit en approchant", 'The ring fills as you get closer'));
  b += `<circle cx="${gx}" cy="${gy}" r="${r}" fill="none" stroke="${C.card2}" stroke-width="10"/>`;
  const jauge = echantillons.filter((_, i) => i % 3 === 0).map((e) => [e.t, (tour * (1 - remplissage(e.m))).toFixed(1)]);
  b += `<circle cx="${gx}" cy="${gy}" r="${r}" fill="none" stroke="url(#degrade)" stroke-width="10" stroke-linecap="round" stroke-dasharray="${tour.toFixed(1)}" transform="rotate(-90 ${gx} ${gy})">${anim(D, 'stroke-dashoffset', [[0, jauge[0][1]], ...jauge, [0.94, '0'], [0.98, jauge[0][1]]])}</circle>`;
  // La distance : un chiffre par pas, arrondi comme dans l'appli.
  const pas = echantillons.filter((e, i) => i % 4 === 0 && e.t < entree);
  pas.forEach((e, i) => {
    const fin = i < pas.length - 1 ? pas[i + 1].t : entree;
    const v = `${Math.round(e.m / 10) * 10}`;
    b += net(D, e.t, fin, text(gx, gy + 6, v, { size: 30, color: C.title, weight: 700, anchor: 'middle', font: MONO }) + text(gx, gy + 28, t('mètres', 'metres'), { size: 12, color: C.faint, anchor: 'middle' }));
  });
  b += pendant(D, entree, 0.94, `<path d="M${gx - 18} ${gy} l12 12 l24 -26" fill="none" stroke="${C.accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>`, 0.02);

  // Le bouton : verrouillé, puis prêt, avec un reflet qui passe.
  const bx = 850;
  const by = 290;
  const bw = 330;
  b += `<rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14" fill="${C.card2}" stroke="${C.line}"/>`;
  b += pendant(D, 0.02, entree, text(bx + bw / 2, by + 33, t('Photo possible à moins de 100 m', 'Photo allowed within 100 m'), { size: 15, color: C.faint, weight: 600, anchor: 'middle' }), 0.015);
  b += `<clipPath id="bouton"><rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14"/></clipPath>`;
  b += pendant(
    D,
    entree + 0.01,
    0.94,
    `<rect x="${bx}" y="${by}" width="${bw}" height="54" rx="14" fill="url(#degrade)"/>` +
      text(bx + bw / 2, by + 34, t('Prendre la photo', 'Take the photo'), { size: 17, color: C.night, weight: 700, anchor: 'middle' }) +
      `<g clip-path="url(#bouton)"><rect y="${by}" width="70" height="54" fill="#fff" opacity=".45" transform="skewX(-20)">${anim(D, 'x', [[0, bx - 120], [entree + 0.08, bx - 120], [entree + 0.16, bx + bw + 60], [1, bx + bw + 60]])}</rect></g>`,
  );

  const m0 = Math.round(echantillons[0].m / 10) * 10;
  return svg(
    W,
    H,
    b,
    t(
      `Animation : sur une carte, un joueur suit un itinéraire le long des rues, trois virages, jusqu'au lieu du jour entouré d'une zone de cent mètres et d'ondes de radar. À droite, une jauge circulaire se remplit pendant que la distance descend depuis ${m0} mètres. Quand le joueur entre dans la zone, la jauge est pleine, une coche apparaît et le bouton « Prendre la photo » se déverrouille.`,
      `Animation: on a map, a player follows a route along the streets, three turns, to the spot of the day surrounded by a hundred metre zone and radar waves. On the right, a circular gauge fills while the distance drops from ${m0} metres. When the player enters the zone, the gauge is full, a tick appears and the "Take the photo" button unlocks.`,
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
  b += pendant(D, 0.5, 0.9, text(fx + fw + 36, fy + 110, '3:4', { size: 44, color: C.title, weight: 800 }) + text(fx + fw + 36, fy + 146, '900 × 1200 · JPEG', { size: 14, color: C.text, font: MONO }) + text(fx + fw + 36, fy + 176, t('Recadrée sur le téléphone,', 'Cropped on the phone,'), { size: 14, color: C.faint }) + text(fx + fw + 36, fy + 196, t('avant l’envoi.', 'before upload.'), { size: 14, color: C.faint }));

  return svg(
    W,
    H,
    b,
    t(
      "Animation : une photo prise en 4:3 montre une porte de ville sous le soleil. Deux bandes sombres tombent de chaque côté et ne laissent qu'un cadre 3:4 en portrait, qui part ensuite vers la droite : 3:4, 900 × 1200 en JPEG, recadrée sur le téléphone avant l'envoi.",
      'Animation: a photo taken in 4:3 shows a city gate in the sun. Two dark bands drop on either side, leaving only a 3:4 portrait frame, which then moves to the right: 3:4, 900 × 1200 JPEG, cropped on the phone before upload.',
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
  const H = 430;
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
  b += pendant(D, 0.02, 0.3, text(x0, 398, t('Quatre joueurs sont passés : leurs photos restent verrouillées.', 'Four players have been: their photos stay locked.'), { size: 14, color: C.faint }), 0.02);
  b += pendant(D, 0.3, 0.52, text(x0, 398, t('Tu publies la tienne, prise sur place…', 'You post yours, taken on site…'), { size: 14, color: C.text }), 0.02);
  b += pendant(D, 0.52, 0.93, text(x0, 398, t('…et le mur se dévoile. Firestore le vérifie lui-même, pas l’application.', '…and the wall opens up. Firestore checks it itself, not the app.'), { size: 14, color: C.title }), 0.02);

  return svg(
    W,
    H,
    b,
    t(
      "Animation : quatre photos du jour, de Maëlle, Yann, Erwan et Klervi, sont verrouillées. Une cinquième photo, la tienne, arrive dans la dernière case. Les verrous sautent alors l'un après l'autre et les quatre photos se dévoilent. C'est Firestore qui vérifie, pas l'application.",
      "Animation: four photos of the day, from Maëlle, Yann, Erwan and Klervi, are locked. A fifth photo, yours, drops into the last slot. The locks then come off one after another and the four photos are revealed. Firestore does the checking, not the app.",
    ),
  );
}

// --- 6. Le rappel ---------------------------------------------------------

function rappel() {
  const D = 10;
  const W = 1280;
  const H = 420;
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
  for (const [n, a] of [[12, 0], [3, 90], [6, 180], [9, 270]]) {
    const rad = (a * Math.PI) / 180;
    b += text(cx + Math.sin(rad) * (r - 34), cy - Math.cos(rad) * (r - 34) + 6, String(n), { size: 16, color: C.text, anchor: 'middle', weight: 700 });
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
      // Les aiguilles tiennent l'heure tant qu'elle est affichée, puis
      // tournent vers la suivante dans les derniers instants.
      const arrive = 0.02 + i * pas;
      const repart = i < jours.length - 1 ? arrive + pas - 0.07 : 0.96;
      vals.push([arrive, a], [repart, a]);
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
    // Affichée pendant que les aiguilles la montrent, masquée pendant
    // qu'elles tournent vers la suivante.
    const a = 0.02 + i * pas;
    const z = i < jours.length - 1 ? a + pas - 0.07 : 0.96;
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
  b += text(px, 380, t('Calculée sur chaque téléphone : aucune notification ne passe par un serveur.', 'Worked out on each phone: no notification goes through a server.'), { size: 14, color: C.faint });

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

// --- 7. La vitrine : les vrais écrans, dans un téléphone ------------------

function vitrine() {
  const D = 21;
  const W = 1280;
  const H = 640;
  const ecrans = [
    [t('Connexion', 'Sign in'), t('Un compte, un pseudo.', 'One account, one nickname.'), t('En démo, n’importe quelle adresse suffit.', 'In the demo, any address will do.')],
    [t('Le lieu du jour', "Today's spot"), t('La carte, la zone de cent mètres,', 'The map, the hundred metre zone,'), t('la note du lieu et la distance qui reste.', 'the note on the place and the distance left.')],
    [t('Sur place', 'On site'), t('La jauge est pleine, le bouton s’allume.', 'The gauge is full, the button lights up.'), t('Il n’y a plus qu’à déclencher.', 'All that is left is to shoot.')],
    [t('Validé', 'Validated'), t('La coche se dessine, les confettis partent,', 'The tick draws itself, confetti bursts out,'), t('les points tombent.', 'the points come in.')],
    [t('Le classement', 'The leaderboard'), t('Sa place, le podium,', 'Your rank, the podium,'), t('et la série en cours de chacun.', 'and everyone’s current streak.')],
    [t('Le profil', 'The profile'), t('Ses chiffres, les lieux découverts', 'Your numbers, the places found'), t('et l’heure du prochain rappel.', 'and the time of the next reminder.')],
  ];
  const n = ecrans.length;
  const tranche = 1 / n;
  const glisse = 0.022;

  // Le téléphone.
  const ew = 250;
  const eh = Math.round((ew * 2400) / 1080);
  const px = 150;
  const py = (H - eh) / 2;
  let b = '';
  b += `<ellipse cx="${px + ew / 2}" cy="${py + eh / 2}" rx="${ew}" ry="${eh / 2}" fill="url(#halo)" opacity=".7"/>`;
  b += `<rect x="${px - 10}" y="${py - 10}" width="${ew + 20}" height="${eh + 20}" rx="38" fill="#05090C" stroke="${C.line}" stroke-width="2"/>`;
  b += `<clipPath id="ecran"><rect x="${px}" y="${py}" width="${ew}" height="${eh}" rx="28"/></clipPath>`;
  let bande = '';
  ecrans.forEach((_, i) => {
    const donnees = fs.readFileSync(path.join(__dirname, 'vitrine', `0${i + 1}.jpg`)).toString('base64');
    bande += `<image x="${px + i * ew}" y="${py}" width="${ew}" height="${eh}" preserveAspectRatio="xMidYMid slice" href="data:image/jpeg;base64,${donnees}"/>`;
  });
  const etapes = [];
  ecrans.forEach((_, i) => {
    const a = i * tranche;
    etapes.push([a + glisse, `${-i * ew} 0`], [a + tranche, `${-i * ew} 0`]);
  });
  etapes.push([1, `0 0`]);
  b += `<g clip-path="url(#ecran)"><g>${move(D, [[0, '0 0'], ...etapes])}${bande}</g></g>`;
  b += `<rect x="${px + ew / 2 - 34}" y="${py + 10}" width="68" height="18" rx="9" fill="#05090C"/>`;

  // À droite : le titre de l'écran, deux lignes, et l'avancement.
  const tx = 560;
  b += text(tx, 150, t("L'APPLICATION", 'THE APP'), { size: 12, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="2"' });
  ecrans.forEach(([titre, l1, l2], i) => {
    const a = i * tranche + glisse;
    const z = (i + 1) * tranche;
    b += pendant(
      D,
      a,
      z,
      `<g>${move(D, [[0, '0 14'], [a, '0 14'], [a + 0.02, '0 0'], [1, '0 0']])}` +
        text(tx, 250, `0${i + 1}`, { size: 18, color: C.accent, font: MONO, weight: 700 }) +
        text(tx + 34, 250, `/ 0${n}`, { size: 18, color: C.faint, font: MONO }) +
        text(tx, 320, titre, { size: 52, color: C.title, weight: 800 }) +
        text(tx, 372, l1, { size: 22, color: C.text }) +
        text(tx, 404, l2, { size: 22, color: C.text }) +
        '</g>',
      0.012,
    );
  });
  // Les pastilles d'avancement : celle de l'écran affiché s'allonge.
  ecrans.forEach((_, i) => {
    const x = tx + i * 34;
    const a = i * tranche;
    const z = (i + 1) * tranche;
    b += `<rect x="${x}" y="470" height="8" rx="4">${anim(D, 'width', [[0, i === 0 ? 26 : 8], [a, 8], [a + glisse, 26], [z, 26], [z + glisse, 8]].filter((p) => p[0] <= 1))}${anim(D, 'fill', [[0, i === 0 ? C.accent : C.line], [a, C.line], [a + 0.001, C.accent], [z, C.accent], [z + 0.001, C.line]].filter((p) => p[0] <= 1), { discrete: true })}</rect>`;
  });
  b += text(tx, 530, t('Captures de la version de démonstration, sur un Pixel 7.', 'Screenshots of the demo build, on a Pixel 7.'), { size: 14, color: C.faint });

  return svg(
    W,
    H,
    b,
    t(
      'Animation : un téléphone fait défiler six vrais écrans de BeVannes : la connexion, le lieu du jour avec sa carte, l’arrivée sur place avec la jauge pleine, la validation avec sa coche et ses confettis, le classement avec son podium, et le profil.',
      'Animation: a phone scrolls through six real BeVannes screens: sign in, the spot of the day with its map, arriving on site with the gauge full, the validation with its tick and confetti, the leaderboard with its podium, and the profile.',
    ),
  );
}

// --- 8. Les dix-neuf lieux, dans l'ordre du tirage ------------------------

/** Le tirage, porté de lib/domain/jour.dart à l'identique. */
function hasard(graine) {
  let e = Number(BigInt(graine) & 0xffffffffn);
  const suivant = () => {
    e = (e + 0x6d2b79f5) >>> 0;
    let x = e;
    x = Math.imul(x ^ (x >>> 15), x | 1) >>> 0;
    x = (x ^ ((x + (Math.imul(x ^ (x >>> 7), x | 61) >>> 0)) >>> 0)) >>> 0;
    return (x ^ (x >>> 14)) >>> 0;
  };
  return { sous: (m) => suivant() % m };
}
function ordreDuCycle(cycle, nb) {
  const o = Array.from({ length: nb }, (_, i) => i);
  const h = hasard(BigInt(cycle) * 2654435761n);
  for (let i = nb - 1; i > 0; i--) {
    const j = h.sous(i + 1);
    [o[i], o[j]] = [o[j], o[i]];
  }
  return o;
}
function indexDuLieu(jour, nb) {
  if (nb === 1) return 0;
  if (nb === 2) return jour % 2;
  const cycle = Math.floor(jour / nb);
  const o = ordreDuCycle(cycle, nb);
  const prec = ordreDuCycle(cycle - 1, nb).at(-1);
  if (o[0] === prec) [o[0], o[1]] = [o[1], prec];
  return o[jour % nb];
}

function lieux() {
  const tous = JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'assets', 'lieux.json'), 'utf8')).lieux;
  const nb = tous.length;
  const D = nb * 0.9 + 3;
  const W = 1280;
  const H = 560;
  // Le cycle en cours au 24 septembre 2026, jour 20 720.
  const jour0 = Math.floor(20720 / nb) * nb;
  const ordre = Array.from({ length: nb }, (_, i) => indexDuLieu(jour0 + i, nb));
  const debut = 0.04;
  const pas = 0.9 / D;

  // Deux vues : toute la ville, et le centre agrandi.
  const cosLat = Math.cos((47.65 * Math.PI) / 180);
  const vue = (bornes, x, y, w, h) => {
    const [la0, la1, lo0, lo1] = bornes;
    return (l) => [x + ((l.longitude - lo0) / (lo1 - lo0)) * w, y + ((la1 - l.latitude) / (la1 - la0)) * h];
  };
  // Ville : de Conleau (sud-ouest) à Saint-Patern (nord-est).
  const villeB = [47.628, 47.664, -2.779, -2.749];
  const vh = 440;
  const vw = Math.round((vh * (villeB[3] - villeB[2]) * cosLat) / (villeB[1] - villeB[0]));
  const vx = 60;
  const vy = 80;
  const ville = vue(villeB, vx, vy, vw, vh);
  // Centre : la ville close et le port.
  const centreB = [47.6505, 47.6605, -2.7625, -2.7515];
  const ch = 440;
  const cw = Math.round((ch * (centreB[3] - centreB[2]) * cosLat) / (centreB[1] - centreB[0]));
  const cx0 = vx + vw + 70;
  const centre = vue(centreB, cx0, vy, cw, ch);
  const dansCentre = (l) => l.latitude > centreB[0] && l.latitude < centreB[1] && l.longitude > centreB[2] && l.longitude < centreB[3];

  let b = '';
  b += etape(60, 40, t('LES LIEUX', 'THE PLACES'), '');
  b += text(60, 62, t('Un cycle de dix-neuf jours : chaque lieu une fois, jamais deux jours de suite', 'A nineteen day cycle: every place once, never twice in a row'), { size: 15, color: C.title, weight: 600 });
  const cadre = (x, y, w, h, label) =>
    `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="18" fill="#0A1614" stroke="${C.line}"/>` +
    // Un quadrillage discret, cent mètres environ entre deux traits.
    `<g stroke="#10231F" stroke-width="1">${Array.from({ length: Math.floor(w / 40) }, (_, i) => `<path d="M${x + 20 + i * 40} ${y + 8} V${y + h - 8}"/>`).join('')}${Array.from({ length: Math.floor(h / 40) }, (_, i) => `<path d="M${x + 8} ${y + 20 + i * 40} H${x + w - 8}"/>`).join('')}</g>` +
    text(x + 14, y + h - 14, label, { size: 12, color: C.faint, font: MONO });
  b += cadre(vx, vy, vw, vh, t('VANNES', 'VANNES'));
  b += cadre(cx0, vy, cw, ch, t('LE CENTRE', 'THE CENTRE'));
  // Le rectangle du centre, dessiné sur la vue de la ville.
  const [ax, ay] = ville({ latitude: centreB[1], longitude: centreB[2] });
  const [bx2, by2] = ville({ latitude: centreB[0], longitude: centreB[3] });
  b += `<rect x="${ax}" y="${ay}" width="${bx2 - ax}" height="${by2 - ay}" fill="none" stroke="${C.accent}" stroke-opacity=".5" stroke-dasharray="4 4"/>`;
  b += `<path d="M${bx2} ${ay} L${cx0} ${vy}" stroke="${C.accent}" stroke-opacity=".25" stroke-dasharray="4 6"/><path d="M${bx2} ${by2} L${cx0} ${vy + ch}" stroke="${C.accent}" stroke-opacity=".25" stroke-dasharray="4 6"/>`;

  // Chaque lieu : un point gris, qui s'allume le jour où il tombe, puis
  // reste allumé jusqu'à la fin du cycle.
  const point = (x, y, a, courant) =>
    `<circle cx="${x}" cy="${y}" r="4" fill="${C.faint}"/>` +
    `<circle cx="${x}" cy="${y}" r="6" fill="url(#degrade)" opacity="0">${appear(D, a, 0.96, 0.01)}</circle>` +
    `<circle cx="${x}" cy="${y}" fill="none" stroke="${C.accent}" stroke-width="2" opacity="0">${anim(D, 'opacity', [[0, 0], [a, 0], [a + 0.005, 1], [a + courant, 0]])}${anim(D, 'r', [[0, 6], [a, 6], [a + courant, 30]])}</circle>`;
  ordre.forEach((idx, i) => {
    const l = tous[idx];
    const a = debut + i * pas;
    const [x, y] = ville(l);
    b += point(x, y, a, pas * 1.4);
    if (dansCentre(l)) {
      const [x2, y2] = centre(l);
      b += point(x2, y2, a, pas * 1.4);
    }
  });

  // À droite : le jour du cycle, le lieu, et le compteur.
  const tx = cx0 + cw + 60;
  b += text(tx, 150, t('JOUR DU CYCLE', 'DAY OF THE CYCLE'), { size: 12, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="2"' });
  ordre.forEach((idx, i) => {
    const l = tous[idx];
    const a = debut + i * pas;
    const z = i < nb - 1 ? a + pas : 0.96;
    const date = new Date(Date.UTC(1970, 0, 1) + (jour0 + i) * 86400000);
    const jourTexte = date.toLocaleDateString(LG === 'en' ? 'en-GB' : 'fr-FR', { day: 'numeric', month: 'long', timeZone: 'UTC' });
    b += pendant(
      D,
      a,
      z,
      text(tx, 200, `${String(i + 1).padStart(2, '0')}`, { size: 44, color: C.accent, weight: 800, font: MONO }) +
        text(tx + 70, 200, `/ ${nb}`, { size: 22, color: C.faint, font: MONO }) +
        text(tx, 236, jourTexte, { size: 15, color: C.faint }) +
        text(tx, 290, l.nom, { size: 26, color: C.title, weight: 700 }) +
        text(tx, 318, l.quartier, { size: 15, color: C.text }),
      0.004,
    );
  });
  b += text(tx, 400, t('Le même ordre sur tous les téléphones,', 'The same order on every phone,'), { size: 14, color: C.faint });
  b += text(tx, 420, t('calculé à partir du numéro du jour.', 'worked out from the day number.'), { size: 14, color: C.faint });

  return svg(
    W,
    H,
    b,
    t(
      `Animation : deux cartes de Vannes, la ville entière et le centre agrandi, montrent les dix-neuf lieux du jeu à leur vraie position. Ils s'allument un par un dans l'ordre du cycle en cours : ${ordre.map((i) => tous[i].nom).join(', ')}.`,
      `Animation: two maps of Vannes, the whole town and a close-up of the centre, show the game's nineteen places at their real position. They light up one by one in the order of the current cycle: ${ordre.map((i) => tous[i].nom).join(', ')}.`,
    ),
  );
}

// --- 9. Une validation, de bout en bout -----------------------------------

function parcours() {
  const D = 11;
  const W = 1280;
  const H = 400;
  let b = '';
  b += etape(60, 50, t('UNE VALIDATION', 'ONE VALIDATION'), t('Du déclencheur au classement, en une transaction', 'From shutter to leaderboard, in one transaction'));

  const postes = [
    [t('Téléphone', 'Phone'), [t('photo en 3:4', '3:4 photo'), t('à 20 m du lieu', '20 m from the spot')]],
    [t('Photo', 'Photo'), [t('3:4, 180 Ko', '3:4, 180 KB'), 'photos/20720_toi']],
    ['Firestore', [t('validation écrite', 'validation written'), t('joueur à jour', 'player updated')]],
    [t('Règles', 'Rules'), [t('série 3 → 4', 'streak 3 → 4'), '10 + 2 × 3 = 16 ✓']],
    [t('Classement', 'Leaderboard'), [t('+16 points', '+16 points'), t('4e sur 12', '4th of 12')]],
  ];
  const pw = 206;
  const ph = 150;
  const y = 150;
  const x0 = 60;
  const ecart = (W - 2 * x0 - postes.length * pw) / (postes.length - 1);
  const arrivees = postes.map((_, i) => 0.06 + i * 0.16);

  // Les liaisons, puis le paquet qui voyage de poste en poste.
  for (let i = 0; i < postes.length - 1; i++) {
    const xa = x0 + i * (pw + ecart) + pw;
    const xb = xa + ecart;
    b += `<path d="M${xa + 6} ${y + ph / 2} H${xb - 6}" stroke="${C.line}" stroke-width="3" stroke-linecap="round"/>`;
    b += `<path d="M${xa + 6} ${y + ph / 2} H${xb - 6}" stroke="${C.accent}" stroke-width="3" stroke-linecap="round" stroke-dasharray="${ecart}" stroke-dashoffset="${ecart}">${anim(D, 'stroke-dashoffset', [[0, ecart], [arrivees[i] + 0.04, ecart], [arrivees[i + 1], 0], [0.94, 0], [0.97, ecart]])}</path>`;
  }
  const trajet = [[0, `${x0 + pw / 2} ${y + ph / 2}`]];
  postes.forEach((_, i) => {
    const cx = x0 + i * (pw + ecart) + pw / 2;
    trajet.push([arrivees[i], `${cx} ${y + ph / 2}`], [arrivees[i] + 0.04, `${cx} ${y + ph / 2}`]);
  });
  b += `<g opacity="0">${appear(D, 0.03, 0.8)}<g>${move(D, trajet)}<circle r="22" fill="url(#halo)"/><circle r="8" fill="url(#degrade)" stroke="${C.bg}" stroke-width="3"/></g></g>`;

  postes.forEach(([titre, lignes], i) => {
    const x = x0 + i * (pw + ecart);
    const a = arrivees[i];
    b += `<rect x="${x}" y="${y}" width="${pw}" height="${ph}" rx="18" fill="${C.card}" stroke="${C.accent}" stroke-width="2">${anim(D, 'stroke-opacity', [[0, 0.12], [a, 0.12], [a + 0.02, 1], [0.94, 1], [0.97, 0.12]])}</rect>`;
    b += text(x + 18, y + 36, titre, { size: 19, color: C.title, weight: 700 });
    lignes.forEach((l, j) => {
      b += pendant(D, a + 0.02 + j * 0.02, 0.94, text(x + 18, y + 80 + j * 26, l, { size: 14, color: j === 1 && i === 3 ? C.accent : C.text, font: MONO }));
    });
  });
  b += pendant(D, arrivees[4] + 0.04, 0.94, text(x0, 360, t('Tout passe, ou rien : si les règles refusent, la photo et les points restent de côté.', 'All or nothing: if the rules refuse, the photo and the points are left out.'), { size: 15, color: C.title }));

  return svg(
    W,
    H,
    b,
    t(
      "Animation : une validation traverse cinq postes. Le téléphone envoie une photo 3:4 prise à 20 mètres du lieu ; la photo part dans photos/20720_toi ; Firestore écrit la validation et met à jour le joueur ; les règles recalculent la série, de 3 à 4, et le gain, 10 + 2 × 3 = 16 ; le classement affiche +16 points et la 4e place. Tout passe, ou rien.",
      'Animation: a validation passes through five stations. The phone sends a 3:4 photo taken 20 metres from the spot; the photo goes to photos/20720_toi; Firestore writes the validation and updates the player; the rules recompute the streak, from 3 to 4, and the gain, 10 + 2 × 3 = 16; the leaderboard shows +16 points and 4th place. All or nothing.',
    ),
  );
}

// --- 10. Une triche, refusée ----------------------------------------------

function triche() {
  const D = 12;
  const W = 1280;
  const H = 420;
  const ok = '#3DD68C';
  const ko = '#FF6B81';
  let b = '';
  b += etape(60, 50, t('LES RÈGLES', 'THE RULES'), t('Le téléphone propose, Firestore vérifie', 'The phone proposes, Firestore checks'));

  // La porte des règles, au milieu.
  const gx = 610;
  b += `<rect x="${gx}" y="100" width="170" height="290" rx="20" fill="${C.card}" stroke="${C.line}"/>`;
  b += text(gx + 85, 132, 'firestore.rules', { size: 13, color: C.faint, anchor: 'middle', font: MONO });

  const couloir = (y, titre, points, a, bon) => {
    const couleur = bon ? ok : ko;
    let c = '';
    c += text(60, y - 22, titre, { size: 15, color: C.title, weight: 700 });
    // La requête qui part vers la porte.
    c += `<g opacity="0">${appear(D, a, 0.94, 0.02)}<g>${move(D, [[0, '0 0'], [a, '0 0'], [a + 0.1, '300 0'], [1, '300 0']])}
  <rect x="60" y="${y}" width="230" height="84" rx="14" fill="${C.card2}" stroke="${C.line}"/>
  ${text(78, y + 30, 'points : 136 → ' + points, { size: 15, color: C.title, font: MONO })}
  ${text(78, y + 58, t('série : 3 → 4', 'streak: 3 → 4'), { size: 15, color: C.text, font: MONO })}
  </g></g>`;
    // Le calcul, dans la porte.
    c += pendant(D, a + 0.11, bon ? 0.48 : 0.94, text(gx + 85, y + 26, '136 + 16', { size: 17, color: C.title, anchor: 'middle', font: MONO, weight: 700 }) + text(gx + 85, y + 54, bon ? '= 152 ✓' : '≠ 999 ✗', { size: 19, color: couleur, anchor: 'middle', font: MONO, weight: 700 }));
    // Le verdict, à droite.
    c += `<g opacity="0">${appear(D, a + 0.16, 0.94, 0.02)}<g>${bon ? move(D, [[0, '-20 0'], [a + 0.16, '-20 0'], [a + 0.2, '0 0'], [1, '0 0']]) : move(D, [[0, '0 0'], [a + 0.16, '0 0'], [a + 0.17, '-8 0'], [a + 0.18, '8 0'], [a + 0.19, '-6 0'], [a + 0.2, '0 0'], [1, '0 0']])}
  <rect x="840" y="${y}" width="380" height="84" rx="14" fill="${couleur}" fill-opacity=".1" stroke="${couleur}" stroke-opacity=".7"/>
  ${text(862, y + 34, bon ? t('Accepté', 'Accepted') : t('Refusé', 'Refused'), { size: 20, color: couleur, weight: 800 })}
  ${text(862, y + 60, bon ? t('validation et points écrits ensemble', 'validation and points written together') : 'permission-denied', { size: 14, color: C.text, font: bon ? SANS : MONO })}
  </g></g>`;
    return c;
  };
  b += couloir(150, t('Un téléphone honnête', 'An honest phone'), '152', 0.04, true);
  b += couloir(290, t('Un téléphone trafiqué', 'A tampered phone'), '999', 0.5, false);

  return svg(
    W,
    H,
    b,
    t(
      "Animation : deux téléphones envoient leurs points. Le premier propose 136 → 152 avec une série de 3 à 4 : les règles refont le calcul, 136 + 16 = 152, et acceptent. Le second propose 136 → 999 : 136 + 16 ne fait pas 999, les règles refusent avec permission-denied.",
      'Animation: two phones send their points. The first proposes 136 → 152 with a streak going from 3 to 4: the rules redo the maths, 136 + 16 = 152, and accept. The second proposes 136 → 999: 136 + 16 is not 999, the rules refuse with permission-denied.',
    ),
  );
}

// --- 11. Les fonctionnalités ----------------------------------------------

/** Un petit pictogramme en traits, dessiné autour de (x, y). */
function picto(nom, x, y, D, a) {
  const s = `stroke="${C.accent}" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"`;
  const g = (c) => `<g transform="translate(${x} ${y})">${c}</g>`;
  switch (nom) {
    case 'lieu':
      return g(`<path d="M0 13 C-8 4 -12 -2 -12 -7 A12 12 0 0 1 12 -7 C12 -2 8 4 0 13 Z" ${s}/><circle cx="0" cy="-7" r="4" fill="${C.accent}"/>`);
    case 'zone':
      return g(`<circle r="4" fill="${C.accent}"/><circle r="13" ${s}/><circle r="13" ${s}>${anim(D, 'r', [[0, 4], [a, 4], [a + 0.08, 17], [a + 0.081, 4]])}${anim(D, 'stroke-opacity', [[0, 0], [a, 1], [a + 0.08, 0]])}</circle>`);
    case 'photo':
      return g(`<rect x="-10" y="-13" width="20" height="26" rx="3" ${s}/><circle cy="-1" r="5" ${s}/>`);
    case 'mur':
      return g(`<rect x="-13" y="-13" width="11" height="11" rx="2" ${s}/><rect x="2" y="-13" width="11" height="11" rx="2" ${s}/><rect x="-13" y="2" width="11" height="11" rx="2" ${s}/><rect x="2" y="2" width="11" height="11" rx="2" fill="${C.accent}" stroke="${C.accent}" stroke-width="2.2"/>`);
    case 'serie':
      return g(`<path d="M0 13 C-9 13 -12 6 -10 0 C-8 -5 -4 -6 -3 -13 C3 -9 5 -5 4 -1 C6 -3 7 -5 7 -7 C11 -2 11 5 8 9 C6 12 3 13 0 13 Z" stroke="${C.flame}" stroke-width="2.2" fill="none" stroke-linejoin="round"/>`);
    case 'podium':
      return g(`<rect x="-14" y="-2" width="9" height="14" rx="1.5" ${s}/><rect x="-4.5" y="-12" width="9" height="24" rx="1.5" fill="${C.accent}" stroke="${C.accent}" stroke-width="2.2"/><rect x="5" y="3" width="9" height="9" rx="1.5" ${s}/>`);
    case 'rappel':
      return g(`<circle r="13" ${s}/><path d="M0 -7 V0 L5 4" ${s}/>`);
    case 'note':
      return g(`<rect x="-11" y="-13" width="22" height="26" rx="3" ${s}/><path d="M-6 -6 H6 M-6 0 H6 M-6 6 H2" ${s}/>`);
    case 'demo':
      return g(`<path d="M-4 -13 H4 M-3 -13 V-3 L-11 10 A2 2 0 0 0 -9 13 H9 A2 2 0 0 0 11 10 L3 -3 V-13" ${s}/><path d="M-7 5 H7" ${s}/>`);
  }
  return '';
}

function fonctionnalites() {
  const D = 18;
  const W = 1280;
  const H = 640;
  const cartes = [
    ['lieu', t('Un lieu par jour', 'One spot a day'), t('Le même pour tous, tiré par', 'The same for everyone, drawn by'), t('chaque téléphone, sans serveur.', 'each phone, with no server.')],
    ['zone', t('Cent mètres, pas plus', 'A hundred metres, no more'), t('Le GPS confirme la présence ;', 'GPS confirms you are there;'), t('une position fictive est refusée.', 'a mock location is refused.')],
    ['photo', t('La photo en 3:4', 'The photo in 3:4'), t('Recadrée et allégée sur le', 'Cropped and slimmed down on the'), t('téléphone, 900 × 1200 en JPEG.', 'phone, 900 × 1200 as JPEG.')],
    ['mur', t('Le mur du jour', 'The daily wall'), t('Les photos des autres se', 'Other players’ photos unlock'), t('dévoilent après la sienne.', 'once yours is posted.')],
    ['serie', t('Points et séries', 'Points and streaks'), t('10 points par lieu, +2 par jour', '10 points a spot, +2 per day'), t('de série, jusqu’à +10.', 'of streak, up to +10.')],
    ['podium', t('Le classement', 'The leaderboard'), t('Les cent meilleurs, le podium,', 'The top hundred, the podium,'), t('et la série de chacun.', 'and everyone’s streak.')],
    ['rappel', t('Le rappel', 'The reminder'), t('Une heure différente chaque jour,', 'A different time every day,'), t('la même pour tout le monde.', 'the same for everybody.')],
    ['note', t('La note du lieu', 'The note on the place'), t('Un peu d’histoire sur chacun', 'A bit of history on each'), t('des dix-neuf lieux de Vannes.', 'of the nineteen spots in Vannes.')],
    ['demo', t('La démo', 'The demo'), t('Une communauté fictive, et un', 'A made-up community, and a'), t('interrupteur pour se téléporter.', 'switch to teleport yourself.')],
  ];
  const cw = 372;
  const ch = 150;
  const gx = 22;
  const gy = 22;
  const x0 = (W - 3 * cw - 2 * gx) / 2;
  const y0 = 100;
  let b = etape(x0, 46, 'BEVANNES', t('Neuf idées, un seul jeu', 'Nine ideas, one game'));
  const pas = 0.9 / cartes.length;
  cartes.forEach(([p, titre, l1, l2], i) => {
    const x = x0 + (i % 3) * (cw + gx);
    const y = y0 + Math.floor(i / 3) * (ch + gy);
    const a = 0.03 + i * pas;
    b += `<rect x="${x}" y="${y}" width="${cw}" height="${ch}" rx="18" fill="${C.card}" stroke="${C.accent}" stroke-width="1.6">${anim(D, 'stroke-opacity', [[0, 0.14], [a, 0.14], [a + 0.015, 0.9], [a + pas, 0.9], [a + pas + 0.015, 0.14]])}</rect>`;
    b += `<circle cx="${x + 48}" cy="${y + 50}" r="40" fill="url(#halo)" opacity="0">${anim(D, 'opacity', [[0, 0], [a, 0], [a + 0.015, 1], [a + pas, 1], [a + pas + 0.015, 0]])}</circle>`;
    b += `<rect x="${x + 22}" y="${y + 24}" width="52" height="52" rx="14" fill="${C.soft}" stroke="${C.accent}" stroke-opacity=".3"/>`;
    b += picto(p, x + 48, y + 50, D, a);
    b += text(x + 94, y + 44, `0${i + 1}`, { size: 12, color: C.faint, font: MONO, weight: 700 });
    b += text(x + 94, y + 68, titre, { size: 19, color: C.title, weight: 700 });
    b += text(x + 22, y + 110, l1, { size: 15, color: C.text });
    b += text(x + 22, y + 132, l2, { size: 15, color: C.text });
  });
  return svg(W, H, b, t(
    "Les fonctionnalités de BeVannes, en neuf cartes qui s'allument l'une après l'autre. Un lieu par jour, le même pour tous, tiré par chaque téléphone. Cent mètres, pas plus : le GPS confirme, une position fictive est refusée. La photo en 3:4, recadrée et allégée sur le téléphone. Le mur du jour, dont les photos se dévoilent après la sienne. Points et séries : 10 points, +2 par jour de série jusqu'à +10. Le classement des cent meilleurs. Le rappel, à une heure différente chaque jour. La note historique de chacun des dix-neuf lieux. La démo, avec sa communauté fictive et la téléportation.",
    'The features of BeVannes, in nine cards that light up one after the other. One spot a day, the same for everyone, drawn by each phone. A hundred metres, no more: GPS confirms, a mock location is refused. The photo in 3:4, cropped and slimmed down on the phone. The daily wall, whose photos unlock once yours is posted. Points and streaks: 10 points, +2 per day of streak up to +10. The top hundred leaderboard. The reminder, at a different time every day. The history note of each of the nineteen spots. The demo, with its made-up community and teleporting.',
  ));
}

// --- 12. La planche des écrans --------------------------------------------

function ecrans() {
  const W = 1280;
  const noms = [
    [t('Connexion', 'Sign in'), t('un compte, un pseudo', 'one account, one nickname')],
    [t('Le lieu du jour', "Today's spot"), t('la carte et sa zone', 'the map and its zone')],
    [t('Sur place', 'On site'), t('la jauge est pleine', 'the gauge is full')],
    [t('Validé', 'Validated'), t('points et série', 'points and streak')],
    [t('Le classement', 'Leaderboard'), t('le podium, sa place', 'the podium, your rank')],
    [t('Le profil', 'The profile'), t('chiffres et lieux', 'numbers and spots')],
  ];
  const ew = 184;
  const eh = Math.round((ew * 1067) / 480);
  const ecart = (W - 80 - 6 * ew) / 5;
  const y = 40;
  const H = y + eh + 96;
  let b = '';
  noms.forEach(([titre, sous], i) => {
    const x = 40 + i * (ew + ecart);
    const donnees = fs.readFileSync(path.join(__dirname, 'vitrine', `0${i + 1}.jpg`)).toString('base64');
    b += `<clipPath id="e${i}"><rect x="${x}" y="${y}" width="${ew}" height="${eh}" rx="20"/></clipPath>`;
    b += `<image x="${x}" y="${y}" width="${ew}" height="${eh}" clip-path="url(#e${i})" preserveAspectRatio="xMidYMid slice" href="data:image/jpeg;base64,${donnees}"/>`;
    b += `<rect x="${x}" y="${y}" width="${ew}" height="${eh}" rx="20" fill="none" stroke="${C.line}" stroke-width="2"/>`;
    b += text(x, y + eh + 36, `0${i + 1}`, { size: 13, color: C.accent, font: MONO, weight: 700 });
    b += text(x + 30, y + eh + 36, titre, { size: 16, color: C.title, weight: 700 });
    b += text(x, y + eh + 62, sous, { size: 14, color: C.text });
  });
  return svg(W, H, b, t(
    "Six vrais écrans de BeVannes, côte à côte. La connexion, avec un compte et un pseudo. Le lieu du jour, avec la carte et sa zone de cent mètres. L'arrivée sur place, jauge pleine. La validation, avec les points et la série. Le classement, avec le podium. Le profil, avec ses chiffres et les lieux découverts.",
    'Six real BeVannes screens, side by side. Sign in, with an account and a nickname. The spot of the day, with the map and its hundred metre zone. Arriving on site, gauge full. The validation, with points and streak. The leaderboard, with the podium. The profile, with its numbers and the spots found.',
  ));
}

// --- 13. Ce qui sort du téléphone -----------------------------------------

function confidentialite() {
  const D = 14;
  const W = 1280;
  const H = 560;
  let b = '';
  b += etape(60, 46, t('CONFIDENTIALITÉ', 'PRIVACY'), t('Ce qui reste sur le téléphone, et ce qui en sort', 'What stays on the phone, and what leaves it'));
  // Le téléphone, au centre.
  const px = 540;
  const py = 120;
  const pw = 160;
  b += `<ellipse cx="${px + pw / 2}" cy="${py + 170}" rx="150" ry="200" fill="url(#halo)" opacity=".45"/>`;
  b += telephone(px, py, pw, 330, text(pw / 2, 150, 'BeVannes', { size: 17, color: C.title, weight: 800, anchor: 'middle' }) + `<circle cx="${pw / 2}" cy="200" r="7" fill="url(#degrade)"/><circle cx="${pw / 2}" cy="200" r="22" fill="none" stroke="${C.accent}" stroke-opacity=".5"/>`);
  // À gauche, ce qui ne part jamais.
  const gauche = [
    [t('La position exacte', 'The exact position'), t('seule la distance arrondie part', 'only the rounded distance leaves')],
    [t('La photo d’origine', 'The original photo'), t('seule la version 3:4 est envoyée', 'only the 3:4 version is sent')],
    [t('Le tirage du lieu', 'The draw of the spot'), t('calculé ici, jamais stocké', 'computed here, never stored')],
    [t('L’heure du rappel', 'The reminder time'), t('notification locale, sans serveur', 'local notification, no server')],
  ];
  b += text(60, 124, t('RESTE ICI', 'STAYS HERE'), { size: 12, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="1.5"' });
  gauche.forEach(([a, c], i) => {
    const y = 144 + i * 84;
    const debut = 0.04 + i * 0.05;
    b += pendant(D, debut, 0.95, `<rect x="60" y="${y}" width="420" height="68" rx="14" fill="${C.card}" stroke="${C.line}"/>` +
      `<g fill="none" stroke="${C.accent}" stroke-width="2" stroke-linecap="round"><path d="M86 ${y + 32} v-6 a6 6 0 0 1 12 0 v6"/><rect x="81" y="${y + 32}" width="22" height="16" rx="4"/></g><circle cx="92" cy="${y + 40}" r="2" fill="${C.accent}"/>` +
      text(124, y + 29, a, { size: 16, color: C.title, weight: 700 }) + text(124, y + 52, c, { size: 14, color: C.text }));
  });
  // À droite, ce qui part vers Firebase, et qui peut le lire.
  const droite = [
    ['Authentication', t('e-mail et mot de passe', 'e-mail and password'), t('personne d’autre', 'nobody else')],
    ['joueurs/{uid}', t('pseudo, points, série', 'nickname, points, streak'), t('joueurs connectés', 'signed-in players')],
    ['validations/{jour}_{uid}', t('lieu, distance, heure', 'spot, distance, time'), t('joueurs connectés', 'signed-in players')],
    ['photos/{jour}_{uid}', t('le JPEG 900 × 1200', 'the 900 × 1200 JPEG'), t('ceux qui ont validé ce jour', 'those who validated that day')],
  ];
  const dx = 780;
  b += text(dx, 124, t('PART VERS FIREBASE', 'GOES TO FIREBASE'), { size: 12, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="1.5"' });
  droite.forEach(([col, quoi, qui], i) => {
    const y = 144 + i * 84;
    const a = 0.3 + i * 0.12;
    // Un paquet quitte le téléphone et rejoint sa collection.
    b += `<circle r="5" fill="${C.pale}" opacity="0">${appear(D, a, a + 0.06, 0.01)}${move(D, [[0, `${px + pw} ${py + 200}`], [a, `${px + pw} ${py + 200}`], [a + 0.06, `${dx} ${y + 34}`], [1, `${dx} ${y + 34}`]])}</circle>`;
    b += pendant(D, a + 0.05, 0.95, `<rect x="${dx}" y="${y}" width="440" height="68" rx="14" fill="${C.card}" stroke="${C.accent}" stroke-opacity=".45"/>` +
      text(dx + 20, y + 28, col, { size: 14, color: C.accent, font: MONO, weight: 700 }) +
      text(dx + 20, y + 52, quoi, { size: 14, color: C.title }) +
      text(dx + 420, y + 52, qui, { size: 13, color: C.text, anchor: 'end' }));
  });
  b += pendant(D, 0.84, 0.95, text(60, 520, t('Supprimer son compte efface ses photos, ses validations et son joueur, puis le compte lui-même.', 'Deleting your account erases your photos, your validations and your player, then the account itself.'), { size: 15, color: C.title }));
  return svg(W, H, b, t(
    "Animation : au centre, le téléphone. À gauche, ce qui n'en sort jamais : la position exacte, dont seule la distance arrondie part ; la photo d'origine, dont seule la version 3:4 est envoyée ; le tirage du lieu, calculé sur place ; l'heure du rappel, une notification locale. À droite, quatre paquets partent vers Firebase : l'e-mail et le mot de passe dans Authentication, lus par personne d'autre ; le pseudo, les points et la série dans joueurs, lus par les joueurs connectés ; le lieu, la distance et l'heure dans validations ; le JPEG dans photos, lisible seulement par ceux qui ont validé ce jour-là. Supprimer son compte efface tout.",
    'Animation: in the middle, the phone. On the left, what never leaves it: the exact position, of which only the rounded distance goes out; the original photo, of which only the 3:4 version is sent; the draw of the spot, computed on the phone; the reminder time, a local notification. On the right, four packets leave for Firebase: e-mail and password in Authentication, read by nobody else; nickname, points and streak in joueurs, read by signed-in players; spot, distance and time in validations; the JPEG in photos, readable only by those who validated that day. Deleting your account erases everything.',
  ));
}

// --- 14. La stack ---------------------------------------------------------

function stack() {
  const D = 16;
  const W = 1280;
  const paquets = [
    ['cloud_firestore 6.10', t('joueurs, validations, photos, en transaction', 'players, validations, photos, in one transaction'), t('Serveur', 'Server')],
    ['firebase_auth 6.7', t('le compte, par e-mail et mot de passe', 'the account, by e-mail and password'), t('Serveur', 'Server')],
    ['flutter_local_notifications 22.3', t('le rappel, programmé sept jours d’avance', 'the reminder, scheduled seven days ahead'), t('Appareil', 'Device')],
    ['image_picker 1.2 · image 4.10', t('l’appareil photo, puis le recadrage 3:4', 'the camera, then the 3:4 crop'), t('Appareil', 'Device')],
    ['geolocator 14.0', t('la position, et le drapeau « fictive »', 'the position, and the “mocked” flag'), t('Appareil', 'Device')],
    ['flutter_map 8.3 · OpenStreetMap', t('la carte, sans clé d’API', 'the map, with no API key'), t('Écran', 'Screen')],
    ['go_router 18.0', t('les écrans, et la redirection sans compte', 'the screens, and the signed-out redirect'), t('Écran', 'Screen')],
    ['flutter_riverpod 3.4', t('l’état : jour, lieu, position, distance', 'the state: day, spot, position, distance'), t('Écran', 'Screen')],
    ['Flutter 3.47 · Dart 3.13', t('toute l’application, un seul code', 'the whole app, one codebase'), t('Socle', 'Base')],
  ];
  const lh = 50;
  const y0 = 96;
  const H = y0 + paquets.length * (lh + 8) + 40;
  let b = etape(60, 46, t('LA STACK', 'THE STACK'), t('Paquet par paquet, du socle au serveur', 'Package by package, from the base to the server'));
  const n = paquets.length;
  paquets.forEach(([nom, role, couche], i) => {
    const y = y0 + i * (lh + 8);
    const a = 0.04 + (n - 1 - i) * 0.08; // on monte depuis le socle
    const socle = i === n - 1;
    b += pendant(D, a, 0.95, `<g>${move(D, [[0, '0 16'], [a, '0 16'], [a + 0.03, '0 0'], [1, '0 0']])}` +
      `<rect x="60" y="${y}" width="1160" height="${lh}" rx="12" fill="${socle ? C.soft : C.card}" stroke="${socle ? C.accent : C.line}" stroke-opacity="${socle ? 0.6 : 1}"/>` +
      text(84, y + 31, nom, { size: 16, color: socle ? C.pale : C.title, font: MONO, weight: 700 }) +
      text(520, y + 31, role, { size: 15, color: C.text }) +
      `<rect x="1080" y="${y + 13}" width="120" height="24" rx="12" fill="${C.soft}"/>` +
      text(1140, y + 30, couche, { size: 12.5, color: C.accent, anchor: 'middle', weight: 600 }) +
      '</g>', 0.02);
  });
  return svg(W, H, b, t(
    "Animation : la stack de BeVannes se monte paquet par paquet, du socle au serveur. Flutter 3.47 et Dart 3.13 pour toute l'application. flutter_riverpod 3.4 pour l'état : jour, lieu, position, distance. go_router 18 pour les écrans et la redirection sans compte. flutter_map 8.3 et OpenStreetMap pour la carte, sans clé d'API. geolocator 14 pour la position et le drapeau de position fictive. image_picker et image pour l'appareil photo et le recadrage 3:4. flutter_local_notifications pour le rappel, programmé sept jours d'avance. firebase_auth pour le compte, cloud_firestore pour les joueurs, les validations et les photos.",
    'Animation: the BeVannes stack builds up package by package, from the base to the server. Flutter 3.47 and Dart 3.13 for the whole app. flutter_riverpod 3.4 for state: day, spot, position, distance. go_router 18 for the screens and the signed-out redirect. flutter_map 8.3 and OpenStreetMap for the map, with no API key. geolocator 14 for the position and the mocked-location flag. image_picker and image for the camera and the 3:4 crop. flutter_local_notifications for the reminder, scheduled seven days ahead. firebase_auth for the account, cloud_firestore for players, validations and photos.',
  ));
}

// --- 15. Les couches, traversées par une validation -----------------------

function couches() {
  const D = 14;
  const W = 1280;
  const H = 560;
  const niveaux = [
    ['lib/ui', t('9 fichiers · 3 586 lignes', '9 files · 3,586 lines'), t('les écrans et leurs animations', 'the screens and their animations')],
    ['lib/providers.dart', t('1 fichier · 125 lignes', '1 file · 125 lines'), t('l’état partagé, par Riverpod', 'the shared state, through Riverpod')],
    ['lib/data', t('7 fichiers · 820 lignes', '7 files · 820 lines'), t('Firebase ou démo, GPS, photo, rappels', 'Firebase or demo, GPS, photo, reminders')],
    ['lib/domain', t('5 fichiers · 233 lignes', '5 files · 233 lines'), t('les règles du jeu, en Dart pur, testées', 'the game rules, in plain Dart, tested')],
  ];
  // Ce que touche une validation, couche par couche.
  const pas = [
    [0, 'EcranPhoto', t('« Prendre la photo »', '“Take the photo”')],
    [1, 'positionProvider', t('la position suivie', 'the tracked position')],
    [2, 'Localisation.actuelle()', t('une mesure fraîche', 'a fresh fix')],
    [3, 'distanceMetres()', t('20 m ≤ 100 m', '20 m ≤ 100 m')],
    [2, 'recadrerPhoto()', t('3:4, 900 × 1200', '3:4, 900 × 1200')],
    [3, 'serieApres() · gainPour()', t('série 4, +16', 'streak 4, +16')],
    [2, 'FirebaseDepot.valider()', t('une seule transaction', 'a single transaction')],
  ];
  const lx = 60;
  const lw = 470;
  const lh = 92;
  const y0 = 100;
  let b = etape(lx, 46, 'ARCHITECTURE', t('Quatre couches, traversées par une validation', 'Four layers, crossed by one validation'));
  niveaux.forEach(([nom, taille, role], i) => {
    const y = y0 + i * (lh + 12);
    const dom = i === 3;
    b += `<rect x="${lx}" y="${y}" width="${lw}" height="${lh}" rx="16" fill="${dom ? C.soft : C.card}" stroke="${dom ? C.accent : C.line}" stroke-opacity="${dom ? 0.6 : 1}"/>`;
    b += text(lx + 22, y + 36, nom, { size: 17, color: dom ? C.pale : C.title, font: MONO, weight: 700 });
    b += text(lx + lw - 22, y + 36, taille, { size: 13, color: C.faint, anchor: 'end', font: MONO });
    b += text(lx + 22, y + 66, role, { size: 15, color: C.text });
  });
  // Le jeton qui descend et remonte, et le journal à droite.
  const jx = 600;
  const cy = (i) => y0 + i * (lh + 12) + lh / 2;
  const jeton = lx + lw + 35;
  const d0 = 0.05;
  const dp = 0.1;
  const etapes = [[0, `${jeton} ${cy(0)}`]];
  pas.forEach(([niv], i) => {
    const a = d0 + i * dp;
    etapes.push([a, `${jeton} ${cy(niv)}`], [a + dp * 0.6, `${jeton} ${cy(niv)}`]);
  });
  b += `<circle r="9" fill="url(#degrade)" opacity="0">${move(D, etapes)}${anim(D, 'opacity', [[0, 0], [d0 - 0.02, 0], [d0, 1], [0.8, 1], [0.84, 0]])}</circle>`;
  b += text(jx, y0 + 6, t('CE QUE TOUCHE UN APPUI', 'WHAT ONE TAP TOUCHES'), { size: 12, color: C.faint, font: MONO, weight: 700, extra: 'letter-spacing="1.5"' });
  pas.forEach(([, fn, quoi], i) => {
    const a = d0 + i * dp;
    const y = y0 + 24 + i * 56;
    b += pendant(D, a, 0.95, `<rect x="${jx}" y="${y}" width="620" height="44" rx="11" fill="${C.card}" stroke="${C.line}"/>` +
      text(jx + 18, y + 28, fn, { size: 14.5, color: C.title, font: MONO, weight: 700 }) +
      text(jx + 602, y + 28, quoi, { size: 14, color: C.accent, anchor: 'end' }), 0.015);
  });
  return svg(W, H, b, t(
    "Animation : les quatre couches de BeVannes, lib/ui, providers.dart, lib/data et lib/domain, traversées par un appui sur « Prendre la photo ». Le jeton part de EcranPhoto, passe par positionProvider, demande une mesure fraîche à Localisation.actuelle, descend au domaine pour distanceMetres, 20 mètres sur 100 permis, remonte pour recadrerPhoto en 3:4, redescend pour serieApres et gainPour, série 4 et +16, et finit dans FirebaseDepot.valider, une seule transaction. Le domaine, 5 fichiers et 233 lignes de Dart pur, est la couche testée à part.",
    'Animation: the four BeVannes layers, lib/ui, providers.dart, lib/data and lib/domain, crossed by a tap on “Take the photo”. The token leaves EcranPhoto, goes through positionProvider, asks Localisation.actuelle for a fresh fix, goes down to the domain for distanceMetres, 20 metres out of 100 allowed, back up for recadrerPhoto in 3:4, down again for serieApres and gainPour, streak 4 and +16, and ends in FirebaseDepot.valider, a single transaction. The domain, 5 files and 233 lines of plain Dart, is the layer tested on its own.',
  ));
}

// --- 16. Le modèle de données ---------------------------------------------

function modele() {
  const D = 12;
  const W = 1280;
  const H = 520;
  const blocs = [
    [60, 'Authentication', t('les comptes', 'the accounts'), [['uid', 'string'], ['email', 'string'], [t('mot de passe', 'password'), t('haché', 'hashed')]]],
    [360, 'joueurs/{uid}', t('un par joueur', 'one per player'), [['pseudo', 'string'], ['points', 'int'], ['serie', 'int'], ['meilleureSerie', 'int'], ['validations', 'int'], ['dernierJour', 'int'], ['creeLe', 'timestamp']]],
    [660, 'validations/{jour}_{uid}', t('une par joueur et par jour', 'one per player and day'), [['uid · pseudo', 'string'], ['jour', 'int'], ['lieu', 'string'], ['distance', '0 … 100'], ['gain · serie', 'int'], ['photo', 'photos/{id}'], ['moment', 'timestamp']]],
    [960, 'photos/{jour}_{uid}', t('le JPEG de la validation', 'the validation’s JPEG'), [['uid', 'string'], ['jour', 'int'], ['jpeg', t('octets < 900 Ko', 'bytes < 900 KB')]]],
  ];
  const bw = 262;
  const y0 = 100;
  let b = etape(60, 46, t('LE MODÈLE DE DONNÉES', 'THE DATA MODEL'), t('Trois collections Firestore, un même identifiant', 'Three Firestore collections, one shared id'));
  blocs.forEach(([x, nom, sous, champs], i) => {
    const h = 82 + champs.length * 30;
    const a = 0.04 + i * 0.12;
    b += pendant(D, a, 0.95, `<rect x="${x}" y="${y0}" width="${bw}" height="${h}" rx="16" fill="${C.card}" stroke="${i === 0 ? C.line : C.accent}" stroke-opacity="${i === 0 ? 1 : 0.45}"/>` +
      text(x + 18, y0 + 30, nom, { size: 14.5, color: i === 0 ? C.title : C.accent, font: MONO, weight: 700 }) +
      text(x + 18, y0 + 52, sous, { size: 13, color: C.faint }) +
      `<line x1="${x + 18}" x2="${x + bw - 18}" y1="${y0 + 66}" y2="${y0 + 66}" stroke="${C.line}"/>` +
      champs.map(([c, ty], j) => text(x + 18, y0 + 96 + j * 30, c, { size: 14, color: C.title, font: MONO }) + text(x + bw - 18, y0 + 96 + j * 30, ty, { size: 13, color: C.text, anchor: 'end', font: MONO })).join(''));
  });
  // Les liens : uid, puis la photo.
  const lien = (x1, x2, y, a, lib, y2 = y) =>
    pendant(D, a, 0.95, `<path d="M${x1} ${y} H${(x1 + x2) / 2} V${y2} H${x2}" fill="none" stroke="${C.accent}" stroke-width="2" stroke-dasharray="5 4"/><circle cx="${x2}" cy="${y2}" r="4" fill="${C.accent}"/>` + text((x1 + x2) / 2, y2 - 10, lib, { size: 11, color: C.faint, anchor: 'middle', font: MONO }));
  b += lien(60 + bw, 360, y0 + 91, 0.5, 'uid');
  b += lien(360 + bw, 660, y0 + 91, 0.58, 'uid');
  b += lien(660 + bw, 960, y0 + 91 + 5 * 30, 0.66, 'id', y0 + 91);
  b += pendant(D, 0.74, 0.95, text(60, 470, t('L’identifiant {jour}_{uid} fait la règle : une seule validation par joueur et par jour, et sa photo porte le même nom.', 'The {jour}_{uid} id is the rule: a single validation per player and per day, and its photo carries the same name.'), { size: 15, color: C.title }));
  return svg(W, H, b, t(
    "Animation : le modèle de données de BeVannes. Authentication garde l'uid, l'e-mail et le mot de passe haché. joueurs/{uid} : pseudo, points, série, meilleure série, validations, dernier jour et date de création. validations/{jour}_{uid} : uid, pseudo, jour, lieu, distance de 0 à 100, gain, série, chemin de la photo et moment. photos/{jour}_{uid} : uid, jour et le JPEG en octets, moins de 900 Ko. Des liens relient les uid et la photo. L'identifiant {jour}_{uid} impose une seule validation par joueur et par jour.",
    'Animation: the BeVannes data model. Authentication keeps the uid, the e-mail and the hashed password. joueurs/{uid}: nickname, points, streak, best streak, validations, last day and creation date. validations/{jour}_{uid}: uid, nickname, day, spot, distance from 0 to 100, gain, streak, photo path and moment. photos/{jour}_{uid}: uid, day and the JPEG as bytes, under 900 KB. Links join the uids and the photo. The {jour}_{uid} id enforces a single validation per player and per day.',
  ));
}

// --- 17. Les tests --------------------------------------------------------

function tests() {
  const D = 14;
  const W = 1280;
  const ok = '#3DD68C';
  const fichiers = [
    ['test/jour_test.dart', [t('le numéro du jour suit la date locale', 'the day number follows the local date'), t('le tirage est le même partout : valeurs figées', 'the draw is the same everywhere: frozen values'), t('chaque lieu passe une fois par cycle', 'each spot comes once per cycle'), t('jamais deux fois le même lieu deux jours de suite', 'never the same spot two days running'), t('un seul lieu : toujours lui', 'a single spot: always that one'), t('le rappel tombe entre 10 h et 19 h 59, et varie', 'the reminder falls between 10:00 and 19:59, and varies')]],
    ['test/geo_test.dart', [t('distance nulle sur place', 'zero distance on the spot'), t('cathédrale ↔ porte Saint-Vincent : 380 m', 'cathedral ↔ Porte Saint-Vincent: 380 m'), t('Vannes ↔ Rennes : 100 km', 'Vannes ↔ Rennes: 100 km'), t('distances lisibles', 'readable distances')]],
    ['test/score_test.dart', [t('la série continue le lendemain, repart à 1 sinon', 'the streak goes on the next day, else back to 1'), t('gain : 10 points, +2 par jour, plafonné à +10', 'gain: 10 points, +2 a day, capped at +10'), t('la série tombe à zéro après un jour manqué', 'the streak drops to zero after a missed day')]],
    ['test/demo_depot_test.dart', [t('valider rapporte les points, une fois par jour', 'validating pays out once a day'), t('le classement est trié par points', 'the leaderboard is sorted by points'), t('pseudos', 'nicknames')]],
  ];
  const tous = fichiers.flatMap((f) => f[1]);
  const total = tous.length;
  const H = 600;
  let b = etape(60, 46, 'FLUTTER TEST', t(`${total} tests, sur les règles du jeu`, `${total} tests, on the game rules`));
  // Le compteur et le ruban de cases.
  const d0 = 0.05;
  const dp = 0.78 / total;
  for (let n = 0; n <= total; n++) {
    const a = n === 0 ? 0 : d0 + (n - 1) * dp;
    const z = n === total ? 0.96 : d0 + n * dp;
    b += net(D, a, z, text(60, 150, `${n}`, { size: 60, color: n === total ? ok : C.title, weight: 800 }) + text(n >= 10 ? 138 : 104, 150, `/ ${total}`, { size: 22, color: C.faint, font: MONO }));
  }
  for (let n = 0; n < total; n++) {
    const a = d0 + n * dp;
    b += `<rect x="${60 + n * 26}" y="178" width="20" height="20" rx="5" fill="${C.card2}"><animate attributeName="fill" dur="${D}s" repeatCount="indefinite" calcMode="discrete" keyTimes="0;${k(a)};${k(0.96)}" values="${C.card2};${ok};${C.card2}"/></rect>`;
  }
  // Les noms, fichier par fichier, en deux colonnes.
  const cols = [[fichiers[0], fichiers[2]], [fichiers[1], fichiers[3]]];
  cols.forEach((col, c) => {
    let y = 252;
    const x = 60 + c * 610;
    col.forEach(([nom, noms]) => {
      b += text(x, y, nom, { size: 13, color: C.faint, font: MONO, weight: 700 });
      y += 30;
      noms.forEach((l) => {
        const a = d0 + tous.indexOf(l) * dp;
        b += pendant(D, a, 0.96, text(x, y, '✓', { size: 15, color: ok, weight: 700 }) + text(x + 24, y, l, { size: 15, color: C.title }), 0.01);
        y += 27;
      });
      y += 24;
    });
  });
  return svg(W, H, b, t(
    `Animation : flutter test, ${total} tests qui passent au vert un à un. jour_test : le numéro du jour suit la date locale, le tirage est le même partout avec des valeurs figées, chaque lieu passe une fois par cycle, jamais deux fois le même lieu deux jours de suite, un seul lieu revient toujours, le rappel tombe entre 10 h et 19 h 59. geo_test : distance nulle sur place, 380 mètres de la cathédrale à la porte Saint-Vincent, 100 kilomètres jusqu'à Rennes, distances lisibles. score_test : la série continue ou repart à 1, le gain plafonné, la série tombe à zéro après un jour manqué. demo_depot_test : une validation par jour, le classement trié, les pseudos.`,
    `Animation: flutter test, ${total} tests turning green one by one. jour_test: the day number follows the local date, the draw is the same everywhere with frozen values, each spot comes once per cycle, never the same spot two days running, a single spot always comes back, the reminder falls between 10:00 and 19:59. geo_test: zero distance on the spot, 380 metres from the cathedral to Porte Saint-Vincent, 100 kilometres to Rennes, readable distances. score_test: the streak goes on or back to 1, the capped gain, the streak drops to zero after a missed day. demo_depot_test: one validation a day, the sorted leaderboard, nicknames.`,
  ));
}

// --- 18. Les versions -----------------------------------------------------

function versions() {
  const D = 12;
  const W = 1280;
  const H = 540;
  const liste = [
    ['2.0.0', t('24 sept. · 11 h 43', '24 Sept · 11:43'), t('La réécriture, en mode démo', 'The rewrite, in demo mode'), t('Flutter à la place du prototype FlutterFlow, une communauté fictive, la téléportation.', 'Flutter instead of the FlutterFlow prototype, a made-up community, teleporting.')],
    ['2.0.1', t('24 sept. · 12 h 34', '24 Sept · 12:34'), t('Les animations', 'The animations'), t('Radar, jauge d’approche, reflet sur le bouton, coche et confettis, écrans bloc par bloc.', 'Radar, approach gauge, button shine, tick and confetti, screens block by block.')],
    ['2.1.0', t('24 sept. · 17 h 27', '24 Sept · 17:27'), t('Deux applications', 'Two apps'), t('Le vrai jeu relié à Firebase, et la démo installée à côté, sans se gêner.', 'The real game wired to Firebase, and the demo installed next to it.')],
  ];
  const x = 60;
  const w = 1160;
  const h = 96;
  const socleY = 430;
  let b = etape(x, 46, t('LES VERSIONS', 'THE VERSIONS'), t('Chacune s’installe par-dessus la précédente', 'Each one installs over the previous one'));
  // Le socle : la clé de signature, qui ne change jamais.
  b += `<rect x="${x}" y="${socleY}" width="${w}" height="64" rx="14" fill="${C.soft}" stroke="${C.accent}" stroke-opacity=".6"/>`;
  b += `<g fill="none" stroke="${C.accent}" stroke-width="2" stroke-linecap="round"><circle cx="${x + 38}" cy="${socleY + 32}" r="9"/><path d="M${x + 47} ${socleY + 32} H${x + 70} M${x + 62} ${socleY + 32} v7 M${x + 68} ${socleY + 32} v5"/></g>`;
  b += text(x + 92, socleY + 28, t('La même clé de signature', 'The same signing key'), { size: 16, color: C.pale, weight: 700 });
  b += text(x + 92, socleY + 49, t('certificat SHA-256 9a8c6764…0f00feeb, CN=BeVannes', 'certificate SHA-256 9a8c6764…0f00feeb, CN=BeVannes'), { size: 13.5, color: C.text, font: MONO });
  liste.forEach(([v, date, titre, detail], i) => {
    const y = socleY - (i + 1) * (h + 12);
    const a = 0.06 + i * 0.2;
    const derniere = i === liste.length - 1;
    b += `<g opacity="0">${appear(D, a, 0.94, 0.02)}<g>${move(D, [[0, '0 -60'], [a, '0 -60'], [a + 0.05, '0 0'], [1, '0 0']])}` +
      `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="16" fill="${C.card}" stroke="${derniere ? C.accent : C.line}" stroke-opacity="${derniere ? 0.8 : 1}"/>` +
      text(x + 26, y + 42, v, { size: 26, color: derniere ? C.accent : C.title, weight: 800, font: MONO }) +
      text(x + 26, y + 72, date, { size: 13, color: C.faint, font: MONO }) +
      text(x + 200, y + 42, titre, { size: 18, color: C.title, weight: 700 }) +
      text(x + 200, y + 70, detail, { size: 15, color: C.text }) +
      (derniere ? `<rect x="${x + w - 130}" y="${y + 20}" width="106" height="26" rx="13" fill="${C.soft}"/>` + text(x + w - 77, y + 38, t('en cours', 'current'), { size: 13, color: C.accent, anchor: 'middle', weight: 600 }) : '') +
      '</g></g>';
  });
  return svg(W, H, b, t(
    "Animation : les trois versions de BeVannes, publiées le 24 septembre 2026, tombent l'une sur l'autre, comme elles s'installent par-dessus sur le téléphone. En bas, le socle ne bouge pas : la même clé de signature, certificat SHA-256 9a8c6764…0f00feeb. 2.0.0 à 11 h 43 : la réécriture en Flutter, à la place du prototype FlutterFlow, en mode démo. 2.0.1 à 12 h 34 : les animations, radar, jauge, reflet, coche et confettis. 2.1.0 à 17 h 27, la version en cours : deux applications, le vrai jeu relié à Firebase et la démo à côté.",
    'Animation: the three BeVannes versions, released on 24 September 2026, fall onto one another, the way they install over each other on the phone. At the bottom, the base never moves: the same signing key, certificate SHA-256 9a8c6764…0f00feeb. 2.0.0 at 11:43: the Flutter rewrite, replacing the FlutterFlow prototype, in demo mode. 2.0.1 at 12:34: the animations, radar, gauge, shine, tick and confetti. 2.1.0 at 17:27, the current version: two apps, the real game wired to Firebase and the demo next to it.',
  ));
}

// --- Écriture -------------------------------------------------------------

fs.mkdirSync(OUT, { recursive: true });
for (const [nom, f] of Object.entries({ vitrine, tirage, approche, mur, rappel, lieux, parcours, triche, serie, cadrage, fonctionnalites, ecrans, confidentialite, stack, couches, modele, tests, versions })) {
  const contenu = f();
  fs.writeFileSync(path.join(OUT, `${nom}.svg`), contenu);
  console.log(`  ${nom}.svg  ${(contenu.length / 1024).toFixed(1)} Ko`);
}
