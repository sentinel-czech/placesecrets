export const LANG_CODES = ['en', 'cs', 'sk', 'de', 'es', 'fr', 'pt', 'ru', 'vi', 'zh', 'ko'] as const
export type LangCode = (typeof LANG_CODES)[number]

export const LANG_LABELS: Record<string, string> = {
  en: 'English',
  cs: 'Czech',
  sk: 'Slovak',
  de: 'German',
  es: 'Spanish',
  fr: 'French',
  pt: 'Portuguese',
  ru: 'Russian',
  vi: 'Vietnamese',
  zh: 'Chinese',
  ko: 'Korean',
}
