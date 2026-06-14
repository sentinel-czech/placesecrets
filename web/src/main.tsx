import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { HelmetProvider } from 'react-helmet-async'
import './index.css'
import './lib/i18n'
import App from './App.tsx'
import { ErrorBoundary } from './components/shared/ErrorBoundary.tsx'
import { initMonitoring } from './lib/monitoring'

// Optional error tracking (no-op unless VITE_SENTRY_DSN is set).
void initMonitoring()

// Fail fast with a clear message if the production build was made without the
// required Supabase configuration, instead of a cryptic blank page later.
const root = createRoot(document.getElementById('root')!)
if (!import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY) {
  root.render(
    <div style={{ padding: 24, fontFamily: 'system-ui, sans-serif', maxWidth: 640, margin: '40px auto' }}>
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>Configuration error</h1>
      <p style={{ color: '#555' }}>
        Missing <code>VITE_SUPABASE_URL</code> / <code>VITE_SUPABASE_ANON_KEY</code>. Set them in the
        hosting platform's environment variables and rebuild. See <code>web/.env.production.example</code>.
      </p>
    </div>,
  )
  throw new Error('Missing Supabase configuration (VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY)')
}

root.render(
  <StrictMode>
    <HelmetProvider>
      <ErrorBoundary>
        <App />
      </ErrorBoundary>
    </HelmetProvider>
  </StrictMode>,
)
