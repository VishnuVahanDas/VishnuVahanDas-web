// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://vishnuvahan.com',
  trailingSlash: 'ignore',
  integrations: [
    mdx(),
    // The component kit is a dev reference page, keep it out of the sitemap.
    sitemap({ filter: (page) => !page.includes('/kit') }),
  ],
});
