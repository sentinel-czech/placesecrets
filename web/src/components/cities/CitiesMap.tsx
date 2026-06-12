import { useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet.markercluster'
import 'leaflet.markercluster/dist/MarkerCluster.css'
import 'leaflet.markercluster/dist/MarkerCluster.Default.css'
import type { City } from '@/lib/supabase/types'
import { escapeHtml } from '@/lib/utils'

interface CitiesMapProps {
  cities: City[]
}

export function CitiesMap({ cities }: CitiesMapProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const clusterRef = useRef<L.MarkerClusterGroup | null>(null)
  const navigate = useNavigate()
  const { t } = useTranslation()

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return

    mapRef.current = L.map(containerRef.current, {
      scrollWheelZoom: true,
      zoomControl: true,
    }).setView([50, 14], 5)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(mapRef.current)

    clusterRef.current = L.markerClusterGroup()
    mapRef.current.addLayer(clusterRef.current)

    return () => {
      mapRef.current?.remove()
      mapRef.current = null
      clusterRef.current = null
    }
  }, [])

  useEffect(() => {
    if (!clusterRef.current || !mapRef.current) return
    clusterRef.current.clearLayers()

    if (cities.length === 0) return

    const bounds: L.LatLngBoundsExpression = []
    cities.forEach(city => {
      const color = city.is_active ? '#2D6A4F' : '#9CA3AF'
      const marker = L.circleMarker([city.latitude, city.longitude], {
        radius: 8,
        fillColor: color,
        color: color,
        fillOpacity: 0.8,
        weight: 2,
      })
      marker.bindTooltip(escapeHtml(city.name))
      marker.on('click', () => navigate(`/admin/cities/${city.id}`))
      clusterRef.current!.addLayer(marker)
      ;(bounds as [number, number][]).push([city.latitude, city.longitude])
    })

    if ((bounds as [number, number][]).length > 0) {
      mapRef.current.fitBounds(bounds as L.LatLngBoundsExpression, { padding: [30, 30] })
    }
  }, [cities, navigate, t])

  return (
    <div
      ref={containerRef}
      className="h-[360px] w-full rounded-lg border"
    />
  )
}
