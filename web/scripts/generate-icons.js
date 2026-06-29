import sharp from 'sharp';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const svgSource = readFileSync(resolve(__dirname, '../public/icons/icon.svg'));
const outDir = resolve(__dirname, '../public/icons');

const sizes = [
  { name: 'icon-64.png', size: 64 },
  { name: 'icon-192.png', size: 192 },
  { name: 'icon-512.png', size: 512 },
  { name: 'apple-touch-icon-180.png', size: 180 },
];

for (const { name, size } of sizes) {
  await sharp(svgSource)
    .resize(size, size)
    .png()
    .toFile(resolve(outDir, name));
  console.log(`Generated ${name} (${size}x${size})`);
}

console.log('Done.');
