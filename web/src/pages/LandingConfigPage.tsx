import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Section } from '@/components/shared/Section'
import { toast } from 'sonner'

// Landing-page CMS fields grouped by the section they render in. Each field is a
// per-language JSONB column on `landing_config`; LandingPage falls back to its
// i18n keys when a value is empty, so leaving a field blank is safe.
const SECTIONS: { title: string; fields: string[] }[] = [
  { title: 'Hero', fields: ['tagline', 'hero_title_1', 'hero_title_2', 'hero_title_3', 'hero_subtitle'] },
  { title: 'Explore', fields: ['explore_title', 'explore_desc'] },
  { title: 'Featured', fields: ['featured_title', 'featured_desc'] },
  {
    title: 'How it works',
    fields: [
      'how_title', 'how_desc',
      'how_step1_title', 'how_step1_desc',
      'how_step2_title', 'how_step2_desc',
      'how_step3_title', 'how_step3_desc',
    ],
  },
  { title: 'Call to action', fields: ['cta_title', 'cta_desc'] },
  { title: 'Footer', fields: ['footer_tagline'] },
]
const FIELDS = SECTIONS.flatMap(s => s.fields)
const LANGS = ['en', 'cs', 'sk', 'de', 'es', 'fr', 'pt', 'ru', 'vi', 'zh', 'ko']
type Cfg = { id: number } & Record<string, Record<string, string>>

export default function LandingConfigPage() {
  const { t } = useTranslation()
  const [cfg, setCfg] = useState<Cfg | null>(null)
  const [lang, setLang] = useState('en')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    adminSelect('landing_config', { select: '*', single: true }).then(({ data }) => {
      if (data) setCfg(data as Cfg)
    })
  }, [])

  function setField(field: string, value: string) {
    if (!cfg) return
    setCfg({ ...cfg, [field]: { ...(cfg[field] || {}), [lang]: value } })
  }

  async function save() {
    if (!cfg) return
    setSaving(true)
    const payload: Record<string, unknown> = {}
    for (const f of FIELDS) payload[f] = cfg[f] || {}
    const { error } = await adminUpdate('landing_config', payload, [{ column: 'id', op: 'eq', value: 1 }])
    setSaving(false)
    if (error) toast.error(error)
    else toast.success(t('settings.configSaved', 'Saved'))
  }

  if (!cfg) return <p className="text-muted-foreground">{t('common.loading')}</p>

  return (
    <div className="max-w-2xl">
      <Section
        title={t('admin.landing.title', 'Landing page content')}
        description={t('admin.landing.desc', 'Edit the public homepage text per language. Empty fields fall back to defaults.')}
        action={
          <select value={lang} onChange={e => setLang(e.target.value)} className="rounded-md border px-2 py-1 text-sm">
            {LANGS.map(l => <option key={l} value={l}>{l.toUpperCase()}</option>)}
          </select>
        }
      >
        <div className="space-y-4">
          {SECTIONS.map(section => (
            <Card key={section.title}>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">{section.title}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {section.fields.map(f => (
                  <div key={f} className="space-y-1">
                    <Label className="capitalize">{f.replace(/_/g, ' ')}</Label>
                    <textarea
                      value={cfg[f]?.[lang] || ''}
                      onChange={e => setField(f, e.target.value)}
                      rows={2}
                      className="w-full rounded-md border px-3 py-2 text-sm"
                    />
                  </div>
                ))}
              </CardContent>
            </Card>
          ))}
          <Button onClick={save} disabled={saving}>{saving ? t('common.loading') : t('common.save')}</Button>
        </div>
      </Section>
    </div>
  )
}
