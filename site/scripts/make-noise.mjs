// Generates public/noise.png: a 160×160 tiling grain used for the paper texture.
// Run once with `npm run noise` (the PNG is committed, so you rarely need this).
import sharp from 'sharp';

const size = 160;
const channels = 4;
const data = Buffer.alloc(size * size * channels);
let seed = 108;
const rand = () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;

for (let i = 0; i < size * size; i++) {
  const v = 150 + Math.floor(rand() * 4) * 30; // warm light grain, 4 tones (compresses well)
  data[i * 4] = v;
  data[i * 4 + 1] = Math.max(0, v - 8);
  data[i * 4 + 2] = Math.max(0, v - 20);
  data[i * 4 + 3] = Math.floor(rand() * 3) * 20; // low alpha, 3 steps: subtle
}

await sharp(data, { raw: { width: size, height: size, channels } })
  .png({ compressionLevel: 9, palette: true, colours: 16, dither: 0 })
  .toFile(new URL('../public/noise.png', import.meta.url).pathname);

console.log('public/noise.png written');
