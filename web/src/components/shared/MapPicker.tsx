import { lazy, Suspense } from 'react'
import { Skeleton } from '@/components/ui/skeleton'

const LazyMap = lazy(() => import('./MapPickerInner'))

interface MapPickerProps {
  latitude: number
  longitude: number
  onChange: (lat: number, lng: number) => void
  radius?: number
}

export function MapPicker(props: MapPickerProps) {
  return (
    <Suspense fallback={<Skeleton className="h-[300px] w-full rounded-md" />}>
      <LazyMap {...props} />
    </Suspense>
  )
}
