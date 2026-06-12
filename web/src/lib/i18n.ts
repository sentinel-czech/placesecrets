import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import en from '@/locales/en/translation.json'
import cs from '@/locales/cs/translation.json'
import sk from '@/locales/sk/translation.json'
import de from '@/locales/de/translation.json'
import es from '@/locales/es/translation.json'
import fr from '@/locales/fr/translation.json'
import pt from '@/locales/pt/translation.json'
import ru from '@/locales/ru/translation.json'
import vi from '@/locales/vi/translation.json'
import zh from '@/locales/zh/translation.json'
import ko from '@/locales/ko/translation.json'

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      cs: { translation: cs },
      sk: { translation: sk },
      de: { translation: de },
      es: { translation: es },
      fr: { translation: fr },
      pt: { translation: pt },
      ru: { translation: ru },
      vi: { translation: vi },
      zh: { translation: zh },
      ko: { translation: ko },
    },
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
    detection: {
      order: ['localStorage', 'navigator'],
      lookupLocalStorage: 'i18nextLng',
      caches: ['localStorage'],
    },
  })

export default i18n
