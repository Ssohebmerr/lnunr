(() => {
  'use strict';

  const byId = (id) => document.getElementById(id);
  const palette = byId('commandPalette');
  const commandSearch = byId('commandSearch');
  const commandButtons = Array.from(document.querySelectorAll('[data-command-tab]'));
  let selectedCommand = 0;

  function isTypingTarget(target) {
    return target instanceof HTMLInputElement
      || target instanceof HTMLTextAreaElement
      || target instanceof HTMLSelectElement
      || target?.isContentEditable;
  }

  function visibleCommands() {
    return commandButtons.filter((button) => !button.hidden);
  }

  function paintSelection() {
    commandButtons.forEach((button) => button.classList.remove('is-selected'));
    const visible = visibleCommands();
    if (!visible.length) return;
    selectedCommand = Math.max(0, Math.min(selectedCommand, visible.length - 1));
    visible[selectedCommand].classList.add('is-selected');
  }

  function openPalette() {
    if (!palette || byId('dashView')?.classList.contains('hidden')) return;
    palette.classList.remove('hidden');
    commandSearch.value = '';
    commandButtons.forEach((button) => { button.hidden = false; });
    selectedCommand = 0;
    paintSelection();
    requestAnimationFrame(() => commandSearch.focus());
  }

  function closePalette() {
    palette?.classList.add('hidden');
  }

  function openTab(name) {
    const trigger = document.querySelector(`.tab[data-tab="${CSS.escape(name)}"]`);
    if (trigger) trigger.click();
    closePalette();
  }

  byId('adminSearchTrigger')?.addEventListener('click', openPalette);
  byId('commandClose')?.addEventListener('click', closePalette);
  palette?.addEventListener('click', (event) => {
    if (event.target === palette) closePalette();
  });

  commandButtons.forEach((button) => {
    button.addEventListener('click', () => openTab(button.dataset.commandTab));
  });

  commandSearch?.addEventListener('input', () => {
    const query = commandSearch.value.trim().toLocaleLowerCase('ar');
    commandButtons.forEach((button) => {
      button.hidden = query.length > 0
        && !button.textContent.toLocaleLowerCase('ar').includes(query);
    });
    selectedCommand = 0;
    paintSelection();
  });

  commandSearch?.addEventListener('keydown', (event) => {
    const visible = visibleCommands();
    if (!visible.length) return;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      selectedCommand = (selectedCommand + 1) % visible.length;
      paintSelection();
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      selectedCommand = (selectedCommand - 1 + visible.length) % visible.length;
      paintSelection();
    } else if (event.key === 'Enter') {
      event.preventDefault();
      visible[selectedCommand]?.click();
    }
  });

  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      palette?.classList.contains('hidden') ? openPalette() : closePalette();
      return;
    }
    if (event.key === 'Escape' && !palette?.classList.contains('hidden')) {
      closePalette();
      return;
    }
    if (event.key === '/' && !isTypingTarget(event.target) && !event.ctrlKey && !event.metaKey) {
      event.preventDefault();
      openPalette();
    }
  });

  function safeStorageGet(key) {
    try { return localStorage.getItem(key); } catch (_) { return null; }
  }

  function safeStorageSet(key, value) {
    try { localStorage.setItem(key, value); } catch (_) {}
  }

  function applyTheme(theme) {
    document.body.classList.toggle('admin-dark', theme === 'dark');
    byId('themeToggle')?.setAttribute(
      'aria-label',
      theme === 'dark' ? 'استخدام المظهر الفاتح' : 'استخدام المظهر الداكن',
    );
  }

  const savedTheme = safeStorageGet('lune_admin_theme') || 'light';
  applyTheme(savedTheme);
  byId('themeToggle')?.addEventListener('click', () => {
    const next = document.body.classList.contains('admin-dark') ? 'light' : 'dark';
    applyTheme(next);
    safeStorageSet('lune_admin_theme', next);
  });

  const refreshIds = {
    articles: 'refreshArticles',
    reports: 'refreshReports',
    users: 'refreshUsers',
    communities: 'refreshCommunities',
    moderation: 'refreshModeration',
    premium: 'refreshPremium',
    ai: 'refreshAi',
    feedback: 'refreshFeedback',
    admins: 'refreshAdmins',
  };

  byId('globalRefresh')?.addEventListener('click', async () => {
    const button = byId('globalRefresh');
    const activeTab = document.querySelector('.tab.active')?.dataset.tab || 'overview';
    button.classList.add('is-loading');
    button.disabled = true;
    try {
      if (activeTab === 'overview' && window.LuneAdminBridge?.refreshOverview) {
        await window.LuneAdminBridge.refreshOverview();
      } else {
        byId(refreshIds[activeTab])?.click();
      }
      byId('lastDashboardRefresh').textContent = 'الآن';
    } finally {
      setTimeout(() => {
        button.classList.remove('is-loading');
        button.disabled = false;
      }, 350);
    }
  });

  function parseVisibleNumber(id) {
    const raw = byId(id)?.textContent?.trim().toLowerCase() || '';
    const value = Number.parseFloat(raw.replace(/,/g, ''));
    if (!Number.isFinite(value)) return null;
    if (raw.endsWith('m')) return value * 1_000_000;
    if (raw.endsWith('k')) return value * 1_000;
    return value;
  }

  function updateOverviewInsights() {
    const users = parseVisibleNumber('statUsers');
    const premium = parseVisibleNumber('statPremium');
    const pending = parseVisibleNumber('statPending');
    if (users != null && premium != null && users > 0) {
      byId('premiumConversion').textContent = `${((premium / users) * 100).toFixed(1)}%`;
    }
    if (pending != null) byId('focusReports').textContent = String(Math.round(pending));
  }

  document.addEventListener('lune:stats-updated', updateOverviewInsights);

  function updateConnectionStatus() {
    const status = byId('connectionStatus');
    if (!status) return;
    status.classList.toggle('is-offline', !navigator.onLine);
    status.lastChild.textContent = navigator.onLine ? ' متصلة' : ' بدون اتصال';
  }

  window.addEventListener('online', updateConnectionStatus);
  window.addEventListener('offline', updateConnectionStatus);
  updateConnectionStatus();

  const date = new Intl.DateTimeFormat('ar', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  }).format(new Date());
  if (byId('overviewDate')) byId('overviewDate').textContent = date;
})();
