import { useCallback, useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { adminStorageUpload } from '@/lib/supabase/admin-api'
import { X, Upload } from 'lucide-react'
import { toast } from 'sonner'

interface PhotoUploaderProps {
  poiId: string
  photos: string[]
  onChange: (urls: string[]) => void
}

export function PhotoUploader({ poiId, photos, onChange }: PhotoUploaderProps) {
  const [uploading, setUploading] = useState(false)
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null)

  const onDrop = useCallback(async (files: File[]) => {
    setUploading(true)
    const newUrls: string[] = []

    for (const file of files) {
      const ext = file.name.split('.').pop()
      const path = `${poiId}/${crypto.randomUUID()}.${ext}`
      const { error } = await adminStorageUpload('poi-photos', path, file)
      if (error) {
        toast.error(`Upload failed: ${error}`)
        continue
      }
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
      const publicUrl = `${supabaseUrl}/storage/v1/object/public/poi-photos/${path}`
      newUrls.push(publicUrl)
    }

    onChange([...photos, ...newUrls])
    setUploading(false)
  }, [poiId, photos, onChange])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'image/*': ['.png', '.jpg', '.jpeg', '.webp'] },
    maxSize: 5 * 1024 * 1024,
  })

  function removePhoto(index: number) {
    onChange(photos.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        {photos.map((url, i) => (
          <div key={i} className="relative group">
            <img
              src={url}
              alt=""
              className="h-28 w-28 rounded object-cover cursor-pointer"
              onClick={() => setLightboxUrl(url)}
            />
            <button
              type="button"
              onClick={() => removePhoto(i)}
              className="absolute -top-1 -right-1 bg-destructive text-white rounded-full p-0.5 opacity-0 group-hover:opacity-100 transition"
            >
              <X className="h-3 w-3" />
            </button>
          </div>
        ))}
      </div>
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-md p-6 text-center cursor-pointer transition ${
          isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/25'
        }`}
      >
        <input {...getInputProps()} />
        <Upload className="h-6 w-6 mx-auto mb-2 text-muted-foreground" />
        <p className="text-sm text-muted-foreground">
          {uploading ? 'Uploading...' : 'Drop photos here or click to browse'}
        </p>
      </div>

      {lightboxUrl && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center"
          onClick={() => setLightboxUrl(null)}
        >
          <button
            type="button"
            className="absolute top-4 right-4 text-white/80 hover:text-white transition"
            onClick={() => setLightboxUrl(null)}
          >
            <X className="h-8 w-8" />
          </button>
          <img
            src={lightboxUrl}
            alt=""
            className="max-h-[90vh] max-w-[90vw] object-contain rounded"
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </div>
  )
}
