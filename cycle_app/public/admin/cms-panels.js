const FUNCTIONS_BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';

export function initExtraAdmin(ctx) {
  const {
    auth, admin, $, esc, show, hide,
    loadOverview, logAdminActivity,
  } = ctx;

  const TAB_NAMES = [
    'overview', 'articles', 'notifications', 'banners', 'settings',
    'communities', 'moderation', 'reports', 'users', 'activity',
    // v3 tabs:
    'analytics', 'premium', 'promo', 'ai', 'feedback', 'admins',
  ];

  document.querySelectorAll('.tab').forEach((t) => {
    t.onclick = () => {
      document.querySelectorAll('.tab').forEach((x) => x.classList.remove('active'));
      t.classList.add('active');
      TAB_NAMES.forEach((name) => {
        const node = $(`tab-${name}`);
        if (node) node.classList.toggle('hidden', name !== t.dataset.tab);
      });
      // load tab data lazily when first opened
      lazyLoadTab(t.dataset.tab);
    };
  });

  const _loadedTabs = new Set();
  function lazyLoadTab(name) {
    if (_loadedTabs.has(name)) return;
    _loadedTabs.add(name);
    try {
      switch (name) {
        case 'analytics': loadAnalytics(); break;
        case 'premium': loadPremiumPanel(); break;
        case 'promo': loadPromoCodes(); break;
        case 'ai': loadAiStats(); break;
        case 'feedback': loadFeedback(); break;
        case 'admins': loadAdmins(); break;
        case 'notifications': loadScheduled(); break;
      }
    } catch (e) {
      console.warn('lazyLoadTab', name, e);
    }
  }

  // ---------------- broadcasts ----------------
  $('sendBroadcast').onclick = sendBroadcast;
  setupBroadcastPreview();
  loadBroadcasts();

  function setupBroadcastPreview() {
    const titleEl = $('broadcastTitle');
    const bodyEl = $('broadcastBody');
    const card = bodyEl?.closest('.card');
    if (!card || !titleEl || !bodyEl) return;
    if (document.getElementById('notifPreview')) return;
    // mount preview right after textarea
    const preview = document.createElement('div');
    preview.id = 'notifPreview';
    preview.className = 'notif-preview';
    preview.innerHTML = `
      <div class="np-ico">🌸</div>
      <div class="np-body">
        <div class="np-app">LUNE · الآن</div>
        <div class="np-title" id="npTitle">عنوان الإشعار سيظهر هنا</div>
        <div class="np-text" id="npText">نص الإشعار سيظهر بهذا الشكل عند المستخدمات.</div>
      </div>
    `;
    // insert before the toolbar (which contains the send button)
    const toolbar = card.querySelector('.toolbar');
    if (toolbar) card.insertBefore(preview, toolbar);
    else card.appendChild(preview);

    const sync = () => {
      const t = titleEl.value.trim();
      const b = bodyEl.value.trim();
      $('npTitle').textContent = t || 'عنوان الإشعار سيظهر هنا';
      $('npText').textContent = b || 'نص الإشعار سيظهر بهذا الشكل عند المستخدمات.';
    };
    titleEl.addEventListener('input', sync);
    bodyEl.addEventListener('input', sync);
  }

  async function sendBroadcast() {
    $('broadcastErr').textContent = '';
    const title = $('broadcastTitle').value.trim();
    const body = $('broadcastBody').value.trim();
    if (!title || !body) {
      $('broadcastErr').textContent = 'العنوان والنص مطلوبان';
      return;
    }
    const audience = $('broadcastAudience').value;
    const audLabel = audience === 'premium' ? 'مشتركو Premium فقط' : 'جميع المستخدمين';
    if (!confirm(`إرسال الإشعار إلى: ${audLabel}؟\n\n📌 ${title}\n${body}\n\nلا يمكن التراجع بعد الإرسال.`)) return;
    $('sendBroadcast').disabled = true;
    try {
      const user = auth.currentUser;
      const token = await user.getIdToken();
      const res = await fetch(`${FUNCTIONS_BASE}/adminBroadcast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ title, body, audience }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'فشل الإرسال');
      alert(`✅ تم الإرسال\n\nنجح: ${data.sent} · فشل: ${data.failed} · إجمالي: ${data.tokensAttempted} جهاز`);
      $('broadcastTitle').value = '';
      $('broadcastBody').value = '';
      // re-sync preview
      const npT = document.getElementById('npTitle');
      const npX = document.getElementById('npText');
      if (npT) npT.textContent = 'عنوان الإشعار سيظهر هنا';
      if (npX) npX.textContent = 'نص الإشعار سيظهر بهذا الشكل عند المستخدمات.';
      await loadBroadcasts();
      if (logAdminActivity) await logAdminActivity('broadcast', title);
    } catch (e) {
      $('broadcastErr').textContent = e.message;
    } finally {
      $('sendBroadcast').disabled = false;
    }
  }

  async function loadBroadcasts() {
    const box = $('broadcastsList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['adminBroadcasts'],
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: 20,
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا إشعارات بعد</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const b = d.data();
        const when = b.createdAt?.toDate ? b.createdAt.toDate().toLocaleString('ar') : '';
        return `<div style="padding:10px 0;border-bottom:1px solid #F3EAEF">
          <strong>${esc(b.title)}</strong>
          <div class="muted">${esc(when)} · ${esc(b.audience || 'all')} · ${esc(String(b.sent ?? 0))} وصل</div>
          <div class="content-quote">${esc(b.body)}</div>
        </div>`;
      }).join('');
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // ---------------- banners ----------------
  let _editingBannerId = null;
  $('addBanner').onclick = () => openBannerModal(null);
  $('bannerModalClose').onclick = closeBannerModal;
  $('cancelBanner').onclick = closeBannerModal;
  $('saveBanner').onclick = saveBanner;
  $('bannerModal').onclick = (e) => { if (e.target === $('bannerModal')) closeBannerModal(); };
  loadBanners();

  function clearBannerForm() {
    _editingBannerId = null;
    $('bannerModalTitle').textContent = 'بانر جديد';
    $('bannerId').value = '';
    $('bannerId').disabled = false;
    $('bannerTitleAr').value = '';
    $('bannerTitleEn').value = '';
    $('bannerBodyAr').value = '';
    $('bannerBodyEn').value = '';
    $('bannerActionUrl').value = '';
    $('bannerAccent').value = '#E8A0BF';
    $('bannerOrder').value = '0';
    $('bannerPublished').checked = true;
    $('bannerErr').textContent = '';
  }

  async function openBannerModal(id) {
    clearBannerForm();
    if (id) {
      _editingBannerId = id;
      $('bannerModalTitle').textContent = 'تعديل البانر';
      $('bannerId').value = id;
      $('bannerId').disabled = true;
      const snap = await admin.get(['appBanners', id]);
      const b = snap.data() || {};
      $('bannerTitleAr').value = b.titleAr || '';
      $('bannerTitleEn').value = b.titleEn || '';
      $('bannerBodyAr').value = b.bodyAr || '';
      $('bannerBodyEn').value = b.bodyEn || '';
      $('bannerActionUrl').value = b.actionUrl || '';
      $('bannerAccent').value = b.accentHex || '#E8A0BF';
      $('bannerOrder').value = String(b.order ?? 0);
      $('bannerPublished').checked = b.published !== false;
    }
    show('bannerModal');
  }

  function closeBannerModal() { hide('bannerModal'); }

  async function saveBanner() {
    const id = ($('bannerId').value.trim() || _editingBannerId || '').replace(/\s+/g, '_');
    if (!id) { $('bannerErr').textContent = 'المعرّف مطلوب'; return; }
    const payload = {
      titleAr: $('bannerTitleAr').value.trim(),
      titleEn: $('bannerTitleEn').value.trim(),
      bodyAr: $('bannerBodyAr').value.trim(),
      bodyEn: $('bannerBodyEn').value.trim(),
      actionUrl: $('bannerActionUrl').value.trim(),
      accentHex: $('bannerAccent').value.trim() || '#E8A0BF',
      order: parseInt($('bannerOrder').value, 10) || 0,
      published: $('bannerPublished').checked,
      updatedAt: admin.SERVER_TS,
    };
    $('saveBanner').disabled = true;
    try {
      await admin.set(['appBanners', id], payload, true);
      closeBannerModal();
      await loadBanners();
      if (logAdminActivity) await logAdminActivity('banner_save', id);
    } catch (e) {
      $('bannerErr').textContent = e.message;
    } finally {
      $('saveBanner').disabled = false;
    }
  }

  async function loadBanners() {
    const box = $('bannersList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['appBanners'],
        orderBy: { field: 'order', dir: 'asc' },
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا بانرات — أضيفي بانرًا جديدًا</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const b = d.data();
        const pub = b.published !== false;
        return `<div style="padding:10px 0;border-bottom:1px solid #F3EAEF">
          <span class="pill ${pub ? 'live' : 'draft'}">${pub ? 'منشور' : 'مسودة'}</span>
          <strong>${esc(b.titleAr || d.id)}</strong>
          <div class="row-actions">
            <button class="btn sm" data-edit-banner="${esc(d.id)}">تعديل</button>
            <button class="btn danger sm" data-del-banner="${esc(d.id)}">حذف</button>
          </div>
        </div>`;
      }).join('');
      box.querySelectorAll('[data-edit-banner]').forEach((b) => {
        b.onclick = () => openBannerModal(b.dataset.editBanner);
      });
      box.querySelectorAll('[data-del-banner]').forEach((b) => {
        b.onclick = async () => {
          if (!confirm('حذف البانر؟')) return;
          await admin.delete(['appBanners', b.dataset.delBanner]);
          await loadBanners();
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // ---------------- settings ----------------
  $('saveSettings').onclick = saveSettings;
  loadSettings();

  async function loadSettings() {
    try {
      const snap = await admin.get(['appSettings', 'main']);
      const s = snap.data() || {};
      $('setCommunityEnabled').checked = s.communityEnabled !== false;
      $('setAiEducationEnabled').checked = s.aiEducationEnabled !== false;
      $('setAnnouncementActive').checked = s.announcementActive === true;
      $('setAnnouncementTitleAr').value = s.announcementTitleAr || '';
      $('setAnnouncementTitleEn').value = s.announcementTitleEn || '';
      $('setAnnouncementBodyAr').value = s.announcementBodyAr || '';
      $('setAnnouncementBodyEn').value = s.announcementBodyEn || '';
      $('setSupportUrl').value = s.supportUrl || '';
    } catch (_) {}
  }

  async function saveSettings() {
    $('settingsErr').textContent = '';
    $('saveSettings').disabled = true;
    try {
      await admin.set(['appSettings', 'main'], {
        communityEnabled: $('setCommunityEnabled').checked,
        aiEducationEnabled: $('setAiEducationEnabled').checked,
        announcementActive: $('setAnnouncementActive').checked,
        announcementTitleAr: $('setAnnouncementTitleAr').value.trim(),
        announcementTitleEn: $('setAnnouncementTitleEn').value.trim(),
        announcementBodyAr: $('setAnnouncementBodyAr').value.trim(),
        announcementBodyEn: $('setAnnouncementBodyEn').value.trim(),
        supportUrl: $('setSupportUrl').value.trim(),
        updatedAt: admin.SERVER_TS,
      }, true);
      if (logAdminActivity) await logAdminActivity('settings_save', 'main');
      alert('تم حفظ الإعدادات');
    } catch (e) {
      $('settingsErr').textContent = e.message;
    } finally {
      $('saveSettings').disabled = false;
    }
  }

  // ---------------- communities ----------------
  $('refreshCommunities').onclick = loadCommunities;
  $('importCommunities').onclick = importCommunities;
  $('communityModalClose').onclick = closeCommunityModal;
  $('cancelCommunity').onclick = closeCommunityModal;
  $('saveCommunity').onclick = saveCommunity;
  $('communityModal').onclick = (e) => { if (e.target === $('communityModal')) closeCommunityModal(); };
  loadCommunities();

  async function loadCommunities() {
    const box = $('communitiesList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const res = await fetch('default-communities.json');
      const defaults = res.ok ? await res.json() : [];
      const snap = await admin.query({ collectionPath: ['communityCatalog'] });
      const overrides = Object.fromEntries(snap.docs.map((d) => [d.id, d.data()]));

      if (!defaults.length) {
        box.innerHTML = '<div class="empty">تعذر تحميل القائمة الافتراضية</div>';
        return;
      }

      box.innerHTML = defaults.map((c) => {
        const o = overrides[c.id] || {};
        const enabled = o.enabled !== false;
        const name = o.nameAr || c.nameAr;
        return `<div style="padding:10px 0;border-bottom:1px solid #F3EAEF">
          <span class="pill ${enabled ? 'live' : 'draft'}">${enabled ? 'مفعّل' : 'معطّل'}</span>
          <strong>${esc(name)}</strong>
          <div class="muted">${esc(c.id)} · ${esc(String(o.maxMembers ?? c.maxMembers))} عضو</div>
          <div class="row-actions">
            <button class="btn sm" data-edit-community="${esc(c.id)}">تعديل</button>
          </div>
        </div>`;
      }).join('');

      box.querySelectorAll('[data-edit-community]').forEach((b) => {
        b.onclick = () => openCommunityModal(b.dataset.editCommunity, defaults, overrides);
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  async function openCommunityModal(id, defaults, overrides) {
    const base = defaults.find((c) => c.id === id) || {};
    const o = overrides[id] || {};
    $('communityId').value = id;
    $('communityNameAr').value = o.nameAr ?? base.nameAr ?? '';
    $('communityNameEn').value = o.nameEn ?? base.nameEn ?? '';
    $('communityDescAr').value = o.descriptionAr ?? base.descriptionAr ?? '';
    $('communityDescEn').value = o.descriptionEn ?? base.descriptionEn ?? '';
    $('communityMaxMembers').value = String(o.maxMembers ?? base.maxMembers ?? 150);
    $('communityEnabled').checked = o.enabled !== false;
    $('communityErr').textContent = '';
    show('communityModal');
  }

  function closeCommunityModal() { hide('communityModal'); }

  async function saveCommunity() {
    const id = $('communityId').value;
    $('saveCommunity').disabled = true;
    try {
      await admin.set(['communityCatalog', id], {
        nameAr: $('communityNameAr').value.trim(),
        nameEn: $('communityNameEn').value.trim(),
        descriptionAr: $('communityDescAr').value.trim(),
        descriptionEn: $('communityDescEn').value.trim(),
        maxMembers: parseInt($('communityMaxMembers').value, 10) || 150,
        enabled: $('communityEnabled').checked,
        topic: 'general',
        updatedAt: admin.SERVER_TS,
      }, true);
      closeCommunityModal();
      await loadCommunities();
      if (logAdminActivity) await logAdminActivity('community_save', id);
    } catch (e) {
      $('communityErr').textContent = e.message;
    } finally {
      $('saveCommunity').disabled = false;
    }
  }

  async function importCommunities() {
    if (!confirm('استيراد إعدادات المجتمعات الافتراضية؟')) return;
    try {
      const res = await fetch('default-communities.json');
      const items = await res.json();
      for (const c of items) {
        const { id, ...data } = c;
        await admin.set(['communityCatalog', id], {
          ...data,
          enabled: true,
          updatedAt: admin.SERVER_TS,
        }, true);
      }
      alert(`تم استيراد ${items.length} مجتمعًا`);
      await loadCommunities();
    } catch (e) {
      alert('فشل: ' + e.message);
    }
  }

  // ---------------- moderation ----------------
  $('refreshModeration').onclick = loadModeration;
  $('reprocessPending').onclick = reprocessPendingModeration;
  loadModeration();

  async function reprocessPendingModeration() {
    const btn = $('reprocessPending');
    btn.disabled = true;
    try {
      const user = auth.currentUser;
      if (!user) throw new Error('سجّلي الدخول أولاً');
      const token = await user.getIdToken();
      const res = await fetch(`${FUNCTIONS_BASE}/reprocessPendingModeration`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: '{}',
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || res.statusText);
      alert(`تمت المعالجة: ${data.postsProcessed ?? 0} منشور، ${data.commentsProcessed ?? 0} تعليق`);
      await loadModeration();
      if (loadOverview) await loadOverview();
    } catch (e) {
      alert('فشل: ' + e.message);
    } finally {
      btn.disabled = false;
    }
  }

  async function loadPendingModeration() {
    const box = $('pendingModerationList');
    if (!box) return;
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const [postsSnap, commentsSnap] = await Promise.all([
        admin.query({
          collectionGroup: 'posts',
          filters: [{ field: 'moderationStatus', op: '==', value: 'pending_review' }],
          orderBy: { field: 'createdAt', dir: 'desc' },
          limit: 20,
        }),
        admin.query({
          collectionGroup: 'comments',
          filters: [{ field: 'moderationStatus', op: '==', value: 'pending_review' }],
          orderBy: { field: 'createdAt', dir: 'desc' },
          limit: 20,
        }),
      ]);

      if (postsSnap.empty && commentsSnap.empty) {
        box.innerHTML = '<div class="empty" style="margin-bottom:8px">لا محتوى بانتظار المراجعة</div>';
        return;
      }

      const postRows = postsSnap.docs.map((d) => {
        const p = d.data();
        const communityId = p.communityId || d.id.split('|')[0];
        const postId = d.id;
        const when = p.createdAt?.toDate ? p.createdAt.toDate().toLocaleString('ar') : '';
        return { p, communityId: p.communityId, postId: d.id, when, kind: 'post' };
      });

      // collectionGroup docs don't have path in client - need path from server
      // serializeDoc only has id - for posts in collectionGroup, we need communityId from data
      const postHtml = postsSnap.docs.map((d) => {
        const p = d.data();
        const pathParts = (p.path || '').split('/');
        const communityId = p.communityId || pathParts[1];
        const postId = d.id;
        const when = p.createdAt?.toDate ? p.createdAt.toDate().toLocaleString('ar') : '';
        if (!communityId) return '';
        return `<div style="padding:12px 0;border-bottom:1px solid #F3EAEF">
          <span class="pill pending">منشور معلّق</span>
          <span class="muted">${esc(communityId)} · ${esc(when)}</span>
          <div class="muted">@${esc(p.authorAlias || '—')}</div>
          <div class="content-quote">${esc(p.text || '')}</div>
          <div class="row-actions">
            <button class="btn sm" data-approve-post="${esc(communityId)}|${esc(postId)}">موافقة</button>
            <button class="btn danger sm" data-reject-post="${esc(communityId)}|${esc(postId)}">رفض</button>
          </div>
        </div>`;
      }).join('');

      const commentHtml = commentsSnap.docs.map((d) => {
        const c = d.data();
        const pathParts = (c.path || '').split('/');
        const communityId = c.communityId || pathParts[1];
        const postId = c.postId || pathParts[3];
        const commentId = d.id;
        const when = c.createdAt?.toDate ? c.createdAt.toDate().toLocaleString('ar') : '';
        if (!communityId || !postId) return '';
        return `<div style="padding:12px 0;border-bottom:1px solid #F3EAEF">
          <span class="pill pending">تعليق معلّق</span>
          <span class="muted">${esc(communityId)} · ${esc(when)}</span>
          <div class="muted">@${esc(c.authorAlias || '—')}</div>
          <div class="content-quote">${esc(c.text || '')}</div>
          <div class="row-actions">
            <button class="btn sm" data-approve-comment="${esc(communityId)}|${esc(postId)}|${esc(commentId)}">موافقة</button>
            <button class="btn danger sm" data-reject-comment="${esc(communityId)}|${esc(postId)}|${esc(commentId)}">رفض</button>
          </div>
        </div>`;
      }).join('');

      box.innerHTML = postHtml + commentHtml;

      box.querySelectorAll('[data-approve-post]').forEach((b) => {
        b.onclick = async () => {
          const [communityId, postId] = b.dataset.approvePost.split('|');
          await admin.update(['communities', communityId, 'posts', postId], {
            moderationStatus: 'approved',
            moderationReviewedAt: admin.SERVER_TS,
            moderationReviewedBy: 'admin',
          });
          await loadModeration();
          if (logAdminActivity) await logAdminActivity('approve_post', postId);
        };
      });
      box.querySelectorAll('[data-reject-post]').forEach((b) => {
        b.onclick = async () => {
          const [communityId, postId] = b.dataset.rejectPost.split('|');
          await admin.update(['communities', communityId, 'posts', postId], {
            hidden: true,
            moderationStatus: 'rejected',
            hiddenAt: admin.SERVER_TS,
            hiddenBy: 'admin',
            moderationReviewedAt: admin.SERVER_TS,
            moderationReviewedBy: 'admin',
          });
          await loadModeration();
          if (logAdminActivity) await logAdminActivity('reject_post', postId);
        };
      });
      box.querySelectorAll('[data-approve-comment]').forEach((b) => {
        b.onclick = async () => {
          const [communityId, postId, commentId] = b.dataset.approveComment.split('|');
          await admin.update(
            ['communities', communityId, 'posts', postId, 'comments', commentId],
            {
              moderationStatus: 'approved',
              moderationReviewedAt: admin.SERVER_TS,
              moderationReviewedBy: 'admin',
            },
          );
          await loadModeration();
          if (logAdminActivity) await logAdminActivity('approve_comment', commentId);
        };
      });
      box.querySelectorAll('[data-reject-comment]').forEach((b) => {
        b.onclick = async () => {
          const [communityId, postId, commentId] = b.dataset.rejectComment.split('|');
          await admin.update(
            ['communities', communityId, 'posts', postId, 'comments', commentId],
            {
              hidden: true,
              moderationStatus: 'rejected',
              hiddenAt: admin.SERVER_TS,
              hiddenBy: 'admin',
              moderationReviewedAt: admin.SERVER_TS,
              moderationReviewedBy: 'admin',
            },
          );
          await loadModeration();
          if (logAdminActivity) await logAdminActivity('reject_comment', commentId);
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  async function loadModeration() {
    await loadPendingModeration();
    const box = $('moderationList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionGroup: 'posts',
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: 40,
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا منشورات</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const p = d.data();
        const hidden = p.hidden === true;
        const pending = p.moderationStatus === 'pending_review';
        const pathParts = (p.path || '').split('/');
        const communityId = p.communityId || pathParts[1];
        const postId = d.id;
        const when = p.createdAt?.toDate ? p.createdAt.toDate().toLocaleString('ar') : '';
        if (!communityId) return '';
        return `<div style="padding:12px 0;border-bottom:1px solid #F3EAEF">
          <span class="pill ${pending ? 'pending' : hidden ? 'draft' : 'live'}">${pending ? 'معلّق' : hidden ? 'مخفي' : 'ظاهر'}</span>
          <span class="muted">${esc(communityId)} · ${esc(when)}</span>
          <div class="muted">@${esc(p.authorAlias || '—')} (${esc(p.authorUid || '')})</div>
          <div class="content-quote">${esc(p.text || '')}</div>
          <div class="row-actions">
            <button class="btn sm" data-hide-post="${esc(communityId)}|${esc(postId)}|${hidden}">
              ${hidden ? 'إظهار' : 'إخفاء'}
            </button>
            <button class="btn danger sm" data-ban-user="${esc(p.authorUid || '')}">
              حظر الكاتبة
            </button>
          </div>
        </div>`;
      }).join('');

      box.querySelectorAll('[data-hide-post]').forEach((b) => {
        b.onclick = async () => {
          const [communityId, postId, isHidden] = b.dataset.hidePost.split('|');
          await admin.update(['communities', communityId, 'posts', postId], {
            hidden: isHidden !== 'true',
            hiddenAt: admin.SERVER_TS,
            hiddenBy: 'admin',
          });
          await loadModeration();
          if (logAdminActivity) await logAdminActivity('post_visibility', postId);
        };
      });
      box.querySelectorAll('[data-ban-user]').forEach((b) => {
        b.onclick = async () => {
          const uid = b.dataset.banUser;
          if (!uid) return;
          if (!confirm(`حظر ${uid} من المجتمع؟`)) return;
          await admin.set(['users', uid], {
            communityBanned: true,
            communityBannedAt: admin.SERVER_TS,
          }, true);
          if (logAdminActivity) await logAdminActivity('community_ban', uid);
          alert('تم الحظر');
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // ---------------- activity log ----------------
  loadActivity();

  const ACT_ICONS = {
    broadcast: '🔔',
    banner_save: '🎨',
    settings_save: '⚙️',
    community_save: '💬',
    community_ban: '🚫',
    community_unban: '✅',
    approve_post: '✅',
    reject_post: '🚫',
    approve_comment: '✅',
    reject_comment: '🚫',
    post_visibility: '👁️',
    article_save: '📚',
    article_delete: '🗑️',
  };
  const ACT_LABELS = {
    broadcast: 'إرسال إشعار جماعي',
    banner_save: 'حفظ بانر',
    settings_save: 'تحديث الإعدادات',
    community_save: 'حفظ مجتمع',
    community_ban: 'حظر مستخدمة',
    community_unban: 'إلغاء حظر مستخدمة',
    approve_post: 'الموافقة على منشور',
    reject_post: 'رفض منشور',
    approve_comment: 'الموافقة على تعليق',
    reject_comment: 'رفض تعليق',
    post_visibility: 'تغيير ظهور منشور',
    article_save: 'حفظ مقال',
    article_delete: 'حذف مقال',
  };

  function timeAgoAr(date) {
    if (!date) return '';
    const diff = Math.floor((Date.now() - date.getTime()) / 1000);
    if (diff < 60) return 'منذ ثوانٍ';
    if (diff < 3600) return `منذ ${Math.floor(diff / 60)} د`;
    if (diff < 86400) return `منذ ${Math.floor(diff / 3600)} س`;
    if (diff < 604800) return `منذ ${Math.floor(diff / 86400)} يوم`;
    return date.toLocaleDateString('ar');
  }

  async function loadActivity() {
    const box = $('activityList');
    if (!box) return;
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const actionFilter = $('activityActionFilter')?.value || '';
      const rangeDays = parseInt($('activityRange')?.value || '30', 10);
      const filters = [];
      if (actionFilter) filters.push({ field: 'action', op: '==', value: actionFilter });
      if (rangeDays > 0) {
        const since = new Date(Date.now() - rangeDays * 86400000);
        // Note: Firestore can't combine inequality with arbitrary equality cheaply
        // — we filter client-side for the date if action filter is present.
      }
      const snap = await admin.query({
        collectionPath: ['adminActivityLog'],
        filters,
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: actionFilter ? 100 : 50,
      });
      let docs = snap.docs;
      if (rangeDays > 0) {
        const cutoff = Date.now() - rangeDays * 86400000;
        docs = docs.filter((d) => {
          const t = d.data().createdAt?.toDate?.()?.getTime();
          return !t || t >= cutoff;
        });
      }
      if (!docs.length) {
        box.innerHTML = '<div class="empty">لا نشاط بهذه المعايير</div>';
        return;
      }
      // wrap as snap-like for old code path
      const filteredSnap = { docs };
      const _origSnap = snap;
      if (filteredSnap.docs.length === 0) {
        box.innerHTML = '<div class="empty">لا نشاط بهذه المعايير</div>';
        return;
      }
      // continue with docs array
      box.innerHTML = docs.map((d) => {
        const a = d.data();
        const date = a.createdAt?.toDate ? a.createdAt.toDate() : null;
        const when = date ? timeAgoAr(date) : '';
        const fullWhen = date ? date.toLocaleString('ar') : '';
        const icon = ACT_ICONS[a.action] || '📝';
        const label = ACT_LABELS[a.action] || a.action;
        return `<div class="activity-item">
          <div class="act-ico">${icon}</div>
          <div class="act-body">
            <div class="act-action">${esc(label)}</div>
            <div class="act-meta" title="${esc(fullWhen)}">
              ${esc(when)} · ${esc(a.details || '—')} · <span style="opacity:0.8">${esc(a.adminEmail || a.adminUid || '')}</span>
            </div>
          </div>
        </div>`;
      }).join('');
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // =====================================================================
  // SNAPSHOT TRIGGER + TRANSLATE OPENER (v3)
  // =====================================================================
  const runSnapshotBtn = $('runSnapshotNow');
  if (runSnapshotBtn) {
    runSnapshotBtn.onclick = async () => {
      runSnapshotBtn.disabled = true;
      $('snapshotResult').textContent = '⏳ جاري التشغيل...';
      try {
        const r = await admin.api('runSnapshotNow', {});
        $('snapshotResult').innerHTML = `✅ تم. <strong>${r.users}</strong> مستخدم · <strong>${r.premium}</strong> Premium · <strong>${r.dau}</strong> DAU · <strong>${r.posts}</strong> منشور.`;
        if (logAdminActivity) await logAdminActivity('snapshot_run', r.date);
        _loadedTabs.delete('analytics');
      } catch (e) {
        $('snapshotResult').textContent = '❌ ' + e.message;
      } finally {
        runSnapshotBtn.disabled = false;
      }
    };
  }
  const openTranslateBtn = $('openTranslate');
  if (openTranslateBtn) {
    openTranslateBtn.onclick = () => {
      $('translateSource').value = '';
      $('translateResult').value = '';
      $('translateErr').textContent = '';
      show('translateModal');
    };
  }

  // =====================================================================
  // ANALYTICS PANEL (v3)
  // =====================================================================
  let _charts = {};

  $('analyticsRange').onchange = () => { _loadedTabs.delete('analytics'); loadAnalytics(); };

  async function loadAnalytics() {
    const days = parseInt($('analyticsRange').value, 10) || 30;
    try {
      const { items } = await admin.api('analyticsHistory', { days });
      const series = (items || []).slice(-days);
      renderAnalyticsStats(series);
      renderAnalyticsCharts(series);
    } catch (e) {
      console.warn('loadAnalytics', e);
      renderAnalyticsStats([]);
      renderAnalyticsCharts([]);
    }
  }

  function renderAnalyticsStats(series) {
    if (!series.length) {
      $('anNewUsers').textContent = '—';
      $('anNewPremium').textContent = '—';
      $('anDau').textContent = '—';
      $('anConvRate').textContent = '—';
      $('anNewUsersTrend').textContent = 'لا توجد بيانات تاريخية بعد';
      $('anNewPremiumTrend').textContent = '—';
      return;
    }
    const last = series[series.length - 1];
    const totalNewUsers = series.reduce((a, b) => a + (b.newUsersToday || 0), 0);
    const totalNewPremium = series.reduce((a, b) => a + (b.newPremiumToday || 0), 0);
    $('anNewUsers').textContent = totalNewUsers.toLocaleString('en-US');
    $('anNewPremium').textContent = totalNewPremium.toLocaleString('en-US');
    $('anDau').textContent = (last.dau || 0).toLocaleString('en-US');
    const convRate = last.users > 0 ? ((last.premium / last.users) * 100).toFixed(1) + '%' : '—';
    $('anConvRate').textContent = convRate;
  }

  function destroyChart(key) {
    if (_charts[key]) { try { _charts[key].destroy(); } catch (_) {} _charts[key] = null; }
  }

  function chartGradient(ctx, height, top, bottom) {
    const grad = ctx.createLinearGradient(0, 0, 0, height);
    grad.addColorStop(0, top);
    grad.addColorStop(1, bottom);
    return grad;
  }

  function renderAnalyticsCharts(series) {
    if (typeof window.Chart === 'undefined') {
      console.warn('Chart.js not loaded yet');
      return;
    }
    const labels = series.map((s) => s.date);
    const fmtOpts = {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: true, labels: { font: { family: 'Cairo', size: 11 } } } },
      scales: {
        x: { ticks: { font: { family: 'Cairo', size: 10 } }, grid: { display: false } },
        y: { beginAtZero: true, ticks: { font: { family: 'Cairo', size: 10 }, precision: 0 } },
      },
      interaction: { mode: 'index', intersect: false },
    };

    destroyChart('users');
    const canvasU = $('chartUsers');
    if (canvasU) {
      const ctx = canvasU.getContext('2d');
      _charts.users = new Chart(ctx, {
        type: 'line',
        data: {
          labels,
          datasets: [
            {
              label: 'إجمالي المستخدمين',
              data: series.map((s) => s.users || 0),
              borderColor: '#D484A8',
              backgroundColor: chartGradient(ctx, 260, 'rgba(212,132,168,0.35)', 'rgba(212,132,168,0.02)'),
              fill: true, tension: 0.35, borderWidth: 2.5, pointRadius: 0,
            },
            {
              label: 'جدد اليوم',
              data: series.map((s) => s.newUsersToday || 0),
              borderColor: '#A48AD4', borderDash: [5, 4],
              backgroundColor: 'transparent', tension: 0.3, borderWidth: 2, pointRadius: 0,
            },
          ],
        },
        options: fmtOpts,
      });
    }

    destroyChart('premium');
    const canvasP = $('chartPremium');
    if (canvasP) {
      const ctx = canvasP.getContext('2d');
      _charts.premium = new Chart(ctx, {
        type: 'line',
        data: {
          labels,
          datasets: [{
            label: 'Premium',
            data: series.map((s) => s.premium || 0),
            borderColor: '#D89C32',
            backgroundColor: chartGradient(ctx, 240, 'rgba(216,156,50,0.30)', 'rgba(216,156,50,0.02)'),
            fill: true, tension: 0.35, borderWidth: 2.5, pointRadius: 0,
          }],
        },
        options: fmtOpts,
      });
    }

    destroyChart('activity');
    const canvasA = $('chartActivity');
    if (canvasA) {
      const ctx = canvasA.getContext('2d');
      _charts.activity = new Chart(ctx, {
        type: 'bar',
        data: {
          labels,
          datasets: [
            { label: 'المنشورات', data: series.map((s) => s.posts || 0), backgroundColor: 'rgba(232,160,191,0.7)', borderRadius: 4 },
            { label: 'DAU', data: series.map((s) => s.dau || 0), backgroundColor: 'rgba(61,155,126,0.7)', borderRadius: 4 },
          ],
        },
        options: fmtOpts,
      });
    }
  }

  // =====================================================================
  // PREMIUM PANEL (v3)
  // =====================================================================
  $('refreshPremium').onclick = () => { _loadedTabs.delete('premium'); loadPremiumPanel(); };

  async function loadPremiumPanel() {
    const box = $('pmList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['users'],
        filters: [{ field: 'isPremium', op: '==', value: true }],
        limit: 500,
      });
      const all = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const total = all.length;
      const fromPromo = all.filter((u) => u.premiumSource === 'promo').length;
      const now = Date.now();
      const expSoon = all.filter((u) => {
        const exp = u.premiumExpiry?.toDate?.()?.getTime();
        return exp && exp - now > 0 && exp - now < 7 * 86400000;
      }).length;

      $('pmActive').textContent = total.toLocaleString('en-US');
      $('pmFromPromo').textContent = fromPromo.toLocaleString('en-US');
      $('pmExpiringSoon').textContent = expSoon.toLocaleString('en-US');

      if (!all.length) {
        box.innerHTML = '<div class="empty">لا توجد اشتراكات Premium حالياً</div>';
        return;
      }
      box.innerHTML = `<div class="table-wrap"><table>
        <thead><tr><th>المستخدم</th><th>المصدر</th><th>منذ</th><th>تنتهي</th></tr></thead>
        <tbody>${
          all.map((u) => {
            const name = u.communityAlias || u.name || u.email || u.id;
            const src = u.premiumSource || 'manual';
            const srcLabel = src === 'promo' ? '🎁 كود' : src === 'google_play' ? '📱 Google Play' : '👨‍⚖️ يدوي';
            const since = u.premiumSince ? new Date(u.premiumSince).toLocaleDateString('en-US') : '—';
            const exp = u.premiumExpiry?.toDate?.();
            const expStr = exp ? exp.toLocaleDateString('en-US') : '∞';
            const expSoonClass = (exp && (exp.getTime() - Date.now()) < 7 * 86400000) ? 'minor' : 'live';
            return `<tr>
              <td><strong>${esc(name)}</strong><div class="muted" style="word-break:break-all">${esc(u.id)}</div></td>
              <td><span class="pill ${src === 'promo' ? 'pending' : 'live'}">${esc(srcLabel)}</span></td>
              <td><span class="muted">${esc(since)}</span></td>
              <td>${exp ? `<span class="pill ${expSoonClass}">${esc(expStr)}</span>` : '<span class="muted">∞</span>'}</td>
            </tr>`;
          }).join('')
        }</tbody></table></div>`;
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // =====================================================================
  // PROMO CODES PANEL (v3)
  // =====================================================================
  $('addPromoCode').onclick = openPromoModal;
  $('promoModalClose').onclick = closePromoModal;
  $('cancelPromo').onclick = closePromoModal;
  $('savePromo').onclick = createPromoCode;
  $('promoModal').onclick = (e) => { if (e.target === $('promoModal')) closePromoModal(); };

  function openPromoModal() {
    $('promoCode').value = '';
    $('promoDays').value = '30';
    $('promoMaxUses').value = '100';
    $('promoExpiresAt').value = '';
    $('promoNote').value = '';
    $('promoErr').textContent = '';
    show('promoModal');
  }
  function closePromoModal() { hide('promoModal'); }

  async function createPromoCode() {
    $('promoErr').textContent = '';
    try {
      const code = $('promoCode').value.trim().toUpperCase();
      const days = parseInt($('promoDays').value, 10);
      const maxUses = parseInt($('promoMaxUses').value, 10);
      const expiresAt = $('promoExpiresAt').value || null;
      const note = $('promoNote').value.trim();
      if (!code) throw new Error('الكود مطلوب');
      $('savePromo').disabled = true;
      await admin.api('createPromoCode', { code, days, maxUses, expiresAt, note });
      closePromoModal();
      await loadPromoCodes();
      if (logAdminActivity) await logAdminActivity('promo_create', code);
    } catch (e) {
      $('promoErr').textContent = e.message;
    } finally {
      $('savePromo').disabled = false;
    }
  }

  async function loadPromoCodes() {
    const box = $('promoList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['promoCodes'],
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: 100,
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا توجد أكواد بعد. أنشئ كوداً جديداً.</div>';
        return;
      }
      box.innerHTML = `<div class="table-wrap"><table>
        <thead><tr><th>الكود</th><th>أيام</th><th>الاستخدام</th><th>الحالة</th><th>تنتهي</th><th></th></tr></thead>
        <tbody>${
          snap.docs.map((d) => {
            const p = d.data();
            const active = p.active !== false;
            const exp = p.expiresAt?.toDate?.();
            const expStr = exp ? exp.toLocaleDateString('en-US') : '∞';
            const expired = exp && exp.getTime() < Date.now();
            const exhausted = (p.usedCount || 0) >= (p.maxUses || 0);
            const status = !active ? 'مُلغى' : expired ? 'منتهي' : exhausted ? 'مستهلَك' : 'مفعّل';
            const statusClass = !active || expired || exhausted ? 'draft' : 'live';
            return `<tr>
              <td><strong style="font-family:'Inter',monospace;letter-spacing:0.06em">${esc(p.code)}</strong>${p.note ? `<div class="muted">${esc(p.note)}</div>` : ''}</td>
              <td><strong>${p.days || 0}</strong> <span class="muted">يوم</span></td>
              <td><strong>${p.usedCount || 0}</strong> / ${p.maxUses || 0}</td>
              <td><span class="pill ${statusClass}">${status}</span></td>
              <td><span class="muted">${esc(expStr)}</span></td>
              <td>${active && !expired && !exhausted ? `<button class="btn danger sm" data-revoke-promo="${esc(p.code)}">إلغاء</button>` : ''}</td>
            </tr>`;
          }).join('')
        }</tbody></table></div>`;
      box.querySelectorAll('[data-revoke-promo]').forEach((b) => {
        b.onclick = async () => {
          if (!confirm(`إلغاء الكود ${b.dataset.revokePromo}؟`)) return;
          try {
            await admin.api('revokePromoCode', { code: b.dataset.revokePromo });
            if (logAdminActivity) await logAdminActivity('promo_revoke', b.dataset.revokePromo);
            await loadPromoCodes();
          } catch (e) { alert(e.message); }
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // =====================================================================
  // AI USAGE PANEL (v3)
  // =====================================================================
  $('refreshAi').onclick = () => { _loadedTabs.delete('ai'); loadAiStats(); };
  $('aiRange').onchange = () => { _loadedTabs.delete('ai'); loadAiStats(); };

  // gemini-flash pricing approx — adjust as needed
  // assume ~150 tokens output per request average + 300 input → ~0.0001 USD per request
  const COST_PER_REQUEST_USD = 0.0001;

  async function loadAiStats() {
    const days = parseInt($('aiRange').value, 10) || 7;
    try {
      const data = await admin.api('aiUsageStats', { days });
      const total = data.total || 0;
      $('aiTotal').textContent = total.toLocaleString('en-US');
      $('aiCost').textContent = '$' + (total * COST_PER_REQUEST_USD).toFixed(2);
      $('aiAvg').textContent = (total / Math.max(days, 1)).toFixed(0);

      renderAiCharts(data);
      renderTopAiUsers(data.topUsers || []);
    } catch (e) {
      ['aiTotal', 'aiCost', 'aiAvg'].forEach((id) => { const el = $(id); if (el) el.textContent = '—'; });
      $('aiTopUsers').innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  function renderAiCharts(data) {
    if (typeof window.Chart === 'undefined') return;
    const byDay = data.byDay || {};
    const labels = Object.keys(byDay).sort();
    const values = labels.map((l) => byDay[l]);

    destroyChart('ai');
    const canvas = $('chartAi');
    if (canvas) {
      const ctx = canvas.getContext('2d');
      _charts.ai = new Chart(ctx, {
        type: 'bar',
        data: {
          labels,
          datasets: [{
            label: 'طلبات Gemini',
            data: values,
            backgroundColor: 'rgba(107,191,174,0.7)',
            borderRadius: 4,
          }],
        },
        options: {
          responsive: true, maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: {
            x: { ticks: { font: { family: 'Cairo', size: 10 } }, grid: { display: false } },
            y: { beginAtZero: true, ticks: { precision: 0 } },
          },
        },
      });
    }

    destroyChart('aiMode');
    const canvasM = $('chartAiMode');
    if (canvasM && data.byMode) {
      const ctx = canvasM.getContext('2d');
      const modes = Object.keys(data.byMode);
      _charts.aiMode = new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: modes.map((m) => ({ chat: '💬 دردشة', analyze: '🧠 تحليل', mood: '😊 مزاج', doctor: '🩺 طبيبة' }[m] || m)),
          datasets: [{
            data: modes.map((m) => data.byMode[m]),
            backgroundColor: ['#E8A0BF', '#A48AD4', '#FFB4A2', '#6BBFAE', '#F1C56A', '#D484A8'],
            borderColor: '#fff', borderWidth: 2,
          }],
        },
        options: {
          responsive: true, maintainAspectRatio: false,
          plugins: { legend: { position: 'bottom', labels: { font: { family: 'Cairo', size: 12 }, padding: 12 } } },
        },
      });
    }
  }

  function renderTopAiUsers(users) {
    const box = $('aiTopUsers');
    if (!users.length) { box.innerHTML = '<div class="empty">لا بيانات استخدام بعد</div>'; return; }
    box.innerHTML = `<div class="table-wrap"><table>
      <thead><tr><th>المستخدم (UID)</th><th>عدد الطلبات</th></tr></thead>
      <tbody>${
        users.map((u) => `<tr>
          <td style="font-family:monospace;font-size:12px;word-break:break-all">${esc(u.uid)}</td>
          <td><strong>${(u.count || 0).toLocaleString('en-US')}</strong></td>
        </tr>`).join('')
      }</tbody></table></div>`;
  }

  // =====================================================================
  // FEEDBACK PANEL (v3)
  // =====================================================================
  $('refreshFeedback').onclick = () => { _loadedTabs.delete('feedback'); loadFeedback(); };
  $('feedbackStatus').onchange = loadFeedback;
  $('feedbackType').onchange = loadFeedback;
  $('feedbackModalClose').onclick = closeFeedbackModal;
  $('cancelFeedback').onclick = closeFeedbackModal;
  $('feedbackModal').onclick = (e) => { if (e.target === $('feedbackModal')) closeFeedbackModal(); };
  $('sendFeedbackReply').onclick = sendFeedbackReply;
  $('closeFeedbackTicket').onclick = closeFeedbackTicket;

  let _currentFeedback = null;

  async function loadFeedback() {
    const box = $('feedbackList');
    box.innerHTML = '<div class="spinner"></div>';
    const status = $('feedbackStatus').value;
    const type = $('feedbackType').value;
    const filters = [];
    if (status !== 'all') filters.push({ field: 'status', op: '==', value: status });
    if (type) filters.push({ field: 'type', op: '==', value: type });
    try {
      const snap = await admin.query({
        collectionPath: ['feedback'],
        filters,
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: 100,
      });
      // update badge for "new" only
      const newCount = await admin.count({
        collectionPath: ['feedback'],
        filters: [{ field: 'status', op: '==', value: 'new' }],
      }).catch(() => 0);
      const badge = document.getElementById('tabBadgeFeedback');
      if (badge) {
        if (newCount > 0) {
          badge.textContent = newCount > 99 ? '99+' : String(newCount);
          badge.classList.remove('hidden');
        } else {
          badge.classList.add('hidden');
        }
      }

      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا توجد ملاحظات بهذا الفلتر</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const fb = d.data();
        const when = fb.createdAt?.toDate ? fb.createdAt.toDate().toLocaleString('ar') : '';
        const typeIcons = { bug: '🐞', idea: '💡', help: '❓', other: '📝' };
        const statusPills = { new: 'pending', replied: 'live', closed: 'dismissed' };
        const statusLabels = { new: 'جديد', replied: 'تم الرد', closed: 'مغلقة' };
        return `<div class="list-row">
          <div class="top">
            <span class="pill ${statusPills[fb.status] || 'pending'}">${statusLabels[fb.status] || fb.status}</span>
            <strong>${typeIcons[fb.type] || '📝'} ${esc(fb.type || 'other')}</strong>
            <span class="muted">${esc(when)} · ${esc(fb.email || fb.uid || '—')} · ${esc(fb.appVersion || '')} ${esc(fb.platform || '')}</span>
          </div>
          <div class="content-quote">${esc(fb.message)}</div>
          ${fb.reply ? `<div class="content-quote" style="border-color:var(--ok);background:rgba(61,155,126,0.08)"><strong style="color:var(--ok)">↩️ ردك:</strong> ${esc(fb.reply)}</div>` : ''}
          <div class="row-actions">
            <button class="btn sm" data-reply="${d.id}">${fb.reply ? 'تعديل الرد' : 'الرد'}</button>
          </div>
        </div>`;
      }).join('');
      box.querySelectorAll('[data-reply]').forEach((b) => {
        b.onclick = () => openFeedbackReply(b.dataset.reply, snap.docs.find((d) => d.id === b.dataset.reply));
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  function openFeedbackReply(id, doc) {
    if (!doc) return;
    _currentFeedback = { id, data: doc.data() };
    const fb = doc.data();
    $('feedbackMeta').innerHTML = `
      <div class="field"><div class="field-label">من</div><div class="field-value">${esc(fb.email || fb.uid || '—')}</div></div>
      <div class="field"><div class="field-label">الرسالة الأصلية</div><div class="content-quote">${esc(fb.message)}</div></div>
    `;
    $('feedbackReplyText').value = fb.reply || '';
    $('feedbackErr').textContent = '';
    show('feedbackModal');
  }
  function closeFeedbackModal() { hide('feedbackModal'); _currentFeedback = null; }

  async function sendFeedbackReply() {
    if (!_currentFeedback) return;
    $('feedbackErr').textContent = '';
    const reply = $('feedbackReplyText').value.trim();
    if (!reply) { $('feedbackErr').textContent = 'الرد فارغ'; return; }
    $('sendFeedbackReply').disabled = true;
    try {
      await admin.api('replyToFeedback', { id: _currentFeedback.id, reply });
      if (logAdminActivity) await logAdminActivity('feedback_reply', _currentFeedback.id);
      closeFeedbackModal();
      await loadFeedback();
    } catch (e) {
      $('feedbackErr').textContent = e.message;
    } finally {
      $('sendFeedbackReply').disabled = false;
    }
  }
  async function closeFeedbackTicket() {
    if (!_currentFeedback) return;
    try {
      await admin.update(['feedback', _currentFeedback.id], { status: 'closed' });
      if (logAdminActivity) await logAdminActivity('feedback_close', _currentFeedback.id);
      closeFeedbackModal();
      await loadFeedback();
    } catch (e) { $('feedbackErr').textContent = e.message; }
  }

  // =====================================================================
  // ADMINS (multi-role) PANEL (v3)
  // =====================================================================
  $('refreshAdmins').onclick = () => { _loadedTabs.delete('admins'); loadAdmins(); };
  $('addAdminBtn').onclick = addAdmin;

  async function loadAdmins() {
    const box = $('adminsList');
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({ collectionPath: ['admins'], limit: 50 });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا مسؤولون مسجّلون بعد</div>';
        return;
      }
      box.innerHTML = `<div class="table-wrap"><table>
        <thead><tr><th>المسؤول</th><th>الدور</th><th>منذ</th><th></th></tr></thead>
        <tbody>${
          snap.docs.map((d) => {
            const a = d.data();
            const role = a.role || 'admin';
            const since = a.createdAt?.toDate?.()?.toLocaleDateString('en-US')
              || a.updatedAt?.toDate?.()?.toLocaleDateString('en-US') || '—';
            const roleClass = role === 'owner' ? 'premium' : role === 'admin' ? 'live' : 'free';
            const roleLabel = role === 'owner' ? '👑 Owner' : role === 'admin' ? '🛡️ Admin' : '👁️ Moderator';
            return `<tr>
              <td>
                <strong>${esc(a.email || d.id)}</strong>
                <div class="muted" style="font-family:monospace;word-break:break-all">${esc(d.id)}</div>
              </td>
              <td><span class="pill ${roleClass}">${roleLabel}</span></td>
              <td><span class="muted">${esc(since)}</span></td>
              <td>
                <button class="btn ghost sm" data-change-role="${esc(d.id)}" data-current-role="${esc(role)}">تغيير الدور</button>
                <button class="btn danger sm" data-remove-admin="${esc(d.id)}">إزالة</button>
              </td>
            </tr>`;
          }).join('')
        }</tbody></table></div>`;
      box.querySelectorAll('[data-change-role]').forEach((b) => {
        b.onclick = async () => {
          const uid = b.dataset.changeRole;
          const cur = b.dataset.currentRole;
          const role = prompt('الدور الجديد: owner أو admin أو moderator', cur);
          if (!role) return;
          if (!['owner', 'admin', 'moderator'].includes(role)) { alert('دور غير صالح'); return; }
          try {
            await admin.api('setAdminRole', { uid, role });
            if (logAdminActivity) await logAdminActivity('admin_role_change', `${uid} → ${role}`);
            await loadAdmins();
          } catch (e) { alert(e.message); }
        };
      });
      box.querySelectorAll('[data-remove-admin]').forEach((b) => {
        b.onclick = async () => {
          const uid = b.dataset.removeAdmin;
          if (!confirm(`إزالة المسؤول ${uid}؟ سيفقد صلاحياته فوراً.`)) return;
          try {
            await admin.api('removeAdmin', { uid });
            if (logAdminActivity) await logAdminActivity('admin_remove', uid);
            await loadAdmins();
          } catch (e) { alert(e.message); }
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  async function addAdmin() {
    $('addAdminErr').textContent = '';
    const uid = $('newAdminUid').value.trim();
    const role = $('newAdminRole').value;
    if (!uid) { $('addAdminErr').textContent = 'UID مطلوب'; return; }
    $('addAdminBtn').disabled = true;
    try {
      await admin.api('setAdminRole', { uid, role });
      if (logAdminActivity) await logAdminActivity('admin_add', `${uid} (${role})`);
      $('newAdminUid').value = '';
      await loadAdmins();
    } catch (e) {
      $('addAdminErr').textContent = e.message;
    } finally {
      $('addAdminBtn').disabled = false;
    }
  }

  // =====================================================================
  // SCHEDULED BROADCASTS + SEGMENTS (v3)
  // =====================================================================
  $('previewSegment').onclick = previewSegment;
  $('scheduleBroadcast').onclick = scheduleNewBroadcast;

  async function previewSegment() {
    const audience = $('broadcastAudience').value;
    const segment = $('broadcastSegment').value;
    $('segmentPreview').textContent = '⏳ احتساب...';
    try {
      const { count } = await admin.api('segmentPreview', { segment: segment || audience });
      $('segmentPreview').innerHTML = `📊 المستلمون المحتملون: <strong style="color:var(--rose-deep)">${count.toLocaleString('en-US')}</strong> مستخدم`;
    } catch (e) {
      $('segmentPreview').textContent = '❌ ' + e.message;
    }
  }

  async function scheduleNewBroadcast() {
    $('broadcastErr').textContent = '';
    const title = $('broadcastTitle').value.trim();
    const body = $('broadcastBody').value.trim();
    const scheduledFor = $('broadcastSchedule').value;
    if (!title || !body) { $('broadcastErr').textContent = 'العنوان والنص مطلوبان'; return; }
    if (!scheduledFor) { $('broadcastErr').textContent = 'وقت الإرسال مطلوب للجدولة'; return; }
    const date = new Date(scheduledFor);
    if (date.getTime() < Date.now() - 60000) { $('broadcastErr').textContent = 'الوقت في الماضي'; return; }
    if (!confirm(`جدولة الإشعار للإرسال في:\n${date.toLocaleString('ar')}؟`)) return;
    $('scheduleBroadcast').disabled = true;
    try {
      await admin.api('scheduleBroadcast', {
        title, body,
        audience: $('broadcastAudience').value,
        segment: $('broadcastSegment').value || null,
        scheduledFor: date.toISOString(),
      });
      alert('✅ تم جدولة الإشعار');
      $('broadcastTitle').value = '';
      $('broadcastBody').value = '';
      $('broadcastSchedule').value = '';
      const npT = document.getElementById('npTitle'); if (npT) npT.textContent = 'عنوان الإشعار سيظهر هنا';
      const npX = document.getElementById('npText'); if (npX) npX.textContent = 'نص الإشعار سيظهر بهذا الشكل عند المستخدمات.';
      if (logAdminActivity) await logAdminActivity('schedule_broadcast', title);
      await loadScheduled();
    } catch (e) {
      $('broadcastErr').textContent = e.message;
    } finally {
      $('scheduleBroadcast').disabled = false;
    }
  }

  async function loadScheduled() {
    const box = $('scheduledList');
    if (!box) return;
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['scheduledBroadcasts'],
        filters: [{ field: 'sent', op: '==', value: false }],
        orderBy: { field: 'scheduledFor', dir: 'asc' },
        limit: 20,
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا إشعارات مجدولة حالياً</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const s = d.data();
        const when = s.scheduledFor?.toDate?.()?.toLocaleString('ar') || '—';
        return `<div class="list-row">
          <div class="top">
            <span class="pill pending">⏰ مجدول</span>
            <strong>${esc(s.title)}</strong>
            <span class="muted">${esc(when)} · ${esc(s.audience || 'all')}</span>
          </div>
          <div class="content-quote">${esc(s.body)}</div>
          <div class="row-actions">
            <button class="btn danger sm" data-cancel-scheduled="${d.id}">إلغاء</button>
          </div>
        </div>`;
      }).join('');
      box.querySelectorAll('[data-cancel-scheduled]').forEach((b) => {
        b.onclick = async () => {
          if (!confirm('إلغاء هذا الإشعار المجدول؟')) return;
          try {
            await admin.api('cancelScheduledBroadcast', { id: b.dataset.cancelScheduled });
            if (logAdminActivity) await logAdminActivity('cancel_scheduled', b.dataset.cancelScheduled);
            await loadScheduled();
          } catch (e) { alert(e.message); }
        };
      });
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  // =====================================================================
  // TRANSLATE HELPER (used by other tabs)
  // =====================================================================
  $('translateModalClose').onclick = () => hide('translateModal');
  $('cancelTranslate').onclick = () => hide('translateModal');
  $('translateModal').onclick = (e) => { if (e.target === $('translateModal')) hide('translateModal'); };
  $('runTranslate').onclick = async () => {
    $('translateErr').textContent = '';
    const text = $('translateSource').value.trim();
    const target = $('translateTarget').value;
    if (!text) { $('translateErr').textContent = 'النص فارغ'; return; }
    $('runTranslate').disabled = true;
    $('translateResult').value = '⏳ Gemini يترجم...';
    try {
      const { translated } = await admin.api('translateText', { text, target });
      $('translateResult').value = translated;
    } catch (e) {
      $('translateErr').textContent = e.message;
      $('translateResult').value = '';
    } finally {
      $('runTranslate').disabled = false;
    }
  };
  $('copyTranslate').onclick = async () => {
    const t = $('translateResult').value;
    if (!t) return;
    try { await navigator.clipboard.writeText(t); $('copyTranslate').textContent = '✅ تم النسخ'; setTimeout(() => $('copyTranslate').textContent = '📋 نسخ', 1500); } catch (_) {}
  };

  // =====================================================================
  // ACTIVITY LOG SEARCH (v3)
  // =====================================================================
  if ($('activitySearch')) $('activitySearch').oninput = filterActivityLog;
  if ($('activityActionFilter')) $('activityActionFilter').onchange = loadActivity;
  if ($('activityRange')) $('activityRange').onchange = loadActivity;

  function filterActivityLog() {
    const term = $('activitySearch').value.trim().toLowerCase();
    document.querySelectorAll('#activityList .activity-item').forEach((row) => {
      const txt = row.textContent.toLowerCase();
      row.style.display = (!term || txt.includes(term)) ? '' : 'none';
    });
  }

  return {
    loadBroadcasts,
    loadBanners,
    loadSettings,
    loadCommunities,
    loadModeration,
    loadActivity,
    loadAnalytics,
    loadPremiumPanel,
    loadPromoCodes,
    loadAiStats,
    loadFeedback,
    loadAdmins,
    loadScheduled,
  };
}
