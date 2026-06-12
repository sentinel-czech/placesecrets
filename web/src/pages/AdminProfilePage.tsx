import { useEffect, useState } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import type { ContributorProfile } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'

export default function AdminProfilePage() {
  const { user, role } = useAuthStore()
  const [profile, setProfile] = useState<ContributorProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const { t } = useTranslation()

  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [website, setWebsite] = useState('')
  const [specializations, setSpecializations] = useState('')

  const isContributor = role === 'contributor'

  useEffect(() => {
    if (!user) return
    if (!isContributor) {
      setLoading(false)
      return
    }
    supabase.from('contributor_profiles').select('*').eq('user_id', user.id).single().then(({ data }) => {
      if (data) {
        const p = data as ContributorProfile
        setProfile(p)
        setDisplayName(p.display_name)
        setBio(p.bio || '')
        setWebsite(p.website_url || '')
        setSpecializations(p.specializations.join(', '))
      }
      setLoading(false)
    })
  }, [user, isContributor])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!profile) return

    setSaving(true)
    const { error } = await supabase.from('contributor_profiles').update({
      display_name: displayName,
      bio: bio || null,
      website_url: website || null,
      specializations: specializations.split(',').map(s => s.trim()).filter(Boolean),
    }).eq('id', profile.id)

    setSaving(false)
    if (error) toast.error(error.message)
    else toast.success(t('common.success'))
  }

  if (loading) return <Skeleton className="h-64 max-w-lg" />

  if (!isContributor) {
    return (
      <div className="max-w-lg">
        <h1 className="text-xl font-semibold mb-4">{t('nav.myProfile')}</h1>
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">{user?.email}</p>
            <p className="text-sm mt-1 font-medium capitalize">{role}</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!profile) return <p>{t('adminProfile.profileNotFound')}</p>

  return (
    <div className="max-w-lg">
      <h1 className="text-xl font-semibold mb-4">{t('nav.myProfile')}</h1>
      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader><CardTitle className="text-base">{t('nav.myProfile')}</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>{t('adminProfile.displayName')}</Label>
              <Input value={displayName} onChange={e => setDisplayName(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>{t('adminProfile.bio')}</Label>
              <textarea
                value={bio}
                onChange={e => setBio(e.target.value)}
                maxLength={300}
                rows={3}
                className="w-full rounded-md border px-3 py-2 text-sm"
                placeholder={t('adminProfile.bioPlaceholder')}
              />
              <p className="text-xs text-muted-foreground">{bio.length}/300</p>
            </div>
            <div className="space-y-2">
              <Label>{t('adminProfile.website')}</Label>
              <Input type="url" value={website} onChange={e => setWebsite(e.target.value)} placeholder="https://" />
            </div>
            <div className="space-y-2">
              <Label>{t('adminProfile.specializations')}</Label>
              <Input
                value={specializations}
                onChange={e => setSpecializations(e.target.value)}
                placeholder={t('adminProfile.specializationsPlaceholder')}
              />
              <p className="text-xs text-muted-foreground">{t('adminProfile.commaSeparated')}</p>
            </div>
            <Button type="submit" disabled={saving}>
              {saving ? t('common.loading') : t('common.save')}
            </Button>
          </CardContent>
        </Card>
      </form>
    </div>
  )
}
