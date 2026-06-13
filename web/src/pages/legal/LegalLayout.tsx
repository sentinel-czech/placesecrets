import { useTranslation } from 'react-i18next'
import { Helmet } from 'react-helmet-async'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { PublicFooter } from '@/components/layout/PublicFooter'

export interface LegalSection {
  heading: string
  body: string[]
}

interface LegalLayoutProps {
  title: string
  lastUpdated: string
  intro?: string
  sections: LegalSection[]
}

/** Shared chrome for Terms / Privacy / static legal pages. */
export function LegalLayout({ title, lastUpdated, intro, sections }: LegalLayoutProps) {
  const { t } = useTranslation()
  return (
    <div className="flex min-h-screen flex-col">
      <Helmet>
        <title>{title} — PlaceSecrets</title>
      </Helmet>
      <PublicHeader />
      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-12 sm:px-6">
        <div className="mb-6 rounded-md border border-amber-300 bg-amber-50 px-4 py-2 text-sm text-amber-800">
          {t('legal.draftNotice', 'DRAFT — template text, must be reviewed by a lawyer before launch.')}
        </div>
        <h1 className="text-3xl font-bold">{title}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {t('legal.lastUpdated', 'Last updated')}: {lastUpdated}
        </p>
        {intro && <p className="mt-6 leading-relaxed text-foreground/90">{intro}</p>}
        <div className="mt-8 space-y-8">
          {sections.map((s, i) => (
            <section key={i}>
              <h2 className="text-xl font-semibold">{`${i + 1}. ${s.heading}`}</h2>
              <div className="mt-2 space-y-3 leading-relaxed text-foreground/90">
                {s.body.map((p, j) => (
                  <p key={j}>{p}</p>
                ))}
              </div>
            </section>
          ))}
        </div>
      </main>
      <PublicFooter />
    </div>
  )
}
