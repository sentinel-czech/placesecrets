import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'

const FIELDS = ['hero_title_1', 'hero_title_2', 'hero_title_3', 'hero_subtitle', 'tagline', 'footer_tagline'] as const
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
    <div className="max-w-2xl space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{t('admin.landing.title', 'Landing page content')}</h1>
          <p className="text-sm text-muted-foreground">{t('admin.landing.desc', 'Edit the public homepage text per language. Empty fields fall back to defaults.')}</p>
        </div>
        <select value={lang} onChange={e => setLang(e.target.value)} className="rounded-md border px-2 py-1 text-sm">
          {LANGS.map(l => <option key={l} value={l}>{l.toUpperCase()}</option>)}
        </select>
      </div>
      <Card>
        <CardContent className="space-y-4 pt-6">
          {FIELDS.map(f => (
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
          <Button onClick={save} disabled={saving}>{saving ? t('common.loading') : t('common.save')}</Button>
        </CardContent>
      </Card>
    </div>
  )
}
