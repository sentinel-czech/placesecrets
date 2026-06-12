import { useEffect, useState, useCallback } from 'react'
import { adminSelect, adminInsert, adminUpdate, adminDelete, adminStorageUploadUpsert } from '@/lib/supabase/admin-api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { X, Upload, Loader2, Star } from 'lucide-react'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'
import type { PoiAudioGuide } from '@/lib/supabase/types'
import { LANG_CODES, LANG_LABELS } from '@/lib/constants'

interface AudioUploaderProps {
  poiId: string
  contributorId?: string | null
}

interface ContributorInfo {
  display_name: string
  avatar_url: string | null
}

const ACCEPTED_AUDIO_EXTENSIONS = ['.mp3', '.wav', '.ogg', '.aac', '.m4a', '.flac', '.wma', '.webm']
const ACCEPTED_AUDIO = ACCEPTED_AUDIO_EXTENSIONS.join(',')

function formatDuration(sec: number | null): string {
  if (!sec) return ''
  const m = Math.floor(sec / 60)
  const s = sec % 60
  return `${m}:${s.toString().padStart(2, '0')}`
}

function formatCount(n: number): string {
  if (n >= 1000) return `${Math.floor(n / 1000)}K+`
  return String(n)
}

function extractFilename(url: string): string {
  try {
    const parts = url.split('/')
    return parts[parts.length - 1] || ''
  } catch {
    return ''
  }
}

