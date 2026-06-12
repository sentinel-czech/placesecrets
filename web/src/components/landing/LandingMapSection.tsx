import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

// Fix default marker icon (same fix as MapPickerInner)
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

interface Poi {
  name: string
  nameEn: string
  city: string
  lat: number
  lng: number
  desc: string
}

interface LandingMapSectionProps {
  pois: Poi[]
}

export default function LandingMapSection({ pois }: LandingMapSectionProps) {
  return (
    <MapContainer
      center={[49.8, 15.5]}
      zoom={7}
      className="h-[400px] w-full sm:h-[500px]"
      scrollWheelZoom={false}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {pois.map((poi) => (
        <Marker key={`${poi.lat}-${poi.lng}`} position={[poi.lat, poi.lng]}>
          <Popup>
            <div className="min-w-[180px]">
              <p className="text-sm font-bold">{poi.name}</p>
              <p className="text-xs text-gray-500">{poi.nameEn}</p>
              <p className="mt-1 text-xs text-gray-600">{poi.city}</p>
              <p className="mt-1.5 text-xs leading-relaxed">{poi.desc}</p>
            </div>
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  )
}
