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

// --- Écriture -------------------------------------------------------------

fs.mkdirSync(OUT, { recursive: true });
for (const [nom, f] of Object.entries({ vitrine, tirage, approche, mur, rappel, lieux, parcours, triche, serie, cadrage })) {
  const contenu = f();
  fs.writeFileSync(path.join(OUT, `${nom}.svg`), contenu);
  console.log(`  ${nom}.svg  ${(contenu.length / 1024).toFixed(1)} Ko`);
}
