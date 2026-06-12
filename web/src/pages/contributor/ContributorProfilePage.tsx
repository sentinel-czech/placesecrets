import { useEffect, useState } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import type { ContributorProfile } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { toast } from 'sonner'

export default function ContributorProfilePage() {
  const { user } = useAuthStore()
  const [profile, setProfile] = useState<ContributorProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [website, setWebsite] = useState('')
  const [specializations, setSpecializations] = useState('')

  useEffect(() => {
    if (!user) return
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
  }, [user])

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
    else toast.success('Profile updated')
  }

  if (loading) return <Skeleton className="h-64 max-w-lg" />
  if (!profile) return <p>Profile not found</p>

  return (
    <div className="max-w-lg">
      <h2 className="text-lg font-semibold mb-4">My Profile</h2>
      <form onSubmit={handleSubmit}>
        <Card>
          <CardContent className="pt-6 space-y-4">
            <div className="space-y-2">
              <Label>Display Name</Label>
              <Input value={displayName} onChange={e => setDisplayName(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>Bio</Label>
              <textarea
                value={bio}
                onChange={e => setBio(e.target.value)}
                maxLength={300}
                rows={3}
                className="w-full rounded-md border px-3 py-2 text-sm"
                placeholder="Tell us about yourself..."
              />
              <p className="text-xs text-muted-foreground">{bio.length}/300</p>
            </div>
            <div className="space-y-2">
              <Label>Website</Label>
              <Input type="url" value={website} onChange={e => setWebsite(e.target.value)} placeholder="https://" />
            </div>
            <div className="space-y-2">
              <Label>Specializations</Label>
              <Input
                value={specializations}
                onChange={e => setSpecializations(e.target.value)}
                placeholder="history, architecture, nature"
              />
              <p className="text-xs text-muted-foreground">Comma-separated</p>
            </div>
            <Button type="submit" disabled={saving}>
              {saving ? 'Saving...' : 'Save Profile'}
            </Button>
          </CardContent>
        </Card>
      </form>
    </div>
  )
}
