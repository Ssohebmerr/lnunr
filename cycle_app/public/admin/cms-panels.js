const FUNCTIONS_BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';

export function initExtraAdmin(ctx) {
  const {
    auth, admin, $, esc, show, hide,
    loadOverview, logAdminActivity,
  } = ctx;

  const TAB_NAMES = [
    'overview', 'articles', 'notifications', 'banners', 'settings',
    'communities', 'moderation', 'reports', 'users', 'activity',
  ];

  document.querySelectorAll('.tab').forEach((t) => {
    t.onclick = () => {
      document.querySelectorAll('.tab').forEach((x) => x.classList.remove('active'));
      t.classList.add('active');
      TAB_NAMES.forEach((name) => {
        $(`tab-${name}`).classList.toggle('hidden', name !== t.dataset.tab);
      });
    };
  });

  // ---------------- broadcasts ----------------
  $('sendBroadcast').onclick = sendBroadcast;
  loadBroadcasts();

  async function sendBroadcast() {
    $('broadcastErr').textContent = '';
    const title = $('broadcastTitle').value.trim();
    const body = $('broadcastBody').value.trim();
    if (!title || !body) {
      $('broadcastErr').textContent = 'العنوان والنص مطلوبان';
      return;
    }
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
        body: JSON.stringify({
          title,
          body,
          audience: $('broadcastAudience').value,
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'فشل الإرسال');
      alert(`تم الإرسال: ${data.sent} نجح، ${data.failed} فشل من ${data.tokensAttempted} جهاز`);
      $('broadcastTitle').value = '';
      $('broadcastBody').value = '';
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

  async function loadActivity() {
    const box = $('activityList');
    if (!box) return;
    box.innerHTML = '<div class="spinner"></div>';
    try {
      const snap = await admin.query({
        collectionPath: ['adminActivityLog'],
        orderBy: { field: 'createdAt', dir: 'desc' },
        limit: 50,
      });
      if (snap.empty) {
        box.innerHTML = '<div class="empty">لا نشاط بعد</div>';
        return;
      }
      box.innerHTML = snap.docs.map((d) => {
        const a = d.data();
        const when = a.createdAt?.toDate ? a.createdAt.toDate().toLocaleString('ar') : '';
        return `<div style="padding:8px 0;border-bottom:1px solid #F3EAEF">
          <strong>${esc(a.action)}</strong>
          <span class="muted"> · ${esc(when)}</span>
          <div class="muted">${esc(a.details || '')} — ${esc(a.adminEmail || a.adminUid || '')}</div>
        </div>`;
      }).join('');
    } catch (e) {
      box.innerHTML = `<div class="empty">${esc(e.message)}</div>`;
    }
  }

  return {
    loadBroadcasts,
    loadBanners,
    loadSettings,
    loadCommunities,
    loadModeration,
    loadActivity,
  };
}
