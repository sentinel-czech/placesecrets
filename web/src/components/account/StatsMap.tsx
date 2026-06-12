import { useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { format } from 'date-fns'
import { escapeHtml, DATE_FORMAT } from '@/lib/utils'

interface VisitMarker {
  id: string
  poi_name: string
  latitude: number
  longitude: number
  visited_at: string
  color_hex: string
  city_slug: string | null
  poi_slug: string | null
  country_code: string | null
}

interface StatsMapProps {
  visits: VisitMarker[]
}

const SLUG_RE = /^[a-z0-9-]+$/

export function StatsMap({ visits }: StatsMapProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const { t } = useTranslation()
  const navigate = useNavigate()

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return

    mapRef.current = L.map(containerRef.current, {
      scrollWheelZoom: true,
    }).setView([50, 14], 5)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(mapRef.current)

    return () => {
      mapRef.current?.remove()
      mapRef.current = null
    }
  }, [])

  useEffect(() => {
    if (!mapRef.current) return

    // Clear existing markers
    mapRef.current.eachLayer(layer => {
      if (layer instanceof L.CircleMarker) mapRef.current!.removeLayer(layer)
    })

    if (visits.length === 0) return

    const bounds: [number, number][] = []
    visits.forEach(v => {
      const marker = L.circleMarker([v.latitude, v.longitude], {
        radius: 7,
        fillColor: v.color_hex || '#2D6A4F',
        color: v.color_hex || '#2D6A4F',
        fillOpacity: 0.8,
        weight: 2,
      })

      const dateStr = format(new Date(v.visited_at), DATE_FORMAT)
      const safeName = escapeHtml(v.poi_name)
      const safeDate = escapeHtml(t('user.dashboard.stats.visitedOn', { date: dateStr }))
      marker.bindTooltip(`${safeName}<br/>${safeDate}`)

      if (v.country_code && v.city_slug && v.poi_slug && SLUG_RE.test(v.city_slug) && SLUG_RE.test(v.poi_slug)) {
        marker.on('click', () => {
          navigate(`/${v.country_code!.toLowerCase()}/${v.city_slug}/${v.poi_slug}`)
        })
      }

      marker.addTo(mapRef.current!)
      bounds.push([v.latitude, v.longitude])
    })

    if (bounds.length > 0) {
      mapRef.current.fitBounds(bounds, { padding: [30, 30] })
    }
  }, [visits, t])

  return (
    <div ref={containerRef} className="h-[360px] w-full rounded-lg border" />
  )
}
