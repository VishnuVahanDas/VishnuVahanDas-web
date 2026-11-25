// Content schemas for the whole site.
// Every piece of text about Vipul lives in src/content/, never inside components.
// The build fails if a file does not match its schema; that is intentional.
import { defineCollection } from 'astro:content';
import { glob, file } from 'astro/loaders';
import { z } from 'astro/zod';

/** Profile: one entry, keyed `vipul` in profile.yaml. */
const profile = defineCollection({
  loader: file('src/content/data/profile.yaml'),
  schema: ({ image }) =>
    z.object({
      name: z.string(),
      callsign: z.string(),
      base: z.string(),
      roles: z.string(),
      tagline: z.string(),
      ratings: z.array(z.object({ title: z.string(), detail: z.string() })),
      education: z.string(),
      email: z.string().optional(),
      linkedin: z.string().optional(),
      github: z.string(),
      photo: image().optional(),
      fieldPhoto: image().optional(),
      fieldPhotoAlt: z.string().optional(),
      resumePdf: z.string().optional(),
    }),
});

/** Flight log: career entries, shown in file order. */
const log = defineCollection({
  loader: file('src/content/data/log.yaml'),
  schema: z.object({
    order: z.number(),
    date: z.string(),
    org: z.string(),
    role: z.string(),
    remark: z.string(),
  }),
});

const ventures = defineCollection({
  loader: file('src/content/data/ventures.yaml'),
  schema: z.object({
    order: z.number(),
    name: z.string(),
    role: z.string(),
    line: z.string(),
    url: z.string().optional(),
  }),
});

const seva = defineCollection({
  loader: file('src/content/data/seva.yaml'),
  schema: z.object({
    order: z.number(),
    name: z.string(),
    what: z.string(),
    url: z.string().optional(),
  }),
});

const hangar = defineCollection({
  loader: file('src/content/data/hangar.yaml'),
  schema: z.object({
    order: z.number(),
    repo: z.string(),
    show: z.boolean().default(true),
  }),
});

/** A node/edge spec drawn by <SketchDiagram> in pencil style. */
const diagramSchema = z.object({
  width: z.number().default(860),
  height: z.number().default(260),
  label: z.string(),
  nodes: z.array(
    z.object({
      id: z.string(),
      label: z.string(),
      x: z.number(),
      y: z.number(),
      w: z.number().default(160),
      h: z.number().default(64),
      shape: z.enum(['box', 'circle', 'dots']).default('box'),
      count: z.number().optional(),
    }),
  ),
  edges: z.array(
    z.object({
      from: z.string(),
      to: z.string(),
      label: z.string().optional(),
    }),
  ),
});

const reports = defineCollection({
  loader: glob({ pattern: '**/*.mdx', base: './src/content/reports' }),
  schema: ({ image }) =>
    z.object({
      code: z.string().regex(/^FR-\d{2}$/),
      title: z.string(),
      folderTitle: z.string().optional(),
      kind: z.enum(['Aerial', 'Software', 'Venture', 'Mentoring', 'App']),
      summary: z.string(),
      status: z.enum(['INCIDENT LOGGED', 'RESOLVED', 'IN SERVICE', 'IN BUILD', 'MISSION FLOWN']),
      pageStamp: z
        .enum(['INCIDENT LOGGED', 'RESOLVED', 'IN SERVICE', 'IN BUILD', 'MISSION FLOWN'])
        .optional(),
      order: z.number(),
      date: z.string().optional(),
      aircraft: z.string(),
      stack: z.string(),
      link: z.string().optional(),
      linkLabel: z.string().optional(),
      fields: z.array(z.object({ k: z.string(), v: z.string() })).optional(),
      photos: z
        .array(
          z.object({
            src: image().optional(),
            video: z.string().optional(),
            alt: z.string(),
            caption: z.string(),
            rotate: z.number().default(0),
          }),
        )
        .default([]),
      diagram: diagramSchema.optional(),
      numbers: z.array(z.object({ label: z.string(), value: z.string() })).default([]),
      draft: z.boolean().default(false),
    }),
});

const notes = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/notes' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    summary: z.string(),
    draft: z.boolean().default(false),
  }),
});

export const collections = { profile, log, ventures, seva, hangar, reports, notes };
