/**
 * Optional production error tracking (Sentry). Activated only when
 * `VITE_SENTRY_DSN` is set at build time; otherwise this is a no-op and Sentry
 * is not even loaded (dynamic import keeps it out of the main bundle).
 *
 * To enable: create a Sentry project, set `VITE_SENTRY_DSN` in the hosting
 * platform env, and rebuild.
 */
export async function initMonitoring(): Promise<void> {
  const dsn = import.meta.env.VITE_SENTRY_DSN
  if (!dsn) return
  try {
    const Sentry = await import('@sentry/react')
    Sentry.init({
      dsn,
      environment: import.meta.env.MODE,
      tracesSampleRate: 0.1,
      // Don't send PII by default.
      sendDefaultPii: false,
    })
  } catch (e) {
    // Monitoring must never break the app.
    console.warn('Sentry init skipped:', e)
  }
}
