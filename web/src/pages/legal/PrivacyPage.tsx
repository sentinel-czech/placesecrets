import { useTranslation } from 'react-i18next'
import { LegalLayout, type LegalSection } from './LegalLayout'

const OPERATOR = '{Provozovatel s.r.o.}'
const CONTACT = '{privacy@placesecrets.app}'
const UPDATED = '2026-06-13'

const CS: { title: string; intro: string; sections: LegalSection[] } = {
  title: 'Zásady ochrany osobních údajů',
  intro: `Tyto zásady popisují, jak ${OPERATOR} („Správce") zpracovává osobní údaje uživatelů služby PlaceSecrets v souladu s GDPR.`,
  sections: [
    { heading: 'Jaké údaje zpracováváme', body: [
      'Registrační údaje (e-mail, přezdívka), volitelně záložní e-mail; údaje o nákupech a přístupech; obsah, který vložíte (hodnocení, komentáře, místa); technické údaje (jazyk, identifikátor zařízení), souhlasy a jejich časová razítka.',
    ]},
    { heading: 'Účel a právní základ', body: [
      'Poskytování Služby a správa účtu (plnění smlouvy); zpracování plateb a vystavení dokladů (právní povinnost); zlepšování Služby a zabezpečení (oprávněný zájem); zasílání novinek pouze na základě vašeho souhlasu (marketing).',
    ]},
    { heading: 'Příjemci a zpracovatelé', body: [
      'Poskytovatel hostingu/databáze (Supabase), platební brána (např. Comgate/Stripe/Revolut), odesílání e-mailů. Údaje předáváme jen v nezbytném rozsahu a na základě smluv o zpracování.',
    ]},
    { heading: 'Doba uchování', body: [
      'Údaje uchováváme po dobu trvání účtu a dále po dobu vyžadovanou právními předpisy (např. účetní doklady). Po zrušení účtu údaje odstraníme nebo anonymizujeme, není-li dán zákonný důvod k jejich uchování.',
    ]},
    { heading: 'Vaše práva', body: [
      'Máte právo na přístup, opravu, výmaz, omezení zpracování, přenositelnost a vznesení námitky, a právo odvolat souhlas. Export svých dat lze provést přímo v nastavení profilu.',
      'Můžete podat stížnost u Úřadu pro ochranu osobních údajů.',
    ]},
    { heading: 'Cookies a místní úložiště', body: [
      'Používáme nezbytné technické úložiště (např. přihlášení, volba jazyka). Nepoužíváme reklamní sledování bez vašeho souhlasu.',
    ]},
    { heading: 'Kontakt', body: [
      'Ve věcech ochrany údajů nás kontaktujte na ' + CONTACT + '.',
    ]},
  ],
}

const EN: { title: string; intro: string; sections: LegalSection[] } = {
  title: 'Privacy Policy',
  intro: `This policy describes how ${OPERATOR} ("Controller") processes the personal data of PlaceSecrets users in accordance with the GDPR.`,
  sections: [
    { heading: 'Data we process', body: [
      'Registration data (email, handle), optionally a backup email; purchase and access data; content you submit (ratings, comments, places); technical data (language, device identifier), and consents with their timestamps.',
    ]},
    { heading: 'Purpose and legal basis', body: [
      'Providing the Service and managing your account (contract performance); processing payments and issuing documents (legal obligation); improving and securing the Service (legitimate interest); newsletters only with your consent (marketing).',
    ]},
    { heading: 'Recipients and processors', body: [
      'Hosting/database provider (Supabase), payment gateway (e.g. Comgate/Stripe/Revolut), email delivery. Data is shared only to the extent necessary and under data-processing agreements.',
    ]},
    { heading: 'Retention', body: [
      'We retain data for the duration of the account and as required by law (e.g. accounting records). After account deletion we erase or anonymise data unless a legal ground requires retention.',
    ]},
    { heading: 'Your rights', body: [
      'You have the right to access, rectification, erasure, restriction, portability and objection, and to withdraw consent. You can export your data directly from profile settings.',
      'You may lodge a complaint with your data-protection authority.',
    ]},
    { heading: 'Cookies and local storage', body: [
      'We use necessary technical storage (e.g. login, language choice). We do not use advertising tracking without your consent.',
    ]},
    { heading: 'Contact', body: [
      'For data-protection matters contact us at ' + CONTACT + '.',
    ]},
  ],
}

export default function PrivacyPage() {
  const { i18n } = useTranslation()
  const c = i18n.language?.startsWith('cs') ? CS : EN
  return <LegalLayout title={c.title} lastUpdated={UPDATED} intro={c.intro} sections={c.sections} />
}
