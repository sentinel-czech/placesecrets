import { useTranslation } from 'react-i18next'
import { LegalLayout, type LegalSection } from './LegalLayout'

const OPERATOR = '{Provozovatel s.r.o.}'
const CONTACT = '{contact@placesecrets.app}'
const UPDATED = '2026-06-13'

const CS: { title: string; intro: string; sections: LegalSection[] } = {
  title: 'Podmínky použití',
  intro: `Tyto podmínky upravují používání služby PlaceSecrets („Služba") provozované ${OPERATOR} („Provozovatel"). Registrací nebo používáním Služby s nimi vyjadřujete souhlas.`,
  sections: [
    { heading: 'Služba', body: [
      'PlaceSecrets je platforma pro audioprůvodce a cestovní deník k místům (POI). Část obsahu je volně dostupná, část za úplatu nebo po registraci.',
      'Provozovatel může Službu, její funkce a ceny kdykoli měnit nebo ukončit.',
    ]},
    { heading: 'Účet a registrace', body: [
      'Pro některé funkce je nutná registrace. Uvádějte pravdivé údaje a chraňte své přihlašovací údaje; za aktivitu na účtu odpovídáte vy.',
      'Účet je určen osobám starším 16 let (resp. dle místních předpisů). Registrací potvrzujete, že tuto podmínku splňujete.',
    ]},
    { heading: 'Obsah uživatele a licence', body: [
      'Pokud do Služby vkládáte obsah (např. místa, popisy, audio, hodnocení, komentáře), zůstáváte jeho vlastníkem.',
      'Vložením obsahu udělujete Provozovateli nevýhradní, celosvětovou, bezúplatnou a převoditelnou licenci tento obsah užívat, ukládat, reprodukovat, upravovat, překládat a zobrazovat v rámci provozu a propagace Služby, a to po dobu trvání ochrany práv.',
      'Odpovídáte za to, že máte k vloženému obsahu potřebná práva a že neporušuje práva třetích osob ani právní předpisy.',
    ]},
    { heading: 'Pravidla užívání', body: [
      'Je zakázáno vkládat protiprávní, klamavý, urážlivý nebo cizí práva porušující obsah, zasahovat do bezpečnosti Služby, obcházet přístupová omezení nebo Službu zneužívat k automatizovanému stahování.',
      'Provozovatel může obsah moderovat, skrýt či odstranit a účet omezit nebo zrušit při porušení těchto podmínek.',
    ]},
    { heading: 'Platby a přístup', body: [
      'Placený obsah (jednotlivé místo, město nebo země) zpřístupňujeme po úhradě přes platební bránu. Zakoupený přístup je dostupný dle zvoleného rozsahu a doby platnosti.',
      'Volný obsah je dostupný v omezeném rozsahu (např. limit za období). Ceny a rozsah jsou uvedeny u nákupu.',
    ]},
    { heading: 'Omezení odpovědnosti', body: [
      'Služba je poskytována „tak, jak je". Provozovatel neodpovídá za úplnost, přesnost ani aktuálnost obsahu třetích stran a za škody vzniklé jejím užíváním v rozsahu povoleném zákonem.',
      'Provozovatel neodpovídá za nedostupnost Služby způsobenou okolnostmi mimo jeho kontrolu.',
    ]},
    { heading: 'Ukončení', body: [
      'Účet můžete kdykoli zrušit. Provozovatel může přístup ukončit při porušení podmínek nebo z provozních důvodů.',
    ]},
    { heading: 'Změny podmínek', body: [
      'Provozovatel může podmínky měnit; o podstatných změnách informuje vhodným způsobem. Pokračováním v užívání po účinnosti změn vyjadřujete souhlas.',
    ]},
    { heading: 'Rozhodné právo a kontakt', body: [
      'Vztah se řídí právem České republiky. Kontakt: ' + CONTACT + '.',
    ]},
  ],
}

const EN: { title: string; intro: string; sections: LegalSection[] } = {
  title: 'Terms of Service',
  intro: `These terms govern the use of the PlaceSecrets service ("Service") operated by ${OPERATOR} ("Operator"). By registering or using the Service you agree to them.`,
  sections: [
    { heading: 'The Service', body: [
      'PlaceSecrets is a platform for audio guides and a travel log of places (POIs). Some content is free, some is paid or requires registration.',
      'The Operator may change or discontinue the Service, its features and prices at any time.',
    ]},
    { heading: 'Account and registration', body: [
      'Some features require registration. Provide accurate information and keep your credentials safe; you are responsible for activity on your account.',
      'Accounts are intended for users aged 16+ (or as required locally). By registering you confirm you meet this requirement.',
    ]},
    { heading: 'User content and licence', body: [
      'If you submit content (e.g. places, descriptions, audio, ratings, comments) you remain its owner.',
      'By submitting content you grant the Operator a non-exclusive, worldwide, royalty-free, transferable licence to use, store, reproduce, modify, translate and display that content in order to operate and promote the Service, for the duration of the applicable rights.',
      'You are responsible for holding the necessary rights to submitted content and for it not infringing third-party rights or laws.',
    ]},
    { heading: 'Acceptable use', body: [
      'You must not submit unlawful, misleading, abusive or infringing content, interfere with the Service’s security, bypass access restrictions, or abuse the Service for automated scraping.',
      'The Operator may moderate, hide or remove content and restrict or terminate accounts for breaches of these terms.',
    ]},
    { heading: 'Payments and access', body: [
      'Paid content (a single place, a city or a country) is unlocked after payment via a payment gateway. Purchased access is available per the chosen scope and validity period.',
      'Free content is available to a limited extent (e.g. a per-period limit). Prices and scope are shown at checkout.',
    ]},
    { heading: 'Limitation of liability', body: [
      'The Service is provided "as is". To the extent permitted by law, the Operator is not liable for the completeness, accuracy or timeliness of third-party content or for damages arising from use of the Service.',
      'The Operator is not liable for unavailability caused by circumstances beyond its control.',
    ]},
    { heading: 'Termination', body: [
      'You may delete your account at any time. The Operator may terminate access for breaches of the terms or for operational reasons.',
    ]},
    { heading: 'Changes', body: [
      'The Operator may amend these terms; material changes will be communicated appropriately. Continued use after changes take effect constitutes acceptance.',
    ]},
    { heading: 'Governing law and contact', body: [
      'These terms are governed by the laws of the Czech Republic. Contact: ' + CONTACT + '.',
    ]},
  ],
}

export default function TermsPage() {
  const { i18n } = useTranslation()
  const c = i18n.language?.startsWith('cs') ? CS : EN
  return <LegalLayout title={c.title} lastUpdated={UPDATED} intro={c.intro} sections={c.sections} />
}
