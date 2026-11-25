// Lists everything Vipul still needs to fill in:
//   - every `TODO(vipul)` comment in the repo
//   - every <Prompt> left in a flight report
//   - every "[ ]" / "[date]" style placeholder value in report front-matter
// Usage: npm run todo
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = new URL('../..', import.meta.url).pathname;
const skip = new Set(['node_modules', 'dist', '.astro', '.git', 'mockups']);
const exts = /\.(astro|ts|mjs|md|mdx|ya?ml|json|css|conf|sh|yml)$/;
const hits = [];

function walk(dir) {
  for (const name of readdirSync(dir)) {
    if (skip.has(name)) continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p);
    else if (exts.test(name)) scan(p);
  }
}

function scan(file) {
  const rel = relative(root, file);
  if (rel.endsWith('Prompt.astro')) return;
  const inContent = rel.includes('content/');
  readFileSync(file, 'utf8')
    .split('\n')
    .forEach((line, i) => {
      const t = line.trim();
      if (t.includes('TODO(vipul)')) {
        hits.push([rel, i + 1, t.replace(/^.*TODO\(vipul\):?\s*/, '')]);
      } else if (inContent && t.includes('<Prompt>')) {
        hits.push([rel, i + 1, 'story: ' + t.replace(/<\/?Prompt>/g, '')]);
      } else if (inContent && /'\[[^\]]*\]/.test(t)) {
        hits.push([rel, i + 1, 'placeholder: ' + t]);
      }
    });
}

// Only real content and code: docs that merely mention TODO(vipul) are skipped.
for (const dir of ['site/src', 'deploy']) walk(join(root, dir));
let last = '';
for (const [file, line, text] of hits) {
  if (file !== last) console.log(`\n${file}`);
  last = file;
  console.log(`  ${String(line).padStart(4)}  ${text}`);
}
console.log(`\n${hits.length} item(s) left to fill in.`);
