import {
  initializeAppCheck,
  ReCaptchaEnterpriseProvider,
  getToken,
} from 'https://www.gstatic.com/firebasejs/11.0.1/firebase-app-check.js';

/** @type {import('firebase/app-check').AppCheck | null} */
let appCheckInstance = null;

/**
 * Initializes Firebase App Check for the admin web panel.
 * Requires a reCAPTCHA Enterprise site key from Firebase Console → App Check.
 *
 * @param {import('firebase/app').FirebaseApp} app
 * @param {string} siteKey
 */
export function initAdminAppCheck(app, siteKey) {
  if (!siteKey) {
    console.warn(
      '[AppCheck] Set window.LUNE_RECAPTCHA_SITE_KEY before admin loads, '
      + 'or register the web app in Firebase Console → App Check.',
    );
    return;
  }

  appCheckInstance = initializeAppCheck(app, {
    provider: new ReCaptchaEnterpriseProvider(siteKey),
    isTokenAutoRefreshEnabled: true,
  });
}

/**
 * @returns {Promise<Record<string, string>>}
 */
export async function getAppCheckHeaders() {
  if (!appCheckInstance) return {};
  try {
    const result = await getToken(appCheckInstance, false);
    if (!result?.token) return {};
    return { 'X-Firebase-AppCheck': result.token };
  } catch (error) {
    console.warn('[AppCheck] getToken failed:', error);
    return {};
  }
}
