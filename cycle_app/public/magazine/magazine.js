(function () {
  'use strict';

  const page = document.body.dataset.page || 'index';
  const catalog = Array.isArray(window.LUNE_LONG_ARTICLES_META) && window.LUNE_LONG_ARTICLES_META.length
    ? window.LUNE_LONG_ARTICLES_META
    : (Array.isArray(window.LUNE_LONG_ARTICLES) ? window.LUNE_LONG_ARTICLES : []);
  const fullArticles = Array.isArray(window.LUNE_LONG_ARTICLES) ? window.LUNE_LONG_ARTICLES : [];
  const articles = page === 'article' && fullArticles.length ? fullArticles : catalog;
  const savedLanguage = localStorage.getItem('lune-magazine-language');
  let language = savedLanguage === 'en' ? 'en' : 'ar';
  let activeCategory = 'all';
  let query = '';

  const copy = {
    ar: {
      all: 'الكل', featured: 'دليل مختار', read: 'اقرئي الدليل', minutes: 'دقيقة قراءة',
      results: 'دليل صحي طويل', noResults: 'لم نجد مقالًا يطابق البحث. جرّبي كلمة أو تصنيفًا آخر.',
      categories: { basics: 'أساسيات الدورة', health: 'الصحة', mind: 'النفس والنوم', nutrition: 'التغذية', fitness: 'الحركة', fertility: 'الخصوبة', adult: 'مواضيع +18' },
      sources: 'المصادر الطبية', sourceNote: 'المحتوى مبني على مراجع صحية رسمية، وهو للتثقيف العام وليس بديلًا عن التشخيص.',
      related: 'أدلة مرتبطة', share: 'نسخ الرابط', copied: 'تم النسخ', back: 'كل المقالات', language: 'English', notFound: 'المقال غير موجود', notFoundBody: 'قد يكون الرابط قديمًا أو غير مكتمل.'
    },
    en: {
      all: 'All', featured: 'Featured guide', read: 'Read the guide', minutes: 'min read',
      results: 'in-depth health guides', noResults: 'No article matched your search. Try another word or category.',
      categories: { basics: 'Cycle basics', health: 'Health', mind: 'Mind & sleep', nutrition: 'Nutrition', fitness: 'Movement', fertility: 'Fertility', adult: '18+ topics' },
      sources: 'Medical sources', sourceNote: 'Content is based on official health references and is general education, not a substitute for diagnosis.',
      related: 'Related guides', share: 'Copy link', copied: 'Copied', back: 'All articles', language: 'العربية', notFound: 'Article not found', notFoundBody: 'The link may be old or incomplete.'
    }
  };

  function text(key) { return copy[language][key]; }
  function field(article, name) { return article[`${name}${language === 'ar' ? 'Ar' : 'En'}`] || ''; }
  function categoryLabel(category) { return copy[language].categories[category] || category; }
  function articleUrl(article) { return `/magazine/article.html?slug=${encodeURIComponent(article.slug)}`; }

  function applyLanguage() {
    const html = document.documentElement;
    html.lang = language;
    html.dir = language === 'ar' ? 'rtl' : 'ltr';
    document.querySelectorAll('[data-ar][data-en]').forEach((element) => {
      element.textContent = element.dataset[language];
    });
    document.querySelectorAll('[data-lang-toggle]').forEach((button) => { button.textContent = text('language'); });
    localStorage.setItem('lune-magazine-language', language);
  }

  function installLanguageToggle(render) {
    document.querySelectorAll('[data-lang-toggle]').forEach((button) => {
      button.addEventListener('click', () => {
        language = language === 'ar' ? 'en' : 'ar';
        applyLanguage();
        render();
      });
    });
  }

  function makeCard(article) {
    const card = document.createElement('article');
    card.className = 'article-card';

    const media = document.createElement('a');
    media.className = 'article-card-media';
    media.href = articleUrl(article);
    const image = document.createElement('img');
    image.src = article.coverImageUrl;
    image.alt = field(article, 'title');
    image.loading = 'lazy';
    image.width = 720;
    image.height = 450;
    media.appendChild(image);
    if (article.featured) {
      const featured = document.createElement('span');
      featured.className = 'article-card-featured';
      featured.textContent = text('featured');
      media.appendChild(featured);
    }

    const body = document.createElement('div');
    body.className = 'article-card-body';
    const meta = document.createElement('div');
    meta.className = 'article-card-meta';
    const category = document.createElement('span');
    category.textContent = categoryLabel(article.category);
    const time = document.createElement('span');
    time.textContent = `${article.minutes} ${text('minutes')}`;
    meta.append(category, time);
    const heading = document.createElement('h2');
    const titleLink = document.createElement('a');
    titleLink.href = articleUrl(article);
    titleLink.textContent = field(article, 'title');
    heading.appendChild(titleLink);
    const excerpt = document.createElement('p');
    excerpt.textContent = field(article, 'excerpt');
    const more = document.createElement('a');
    more.className = 'article-card-link';
    more.href = articleUrl(article);
    more.textContent = `${text('read')} ←`;
    body.append(meta, heading, excerpt, more);
    card.append(media, body);
    return card;
  }

  function renderIndex() {
    const grid = document.getElementById('articlesGrid');
    if (!grid) return;
    const normalized = query.trim().toLocaleLowerCase(language === 'ar' ? 'ar' : 'en');
    const filtered = articles.filter((article) => {
      const inCategory = activeCategory === 'all' || article.category === activeCategory;
      const haystack = `${article.titleAr} ${article.titleEn} ${article.excerptAr} ${article.excerptEn}`.toLocaleLowerCase();
      return inCategory && (!normalized || haystack.includes(normalized));
    });
    grid.replaceChildren();
    if (!filtered.length) {
      const empty = document.createElement('div');
      empty.className = 'empty-magazine';
      empty.textContent = text('noResults');
      grid.appendChild(empty);
    } else {
      filtered.forEach((article) => grid.appendChild(makeCard(article)));
    }
    const count = document.getElementById('resultCount');
    if (count) count.textContent = `${filtered.length} ${text('results')}`;
    document.getElementById('articleTotal').textContent = articles.length;
    renderCategoryButtons();
  }

  function renderCategoryButtons() {
    const bar = document.getElementById('categoryBar');
    if (!bar) return;
    const present = [...new Set(articles.map((article) => article.category))];
    bar.replaceChildren();
    ['all', ...present].forEach((category) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `category-chip${category === activeCategory ? ' active' : ''}`;
      button.textContent = category === 'all' ? text('all') : categoryLabel(category);
      button.addEventListener('click', () => { activeCategory = category; renderIndex(); });
      bar.appendChild(button);
    });
  }

  function initIndex() {
    applyLanguage();
    const search = document.getElementById('articleSearch');
    search.addEventListener('input', (event) => { query = event.target.value; renderIndex(); });
    installLanguageToggle(renderIndex);
    renderIndex();
  }

  function appendBody(container, bodyText) {
    const blocks = bodyText.split(/\n\s*\n/u).map((block) => block.trim()).filter(Boolean);
    const imageRe = /^!\[([^\]]*)\]\((https?:\/\/[^)\s]+)\)$/u;
    const imageLineRe = /^!\[([^\]]*)\]\((https?:\/\/[^)\s]+)\)$/u;

    function appendImage(caption, src) {
      const figure = document.createElement('figure');
      figure.className = 'article-inline-figure';
      const image = document.createElement('img');
      image.src = src;
      image.alt = caption || '';
      image.loading = 'lazy';
      image.decoding = 'async';
      image.width = 1200;
      image.height = 750;
      image.onerror = () => {
        figure.classList.add('is-broken');
        figure.replaceChildren();
        const note = document.createElement('p');
        note.className = 'article-inline-fallback';
        note.textContent = caption || '';
        figure.appendChild(note);
      };
      figure.appendChild(image);
      if (caption) {
        const figcaption = document.createElement('figcaption');
        figcaption.textContent = caption;
        figure.appendChild(figcaption);
      }
      container.appendChild(figure);
    }

    blocks.forEach((block) => {
      if (block.startsWith('## ')) {
        const heading = document.createElement('h2');
        heading.textContent = block.slice(3).trim();
        container.appendChild(heading);
        return;
      }
      const imageMatch = block.match(imageRe);
      if (imageMatch) {
        appendImage(imageMatch[1], imageMatch[2]);
        return;
      }
      const lines = block.split('\n').map((line) => line.trim()).filter(Boolean);
      if (lines.some((line) => imageLineRe.test(line))) {
        lines.forEach((line) => {
          const m = line.match(imageLineRe);
          if (m) appendImage(m[1], m[2]);
          else {
            const paragraph = document.createElement('p');
            paragraph.textContent = line;
            container.appendChild(paragraph);
          }
        });
        return;
      }
      if (lines.every((line) => line.startsWith('• '))) {
        const list = document.createElement('ul');
        lines.forEach((line) => {
          const item = document.createElement('li');
          item.textContent = line.slice(2).trim();
          list.appendChild(item);
        });
        container.appendChild(list);
        return;
      }
      const paragraph = document.createElement('p');
      paragraph.textContent = block;
      container.appendChild(paragraph);
    });
  }

  function renderRelated(article) {
    const holder = document.getElementById('relatedList');
    holder.replaceChildren();
    articles.filter((candidate) => candidate.id !== article.id)
      .sort((a, b) => Number(b.category === article.category) - Number(a.category === article.category))
      .slice(0, 3)
      .forEach((candidate) => {
        const link = document.createElement('a');
        link.className = 'related-link';
        link.href = articleUrl(candidate);
        const image = document.createElement('img');
        image.src = candidate.coverImageUrl;
        image.alt = '';
        image.loading = 'lazy';
        const title = document.createElement('span');
        title.textContent = field(candidate, 'title');
        link.append(image, title);
        holder.appendChild(link);
      });
  }

  function showNotFound() {
    const main = document.getElementById('articlePage');
    main.className = 'article-not-found';
    main.replaceChildren();
    const heading = document.createElement('h1');
    heading.textContent = text('notFound');
    const paragraph = document.createElement('p');
    paragraph.textContent = text('notFoundBody');
    const link = document.createElement('a');
    link.className = 'btn btn-primary';
    link.href = '/magazine/';
    link.textContent = text('back');
    main.append(heading, paragraph, link);
  }

  function renderArticle() {
    const slug = new URLSearchParams(location.search).get('slug') || '';
    const fromFull = fullArticles.find((item) => item.slug === slug);
    const fromMeta = catalog.find((item) => item.slug === slug);
    if (!fromFull && !fromMeta) { showNotFound(); return; }

    const apply = (article) => {
      document.title = `${field(article, 'title')} — Lune`;
      const description = document.querySelector('meta[name="description"]');
      if (description) description.content = field(article, 'excerpt');
      document.getElementById('articleCover').src = article.coverImageUrl;
      document.getElementById('articleCover').alt = field(article, 'title');
      document.getElementById('articleTitle').textContent = field(article, 'title');
      document.getElementById('articleCategory').textContent = categoryLabel(article.category);
      document.getElementById('articleMinutes').textContent = `${article.minutes} ${text('minutes')}`;
      const reader = document.getElementById('articleReader');
      reader.replaceChildren();
      const lead = document.createElement('p');
      lead.className = 'lead';
      lead.textContent = field(article, 'excerpt');
      reader.appendChild(lead);
      appendBody(reader, field(article, 'body'));
      const sourceTitle = document.getElementById('sourcesTitle');
      sourceTitle.textContent = text('sources');
      document.getElementById('sourceNote').textContent = text('sourceNote');
      document.getElementById('relatedTitle').textContent = text('related');
      const sources = document.getElementById('articleSources');
      sources.replaceChildren();
      (article.sourceUrls || []).forEach((url) => {
        const item = document.createElement('li');
        const link = document.createElement('a');
        link.href = url;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.textContent = new URL(url).hostname.replace(/^www\./, '');
        item.appendChild(link);
        sources.appendChild(item);
      });
      document.getElementById('copyLink').textContent = text('share');
      document.getElementById('backToMagazine').textContent = text('back');
      renderRelated(article);
    };

    if (fromFull && fromFull.bodyAr && fromFull.bodyEn) {
      apply(fromFull);
      return;
    }

    const reader = document.getElementById('articleReader');
    reader.replaceChildren();
    const loading = document.createElement('p');
    loading.textContent = language === 'ar' ? 'جاري تحميل الدليل…' : 'Loading guide…';
    reader.appendChild(loading);

    fetch(`/magazine/bodies/${encodeURIComponent(slug)}.json`)
      .then((response) => {
        if (!response.ok) throw new Error(String(response.status));
        return response.json();
      })
      .then((article) => apply(article))
      .catch(() => showNotFound());
  }

  function initArticle() {
    applyLanguage();
    installLanguageToggle(renderArticle);
    document.getElementById('copyLink').addEventListener('click', async (event) => {
      try { await navigator.clipboard.writeText(location.href); event.currentTarget.textContent = text('copied'); }
      catch (_) { window.prompt(language === 'ar' ? 'انسخي الرابط:' : 'Copy this link:', location.href); }
    });
    renderArticle();
  }

  if (page === 'article') initArticle(); else initIndex();
})();
