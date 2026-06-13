import { useTranslation } from 'react-i18next'
import { LegalLayout } from './LegalLayout'

export default function AboutPage() {
  const { i18n } = useTranslation()
  const cs = i18n.language?.startsWith('cs')
  return (
    <LegalLayout
      draft={false}
      title={cs ? 'O PlaceSecrets' : 'About PlaceSecrets'}
      intro={cs
        ? 'PlaceSecrets je audioprůvodce a cestovní deník, který odhaluje příběhy ukryté za místy kolem vás.'
        : 'PlaceSecrets is an audio guide and travel log that reveals the stories hidden behind the places around you.'}
      sections={[
        {
          heading: cs ? 'Naše mise' : 'Our mission',
          body: [cs
            ? 'Propojit cestovatele s místními znalostmi — poslechněte si poutavé audioprůvodce, objevujte místa na mapě a podpořte přispěvatele, kteří sdílejí své příběhy.'
            : 'To connect travellers with local knowledge — listen to immersive audio guides, discover places on the map, and support the contributors who share their stories.'],
        },
        {
          heading: cs ? 'Pro přispěvatele' : 'For contributors',
          body: [cs
            ? 'Staňte se přispěvatelem a sdílejte tipy na místa s cestovateli z celého světa. Registrace je zdarma.'
            : 'Become a contributor and share local secrets with travellers worldwide. Signing up is free.'],
        },
      ]}
    />
  )
}
