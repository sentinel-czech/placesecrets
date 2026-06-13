import { useTranslation } from 'react-i18next'
import { LegalLayout } from './LegalLayout'

export default function FaqPage() {
  const { i18n } = useTranslation()
  const cs = i18n.language?.startsWith('cs')
  return (
    <LegalLayout
      draft={false}
      title={cs ? 'Časté dotazy' : 'FAQ'}
      sections={cs ? [
        { heading: 'Jak PlaceSecrets funguje?', body: ['Najdete místo na mapě nebo vyhledáním, přehrajete si audioprůvodce a můžete místo ohodnotit.'] },
        { heading: 'Co je zdarma?', body: ['Část obsahu je volně dostupná; volné audio je dostupné v omezeném počtu za období (nastavuje provozovatel).'] },
        { heading: 'Co si mohu koupit?', body: ['Jednotlivé místo, celé město nebo celou zemi. Zakoupený přístup máte vždy dostupný ve svém účtu.'] },
        { heading: 'Jak se stanu přispěvatelem?', body: ['Zaregistrujte se jako přispěvatel a sdílejte svá místa a audioprůvodce.'] },
      ] : [
        { heading: 'How does PlaceSecrets work?', body: ['Find a place on the map or by search, play its audio guide, and rate it.'] },
        { heading: 'What is free?', body: ['Some content is free; free audio is available in a limited amount per period (set by the operator).'] },
        { heading: 'What can I buy?', body: ['A single place, a whole city, or a whole country. Purchased access is always available in your account.'] },
        { heading: 'How do I become a contributor?', body: ['Register as a contributor and share your places and audio guides.'] },
      ]}
    />
  )
}
