import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { PlaceDetailSheet } from './PlaceDetailSheet'
import { PoiTypeFilter } from './PoiTypeFilter'
import type { PoiType } from '@/lib/supabase/types'
import { MapPin } from 'lucide-react'
import { escapeHtml } from '@/lib/utils'

interface NearbyPoi {
  id: string
  name: Record<string, string>
  slug: string | null
  perex: Record<string, string> | null
  access_level: string
  avg_rating: number | null
  total_ratings: number
  latitude: number
  longitude: number
  photo_urls: string[]
  type_id: string | null
  city_slug: string | null
  country_code: string | null
}

interface ExploreMapProps {
  poiTypes: PoiType[]
}

export function ExploreMap({ poiTypes }: ExploreMapProps) {
  const { t } = useTranslation()
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const [gpsState, setGpsState] = useState<'loading' | 'denied' | 'ready'>('loading')
  const [position, setPosition] = useState<{ lat: number; lng: number } | null>(null)
  const [pois, setPois] = useState<NearbyPoi[]>([])
  const [selectedTypes, setSelectedTypes] = useState<Set<string>>(new Set())
  const [selectedPoi, setSelectedPoi] = useState<NearbyPoi | null>(null)

  useEffect(() => {
    if (!navigator.geolocation) {
      setGpsState('denied')
      return
    }
    navigator.geolocation.getCurrentPosition(
      pos => {
        setPosition({ lat: pos.coords.latitude, lng: pos.coords.longitude })
        setGpsState('ready')
      },
      () => setGpsState('denied')
    )
  }, [])

  useEffect(() => {
    if (!position) return

    const delta = 0.1 // ~10km bounding box
    supabase
      .from('pois')
      .select('id, name, slug, perex, access_level, avg_rating, total_ratings, latitude, longitude, photo_urls, type_id, cities(slug, country_code)')
      .gte('latitude', position.lat - delta)
      .lte('latitude', position.lat + delta)
      .gte('longitude', position.lng - delta)
      .lte('longitude', position.lng + delta)
      .eq('is_active', true)
      .then(({ data }) => {
        if (data) {
          setPois(data.map((p: Record<string, unknown>) => ({
            id: p.id as string,
            name: p.name as Record<string, string>,
            slug: p.slug as string | null,
            perex: p.perex as Record<string, string> | null,
            access_level: p.access_level as string,
            avg_rating: p.avg_rating as number | null,
            total_ratings: p.total_ratings as number,
            latitude: p.latitude as number,
            longitude: p.longitude as number,
            photo_urls: p.photo_urls as string[],
            type_id: p.type_id as string | null,
            city_slug: (p.cities as Record<string, string>)?.slug ?? null,
            country_code: (p.cities as Record<string, string>)?.country_code ?? null,
          })))
        }
      })
  }, [position])

  useEffect(() => {
    if (!containerRef.current || !position || mapRef.current) return

    mapRef.current = L.map(containerRef.current, {
      scrollWheelZoom: true,
    }).setView([position.lat, position.lng], 13)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(mapRef.current)

    // User position marker
    L.circleMarker([position.lat, position.lng], {
      radius: 10,
      fillColor: '#3B82F6',
      color: '#fff',
      fillOpacity: 1,
      weight: 3,
    }).bindTooltip(t('user.dashboard.explore.you')).addTo(mapRef.current)

    return () => {
      mapRef.current?.remove()
      mapRef.current = null
    }
  }, [position])

  useEffect(() => {
    if (!mapRef.current) return

    // Clear POI markers (keep user marker)
    mapRef.current.eachLayer(layer => {
      if (layer instanceof L.CircleMarker && (layer.options as { fillColor?: string }).fillColor !== '#3B82F6') {
        mapRef.current!.removeLayer(layer)
      }
    })

    const filtered = selectedTypes.size > 0
      ? pois.filter(p => p.type_id && selectedTypes.has(p.type_id))
      : pois

    const typeMap = new Map(poiTypes.map(pt => [pt.id, pt]))

    filtered.forEach(poi => {
      const type = poi.type_id ? typeMap.get(poi.type_id) : null
      const color = type?.color_hex || '#2D6A4F'
      const marker = L.circleMarker([poi.latitude, poi.longitude], {
        radius: 7,
        fillColor: color,
        color,
        fillOpacity: 0.8,
        weight: 2,
      })
      marker.bindTooltip(escapeHtml(poi.name?.cs || poi.name?.en || 'Place'))
      marker.on('click', () => setSelectedPoi(poi))
      marker.addTo(mapRef.current!)
    })
  }, [pois, selectedTypes, poiTypes])

  if (gpsState === 'loading') {
    return (
      <div className="flex items-center justify-center h-[360px] border rounded-lg">
        <p className="text-muted-foreground">{t('user.dashboard.explore.loadingLocation')}</p>
      </div>
    )
  }

  if (gpsState === 'denied') {
    return (
      <div className="flex flex-col items-center justify-center h-[360px] border rounded-lg gap-4">
        <MapPin className="h-12 w-12 text-muted-foreground" />
        <p className="text-muted-foreground">{t('user.dashboard.explore.noGps')}</p>
        <Button onClick={() => {
          navigator.geolocation.getCurrentPosition(
            pos => {
              setPosition({ lat: pos.coords.latitude, lng: pos.coords.longitude })
              setGpsState('ready')
            },
            () => setGpsState('denied')
          )
        }}>
          {t('user.dashboard.explore.enableGps')}
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <PoiTypeFilter types={poiTypes} selected={selectedTypes} onChange={setSelectedTypes} />
      <div ref={containerRef} className="h-[360px] w-full rounded-lg border" />
      {pois.length === 0 && (
        <p className="text-sm text-muted-foreground">{t('user.dashboard.explore.noNearby')}</p>
      )}
      <PlaceDetailSheet
        place={selectedPoi ? { ...selectedPoi, city_slug: selectedPoi.city_slug } : null}
        open={!!selectedPoi}
        onClose={() => setSelectedPoi(null)}
      />
    </div>
  )
}
