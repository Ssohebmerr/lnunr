/**
 * Emits lightweight magazine web bundles:
 * - long-articles-meta.js (index catalog, no bodies)
 * - bodies/{slug}.json (one article per file for article page)
 *
 * Run after build-extra-long-articles.mjs:
 *   node scripts/build-extra-long-articles.mjs
 *   node scripts/emit-magazine-web-bundles.cjs
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const MAG = path.join(ROOT, 'public/magazine');
const BODIES = path.join(MAG, 'bodies');

function loadArticles() {
  const ctx = { window: {}, global: null };
  ctx.global = ctx;
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(MAG, 'long-articles-extra.js'), 'utf8'), ctx);
  vm.runInContext(fs.readFileSync(path.join(MAG, 'long-articles.js'), 'utf8'), ctx);
  return ctx.window.LUNE_LONG_ARTICLES;
}

function main() {
  const articles = loadArticles();
  if (!Array.isArray(articles) || articles.length !== 1000) {
    throw new Error(`Expected 1000 articles, got ${articles?.length ?? 0}`);
  }

  fs.mkdirSync(BODIES, { recursive: true });

  const meta = articles.map((article) => ({
    id: article.id,
    slug: article.slug,
    category: article.category,
    minutes: article.minutes,
    adultsOnly: article.adultsOnly,
    published: article.published,
    order: article.order,
    titleEn: article.titleEn,
    titleAr: article.titleAr,
    excerptAr: article.excerptAr,
    excerptEn: article.excerptEn,
    coverImageUrl: article.coverImageUrl,
    featured: article.featured,
    sourceUrls: article.sourceUrls,
  }));

  fs.writeFileSync(
    path.join(MAG, 'long-articles-meta.js'),
    `/* Auto-generated magazine catalog — no article bodies */\n(function (root) {\n  'use strict';\n  root.LUNE_LONG_ARTICLES_META = ${JSON.stringify(meta)};\n})(typeof window !== 'undefined' ? window : global);\n`,
    'utf8',
  );

  for (const article of articles) {
    fs.writeFileSync(
      path.join(BODIES, `${article.slug}.json`),
      JSON.stringify(article),
      'utf8',
    );
  }

  console.log(`Wrote meta (${meta.length}) and ${articles.length} body JSON files`);
}

main();
