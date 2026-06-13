import { useTranslation } from 'react-i18next'
import { LegalLayout } from './LegalLayout'

const SUPPORT_EMAIL = 'support@placesecrets.app'

export default function ContactPage() {
  const { i18n } = useTranslation()
  const cs = i18n.language?.startsWith('cs')
  return (
    <LegalLayout
      draft={false}
      title={cs ? 'Kontakt' : 'Contact'}
      intro={cs
        ? 'Máte dotaz, návrh nebo problém? Ozvěte se nám.'
        : 'Have a question, suggestion or problem? Get in touch.'}
      sections={[
        {
          heading: 'E-mail',
          body: [`${cs ? 'Podpora' : 'Support'}: ${SUPPORT_EMAIL}`],
        },
        {
          heading: cs ? 'Ochrana údajů' : 'Data protection',
          body: [cs
            ? 'Ve věcech osobních údajů viz Zásady ochrany osobních údajů.'
            : 'For personal-data matters, see the Privacy Policy.'],
        },
      ]}
    />
  )
}
