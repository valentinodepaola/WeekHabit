import fs from "node:fs/promises";
import path from "node:path";
import sharp from "/Users/valentino/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp/lib/index.js";

const outDir = process.argv[2] ?? path.join(process.cwd(), "exports", "weekhabit-icons");

const svg = (body) => `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  ${body}
</svg>`;

const icons = [
  {
    file: "WeekHabit_01_Week_Ring.png",
    body: `
      <defs>
        <linearGradient id="g1bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#F5EBDC"/>
          <stop offset="1" stop-color="#E8D5BD"/>
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#g1bg)"/>
      <g transform="translate(512 540)">
        <circle r="280" fill="none" stroke="#E0CDB2" stroke-width="2" stroke-dasharray="4 8"/>
        <circle cx="-280" cy="0" r="50" fill="#C2573C"/>
        <circle cx="-194" cy="-202" r="50" fill="#C2573C"/>
        <circle cx="0" cy="-280" r="50" fill="#D8893E"/>
        <circle cx="194" cy="-202" r="50" fill="#D8893E"/>
        <circle cx="280" cy="0" r="60" fill="#C2573C" stroke="#fff" stroke-width="14"/>
        <circle cx="280" cy="0" r="86" fill="none" stroke="#C2573C" stroke-width="6" opacity="0.35"/>
      </g>
      <text x="512" y="380" text-anchor="middle" font-family="Times New Roman, Georgia, serif" font-style="italic" font-size="180" font-weight="500" fill="#1C1812">w</text>
    `,
  },
  {
    file: "WeekHabit_02_Streak.png",
    body: `
      <defs>
        <linearGradient id="g2bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#D8893E"/>
          <stop offset="0.6" stop-color="#C2573C"/>
          <stop offset="1" stop-color="#8E2D1F"/>
        </linearGradient>
        <radialGradient id="g2glow" cx="0.5" cy="0.65" r="0.5">
          <stop offset="0" stop-color="#FFD79A" stop-opacity="0.7"/>
          <stop offset="1" stop-color="#FFD79A" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#g2bg)"/>
      <rect width="1024" height="1024" fill="url(#g2glow)"/>
      <path d="M512 220 C 380 360, 320 460, 320 600 C 320 760, 420 840, 512 840 C 604 840, 704 760, 704 600 C 704 480, 620 420, 580 340 C 560 460, 510 460, 512 220 Z" fill="#FFEBC9" opacity="0.95"/>
      <path d="M512 360 C 440 440, 410 510, 410 600 C 410 700, 460 750, 512 750 C 564 750, 614 700, 614 600 C 614 530, 570 500, 540 450 C 530 520, 500 520, 512 360 Z" fill="#C2573C"/>
      <g transform="translate(512 920)">
        <rect x="-180" y="-12" width="48" height="24" rx="12" fill="#FFEBC9" opacity="0.4"/>
        <rect x="-120" y="-12" width="48" height="24" rx="12" fill="#FFEBC9" opacity="0.55"/>
        <rect x="-60" y="-12" width="48" height="24" rx="12" fill="#FFEBC9" opacity="0.7"/>
        <rect x="0" y="-12" width="48" height="24" rx="12" fill="#FFEBC9" opacity="0.85"/>
        <rect x="60" y="-12" width="48" height="24" rx="12" fill="#FFEBC9"/>
        <rect x="120" y="-12" width="48" height="24" rx="12" fill="#FFFFFF"/>
        <rect x="180" y="-16" width="48" height="32" rx="14" fill="#FFFFFF"/>
      </g>
    `,
  },
  {
    file: "WeekHabit_03_Editorial_W.png",
    body: `
      <defs>
        <linearGradient id="g3bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#1C1812"/>
          <stop offset="1" stop-color="#3a2e21"/>
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#g3bg)"/>
      <text x="512" y="730" text-anchor="middle" font-family="Times New Roman, Georgia, serif" font-style="italic" font-size="780" font-weight="500" fill="#F5EBDC" letter-spacing="-30">W</text>
      <circle cx="780" cy="280" r="48" fill="#C2573C"/>
    `,
  },
  {
    file: "WeekHabit_04_Grid.png",
    body: `
      <rect width="1024" height="1024" fill="#FDFAF3"/>
      <g transform="translate(150 240)">
        <g font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="40" font-weight="700" fill="#B5A89A" letter-spacing="2">
          <text x="0" y="0">L</text>
          <text x="120" y="0">M</text>
          <text x="240" y="0">X</text>
          <text x="360" y="0">J</text>
          <text x="480" y="0">V</text>
          <text x="600" y="0">S</text>
          <text x="720" y="0">D</text>
        </g>
        <g transform="translate(0 70)">
          <circle cx="14" cy="50" r="42" fill="#C2573C"/>
          <circle cx="134" cy="50" r="42" fill="#C2573C"/>
          <circle cx="254" cy="50" r="42" fill="#E0CDB2"/>
          <circle cx="374" cy="50" r="42" fill="#C2573C"/>
          <circle cx="494" cy="50" r="42" fill="#C2573C"/>
          <circle cx="614" cy="50" r="42" fill="#C2573C"/>
          <circle cx="734" cy="50" r="42" fill="#E0CDB2"/>
        </g>
        <g transform="translate(0 200)">
          <circle cx="14" cy="50" r="42" fill="#C2573C"/>
          <circle cx="134" cy="50" r="60" fill="#1C1812"/>
          <circle cx="134" cy="50" r="42" fill="#D8893E"/>
          <circle cx="254" cy="50" r="42" fill="#E0CDB2"/>
          <circle cx="374" cy="50" r="42" fill="#E0CDB2" stroke="#E0CDB2" stroke-dasharray="4 4" stroke-width="2"/>
          <circle cx="494" cy="50" r="42" fill="#FDFAF3" stroke="#E0CDB2" stroke-dasharray="6 6" stroke-width="3"/>
          <circle cx="614" cy="50" r="42" fill="#FDFAF3" stroke="#E0CDB2" stroke-dasharray="6 6" stroke-width="3"/>
          <circle cx="734" cy="50" r="42" fill="#FDFAF3" stroke="#E0CDB2" stroke-dasharray="6 6" stroke-width="3"/>
        </g>
      </g>
    `,
  },
  {
    file: "WeekHabit_05_Orbit.png",
    body: `
      <defs>
        <linearGradient id="g5bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#FFD79A"/>
          <stop offset="0.5" stop-color="#E89A5A"/>
          <stop offset="1" stop-color="#C2573C"/>
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#g5bg)"/>
      <circle cx="512" cy="512" r="320" fill="#FDF5E5"/>
      <circle cx="640" cy="430" r="290" fill="url(#g5bg)"/>
      <g fill="#FDF5E5">
        <circle cx="512" cy="120" r="22"/>
        <circle cx="765" cy="186" r="22" opacity="0.85"/>
        <circle cx="900" cy="378" r="22" opacity="0.7"/>
        <circle cx="900" cy="638" r="22" opacity="0.55"/>
        <circle cx="765" cy="830" r="22" opacity="0.4"/>
        <circle cx="512" cy="900" r="22" opacity="0.3"/>
        <circle cx="259" cy="830" r="22" opacity="0.25"/>
      </g>
    `,
  },
  {
    file: "WeekHabit_06_Stack.png",
    body: `
      <defs>
        <linearGradient id="g6bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#F5EBDC"/>
          <stop offset="1" stop-color="#EAD9BC"/>
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" fill="url(#g6bg)"/>
      <g transform="translate(240 200)">
        <rect x="0" y="0" width="544" height="48" rx="24" fill="#C2573C"/>
        <rect x="-10" y="74" width="544" height="48" rx="24" fill="#C2573C"/>
        <rect x="20" y="148" width="544" height="48" rx="24" fill="#D8893E"/>
        <rect x="-6" y="222" width="544" height="48" rx="24" fill="#C2573C"/>
        <rect x="14" y="296" width="544" height="48" rx="24" fill="#D8893E"/>
        <rect x="0" y="370" width="544" height="48" rx="24" fill="#C2573C"/>
        <g transform="translate(-30 444)">
          <rect x="0" y="0" width="604" height="64" rx="32" fill="#1C1812"/>
          <path d="M180 32 L260 100 L420 -36" stroke="#fff" stroke-width="36" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        </g>
      </g>
    `,
  },
];

await fs.mkdir(outDir, { recursive: true });

for (const icon of icons) {
  await sharp(Buffer.from(svg(icon.body)))
    .resize(1024, 1024, { fit: "fill" })
    .png({ compressionLevel: 9, palette: false })
    .toFile(path.join(outDir, icon.file));
}

console.log(`Exported ${icons.length} icons to ${outDir}`);
