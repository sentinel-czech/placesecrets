import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        // Split heavy vendor libraries out of the main bundle so the initial
        // admin/app payload is smaller and they can be cached independently.
        manualChunks(id: string) {
          if (!id.includes('node_modules')) return
          if (/leaflet|react-leaflet/.test(id)) return 'maps'
          if (/recharts|d3-|victory-vendor/.test(id)) return 'charts'
          if (/jspdf|jszip|html2canvas/.test(id)) return 'pdf'
          if (/i18next/.test(id)) return 'i18n'
          if (/@supabase/.test(id)) return 'supabase'
          if (/@tanstack/.test(id)) return 'table'
          if (/[\\/]node_modules[\\/](react|react-dom|react-router|react-router-dom|scheduler)[\\/]/.test(id)) return 'react'
          return 'vendor'
        },
      },
    },
  },
  server: {
    hmr: {
      overlay: process.env.VITE_DISABLE_ERROR_OVERLAY !== 'true',
    },
  },
})
