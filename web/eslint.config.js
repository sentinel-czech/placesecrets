import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    rules: {
      // Allow intentionally-unused identifiers prefixed with `_`.
      '@typescript-eslint/no-unused-vars': ['error', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
        caughtErrorsIgnorePattern: '^_',
      }],
      // One-shot data-fetching effects legitimately call setState on resolve; the
      // cascading-render concern of this rule does not apply to that pattern, which
      // is used consistently across the app. Keep visible as a warning.
      'react-hooks/set-state-in-effect': 'warn',
      // False positive against zustand stores (useAuthStore selector usage).
      'react-hooks/incompatible-library': 'off',
      // HMR-only hint; shadcn/ui files intentionally co-export variant helpers
      // alongside their component. Keep as a warning rather than a hard error.
      'react-refresh/only-export-components': 'warn',
    },
  },
])
