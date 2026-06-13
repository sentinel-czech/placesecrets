import { useTranslation } from 'react-i18next'

const LANGS = [
  { code: 'en', flag: '🇬🇧' },
  { code: 'cs', flag: '🇨🇿' },
  { code: 'sk', flag: '🇸🇰' },
  { code: 'de', flag: '🇩🇪' },
  { code: 'es', flag: '🇪🇸' },
  { code: 'fr', flag: '🇫🇷' },
  { code: 'pt', flag: '🇵🇹' },
  { code: 'ru', flag: '🇷🇺' },
  { code: 'vi', flag: '🇻🇳' },
  { code: 'zh', flag: '🇨🇳' },
  { code: 'ko', flag: '🇰🇷' },
]

/** Public language switcher — changes i18n language (persisted to localStorage). */
export function LanguageSwitcher({ className }: { className?: string }) {
  const { i18n } = useTranslation()
  const current = i18n.language?.substring(0, 2) || 'en'
  return (
    <select
      value={current}
      onChange={e => i18n.changeLanguage(e.target.value)}
      aria-label="Language"
      className={className ?? 'rounded-md border border-current/20 bg-transparent px-2 py-1 text-sm outline-none'}
    >
      {LANGS.map(l => (
        <option key={l.code} value={l.code} className="text-foreground">
          {l.flag} {l.code.toUpperCase()}
        </option>
      ))}
    </select>
  )
}
