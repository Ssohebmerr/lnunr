const FUNCTIONS_BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';

export function createAdminClient(auth, { getAppCheckHeaders } = {}) {
  async function api(action, payload = {}) {
    const user = auth.currentUser;
    if (!user) throw new Error('سجّلي الدخول أولاً');
    const token = await user.getIdToken(true);
    const appCheckHeaders = getAppCheckHeaders
      ? await getAppCheckHeaders()
      : {};
    const res = await fetch(`${FUNCTIONS_BASE}/adminApi`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...appCheckHeaders,
      },
      body: JSON.stringify({ action, payload }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || `فشل الطلب (${res.status})`);
    return data;
  }

  function revive(val) {
    if (val && typeof val === 'object' && val.__type === 'timestamp') {
      const d = new Date(val.iso);
      return { toDate: () => d };
    }
    if (Array.isArray(val)) return val.map(revive);
    if (val && typeof val === 'object' && val.constructor === Object) {
      const out = {};
      for (const [k, v] of Object.entries(val)) out[k] = revive(v);
      return out;
    }
    return val;
  }

  function wrapDocs(items) {
    return (items || []).map((item) => {
      const { id, ...fields } = item;
      const data = revive(fields);
      return {
        id,
        data: () => data,
        exists: true,
      };
    });
  }

  const SERVER_TS = { __serverTimestamp: true };

  return {
    api,
    SERVER_TS,
    async query(opts) {
      const { items } = await api('query', opts);
      const docs = wrapDocs(items);
      return { docs, empty: docs.length === 0 };
    },
    async get(path) {
      const { item, exists } = await api('get', { path });
      if (!exists) return { exists: () => false, data: () => undefined };
      const { id, ...fields } = item;
      const data = revive(fields);
      return {
        exists: () => true,
        id,
        data: () => data,
      };
    },
    async set(path, data, merge = false) {
      return api('set', { path, data, merge });
    },
    async update(path, data) {
      return api('update', { path, data });
    },
    async delete(path) {
      return api('delete', { path });
    },
    async add(collectionPath, data) {
      const { id } = await api('add', { collectionPath, data });
      return id;
    },
    async count(opts) {
      const { count } = await api('count', opts);
      return count;
    },
    async overview() {
      return api('overview');
    },
    async ensureAdmin() {
      return api('ensureAdmin');
    },
    async checkAdmin() {
      return api('checkAdmin');
    },
  };
}