export function AudioUploader({ poiId, contributorId }: AudioUploaderProps) {
  const { t, i18n } = useTranslation()
  const [guides, setGuides] = useState<PoiAudioGuide[]>([])
  const [uploaderMap, setUploaderMap] = useState<Map<string, ContributorInfo>>(new Map())
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const [editingTitle, setEditingTitle] = useState<string | null>(null)
  const [selectedLang, setSelectedLang] = useState(() => {
    const current = i18n.language.substring(0, 2)
    return (LANG_CODES as readonly string[]).includes(current) ? current : 'en'
  })
  const [uploadTitle, setUploadTitle] = useState('')
  const [maxAudioSizeMb, setMaxAudioSizeMb] = useState(50)

  const isNew = poiId === 'new'

  const fetchGuides = useCallback(async () => {
    if (isNew) { setLoading(false); return }
    const { data } = await adminSelect('poi_audio_guides', {
      filters: [{ column: 'poi_id', op: 'eq', value: poiId }],
      order: { column: 'sort_order' },
    })
    if (data) {
      const fetchedGuides = data as PoiAudioGuide[]
      setGuides(fetchedGuides)

      // Batch-fetch display names (with email fallback) + avatars
      const uidSet = new Set(fetchedGuides.map(g => g.uploaded_by).filter(Boolean) as string[])
      if (contributorId) uidSet.add(contributorId)
      const uids = [...uidSet]
      if (uids.length > 0) {
        const map = new Map<string, ContributorInfo>()
        // admin_users_view has both display_name and email
        const { data: adminUsers } = await adminSelect('admin_users_view', {
          select: 'id, email, display_name',
          filters: [{ column: 'id', op: 'in', value: uids }],
        })
        if (adminUsers) {
          for (const u of adminUsers as Array<{ id: string; email: string; display_name: string | null }>) {
            const name = u.display_name ?? u.email.split('@')[0]
            map.set(u.id, { display_name: name, avatar_url: null })
          }
        }
        // Fetch avatars from contributor_profiles for those who have them
        const { data: contribProfiles } = await adminSelect('contributor_profiles', {
          select: 'user_id, avatar_url',
          filters: [{ column: 'user_id', op: 'in', value: uids }],
        })
        if (contribProfiles) {
          for (const p of contribProfiles as Array<{ user_id: string; avatar_url: string | null }>) {
            const existing = map.get(p.user_id)
            if (existing) {
              existing.avatar_url = p.avatar_url
            }
          }
        }
        setUploaderMap(map)
      }
    }
    setLoading(false)
  }, [poiId, isNew, contributorId])

  useEffect(() => { fetchGuides() }, [fetchGuides])

  // Fetch max_audio_size_mb from system config
  useEffect(() => {
    adminSelect('payment_config', {
      select: 'max_audio_size_mb',
      single: true,
    }).then(({ data }) => {
      if (data && (data as { max_audio_size_mb?: number }).max_audio_size_mb) {
        setMaxAudioSizeMb((data as { max_audio_size_mb: number }).max_audio_size_mb)
      }
    })
  }, [])

  if (isNew) {
    return (
      <p className="text-sm text-muted-foreground">
        {t('audioUploader.saveFirst', 'Save the POI first to upload audio guides.')}
      </p>
    )
  }

  async function handleUpload(file: File) {
    const ext = '.' + (file.name.split('.').pop()?.toLowerCase() || '')
    if (!ACCEPTED_AUDIO_EXTENSIONS.includes(ext)) {
      toast.error(t('audioUploader.unsupportedFormat', 'Unsupported audio format'))
      return
    }
    if (file.size > maxAudioSizeMb * 1024 * 1024) {
      toast.error(t('audioUploader.fileTooLarge', `File exceeds ${maxAudioSizeMb} MB limit`))
      return
    }

    setUploading(true)
    try {
      const guideId = crypto.randomUUID()
      const fileExt = file.name.split('.').pop() || 'mp3'
      const storagePath = `${poiId}/${guideId}.${fileExt}`

      const { error: uploadErr } = await adminStorageUploadUpsert('audio-guides', storagePath, file)
      if (uploadErr) {
        toast.error(`Upload failed: ${uploadErr}`)
        return
      }

      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
      const publicUrl = `${supabaseUrl}/storage/v1/object/public/audio-guides/${storagePath}`

      // Extract duration from local blob (faster and more reliable than network URL)
      let durationSec: number | null = null
      const blobUrl = URL.createObjectURL(file)
      try {
        durationSec = await getAudioDuration(blobUrl)
      } catch {
        // Duration extraction is best-effort
      } finally {
        URL.revokeObjectURL(blobUrl)
      }

      const maxSort = guides.reduce((max, g) => Math.max(max, g.sort_order), -1)
      const { error: insertErr } = await adminInsert('poi_audio_guides', {
        id: guideId,
        poi_id: poiId,
        lang_code: selectedLang,
        title: uploadTitle,
        url: publicUrl,
        duration_sec: durationSec,
        sort_order: maxSort + 1,
      })

      if (insertErr) {
        toast.error(`Save failed: ${insertErr}`)
        return
      }

      setUploadTitle('')
      await fetchGuides()
      toast.success(t('audioUploader.uploaded', 'Audio uploaded'))
    } finally {
      setUploading(false)
    }
  }

  async function handleDelete(guide: PoiAudioGuide) {
    const { error } = await adminDelete('poi_audio_guides', [
      { column: 'id', op: 'eq', value: guide.id },
    ])
    if (error) {
      toast.error(`Delete failed: ${error}`)
      return
    }
    setGuides(prev => prev.filter(g => g.id !== guide.id))
    toast.success(t('audioUploader.deleted', 'Audio deleted'))
  }

  async function handleTitleSave(guide: PoiAudioGuide, newTitle: string) {
    const { error } = await adminUpdate('poi_audio_guides', { title: newTitle }, [
      { column: 'id', op: 'eq', value: guide.id },
    ])
    if (error) {
      toast.error(`Update failed: ${error}`)
      return
    }
    setGuides(prev => prev.map(g => g.id === guide.id ? { ...g, title: newTitle } : g))
    setEditingTitle(null)
  }

  // Group guides by language — only show languages that have guides
  const byLang = LANG_CODES
    .map(code => ({
      code,
      label: LANG_LABELS[code] || code.toUpperCase(),
      guides: guides.filter(g => g.lang_code === code),
    }))
    .filter(lang => lang.guides.length > 0)

  if (loading) {
    return <div className="flex items-center gap-2 text-sm text-muted-foreground"><Loader2 className="h-4 w-4 animate-spin" /> Loading...</div>
  }

  return (
    <div className="space-y-4">
      {/* Upload form */}
      <div className="flex items-end gap-3 pb-4 border-b">
        <div className="space-y-1">
          <Label className="text-xs">{t('audioUploader.language', 'Language')}</Label>
          <select
            value={selectedLang}
            onChange={e => setSelectedLang(e.target.value)}
            className="h-9 rounded-md border border-input bg-background px-3 text-sm"
          >
            {LANG_CODES.map(c => (
              <option key={c} value={c}>{LANG_LABELS[c]}</option>
            ))}
          </select>
        </div>
        <div className="space-y-1 flex-1">
          <Label className="text-xs">{t('audioUploader.title', 'Title')}</Label>
          <Input
            value={uploadTitle}
            onChange={e => setUploadTitle(e.target.value)}
            placeholder={t('audioUploader.titlePlaceholder', 'Audio guide title (optional)')}
          />
        </div>
        <label className="cursor-pointer flex-shrink-0">
          <Input
            type="file"
            accept={ACCEPTED_AUDIO}
            className="hidden"
            disabled={uploading}
            onChange={e => {
              const file = e.target.files?.[0]
              if (file) handleUpload(file)
              e.target.value = ''
            }}
          />
          <span className="inline-flex items-center gap-1.5 px-4 h-9 text-sm rounded-md border hover:bg-muted transition cursor-pointer">
            {uploading ? (
              <><Loader2 className="h-4 w-4 animate-spin" /> {t('audioUploader.uploading', 'Uploading...')}</>
            ) : (
              <><Upload className="h-4 w-4" /> {t('audioUploader.upload', 'Upload')}</>
            )}
          </span>
        </label>
      </div>

      {/* Existing guides grouped by language */}
      {byLang.length === 0 && (
        <p className="text-sm text-muted-foreground">{t('audioUploader.noGuides', 'No audio guides yet.')}</p>
      )}
      {byLang.map(lang => (
        <div key={lang.code} className="space-y-2">
          <Label className="text-sm font-medium">{lang.label}</Label>
          <div className="space-y-1.5 pl-2">
            {lang.guides.map(guide => {
              const uploaderId = guide.uploaded_by || contributorId
              const info = uploaderId ? uploaderMap.get(uploaderId) : undefined
              return (
                <div
                  key={guide.id}
                  className="grid items-center gap-2 rounded-md border px-2 py-1.5 text-sm"
                  style={{ gridTemplateColumns: 'minmax(0,10rem) minmax(0,20rem) auto minmax(6rem,auto) auto 1fr auto' }}
                >
                  {/* Uploader handle */}
                  {info ? (
                    <span className="text-xs text-muted-foreground flex items-center gap-1 truncate" title={info.display_name}>
                      {info.avatar_url && (
                        <img src={info.avatar_url} alt="" className="h-4 w-4 rounded-full flex-shrink-0" />
                      )}
                      <span className="truncate">@{info.display_name}</span>
                    </span>
                  ) : (
                    <span />
                  )}
                  {/* Title (inline-editable) */}
                  {editingTitle === guide.id ? (
                    <input
                      type="text"
                      defaultValue={guide.title}
                      className="border-b bg-transparent text-sm outline-none min-w-0 truncate"
                      autoFocus
                      onBlur={e => handleTitleSave(guide, e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter') handleTitleSave(guide, (e.target as HTMLInputElement).value)
                        if (e.key === 'Escape') setEditingTitle(null)
                      }}
                    />
                  ) : (
                    <button
                      type="button"
                      className="min-w-0 truncate text-left hover:text-primary transition"
                      onClick={() => setEditingTitle(guide.id)}
                      title={t('audioUploader.clickToEditTitle', 'Click to edit title')}
                    >
                      {guide.title || <span className="text-muted-foreground italic">{t('audioUploader.untitled', 'Untitled')}</span>}
                    </button>
                  )}
                  {/* Filename */}
                  <span className="text-xs text-muted-foreground/60 font-mono whitespace-nowrap" title={guide.id}>
                    {extractFilename(guide.url) || guide.id.substring(0, 8)}
                  </span>
                  {/* Rating */}
                  <span className="text-xs text-muted-foreground flex items-center gap-1 whitespace-nowrap pr-2">
                    {guide.total_ratings > 0 ? (
                      <>
                        <Star className="h-3 w-3 text-yellow-500 fill-yellow-500" />
                        {(Math.round(Number(guide.avg_rating) * 10) / 10).toFixed(1)}
                        <span className="text-muted-foreground/60" title={String(guide.total_ratings)}>
                          ({formatCount(guide.total_ratings)})
                        </span>
                      </>
                    ) : (
                      <Star className="h-3 w-3 text-muted-foreground/30" />
                    )}
                  </span>
                  {/* Duration */}
                  <span className="text-xs text-muted-foreground font-mono whitespace-nowrap">
                    {guide.duration_sec != null ? formatDuration(guide.duration_sec) : ''}
                  </span>
                  {/* Audio player */}
                  <div className="min-w-[160px] bg-gray-900 rounded px-1 py-0.5">
                    <audio src={guide.url} controls className="h-6 w-full" />
                  </div>
                  {/* Delete button */}
                  <Button type="button" variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={() => handleDelete(guide)}>
                    <X className="h-3.5 w-3.5" />
                  </Button>
                </div>
              )
            })}
          </div>
        </div>
      ))}
    </div>
  )
}

function getAudioDuration(url: string): Promise<number> {
  return new Promise((resolve, reject) => {
    const audio = new Audio()
    audio.preload = 'metadata'
    audio.onloadedmetadata = () => {
      resolve(Math.round(audio.duration))
      audio.src = ''
    }
    audio.onerror = () => reject(new Error('Failed to load audio metadata'))
    audio.src = url
  })
}
