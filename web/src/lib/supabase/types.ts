export interface Country {
  code: string
  name: string
  aliases: string[]
  created_at: string
  updated_at: string
}

export interface City {
  id: string
  name: string
  country_code: string
  latitude: number
  longitude: number
  bounding_box_radius_km: number
  price_eur: number
  is_active: boolean
  slug: string | null
  registered_sample_poi_id: string | null
  premium_bundle_price: number | null
  aliases: string[]
  created_at: string
  updated_at: string
}

export type PoiAccessLevel = 'public' | 'registered' | 'city_access' | 'premium_poi'

export interface Poi {
  id: string
  city_id: string
  type_id: string | null
  name: Record<string, string>
  description: Record<string, string>
  latitude: number
  longitude: number
  geofence_radius: number
  photo_urls: string[]
  audio_urls: Record<string, string>
  is_premium: boolean
  sort_order: number
  is_active: boolean
  contributor_id: string | null
  contributor_note: string | null
  avg_rating: number | null
  total_ratings: number
  slug: string | null
  access_level: PoiAccessLevel
  perex: Record<string, string> | null
  premium_price: number | null
  aliases: string[]
  created_at: string
  updated_at: string
  city?: City
  poi_type?: PoiType
}

export interface PoiType {
  id: string
  name: Record<string, string>
  slug: string
  icon_name: string
  color_hex: string
  sort_order: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface AdminUser {
  id: string
  user_id: string
  role: 'superadmin' | 'editor' | 'viewer' | 'contributor'
  pin_hash: string | null
  pin_set_at: string | null
  created_at: string
}

export interface PaymentReceipt {
  id: string
  user_id: string
  city_id: string
  purchased_at: string
  payment_method: string
  transaction_id: string | null
  amount_eur: number
  currency: string
  status: 'pending' | 'completed' | 'refunded' | 'disputed'
  revolut_note: string | null
  confirmed_by: string | null
  confirmed_at: string | null
  receipt_number: string | null
  receipt_pdf_url: string | null
  receipt_sent_at: string | null
  created_at: string
  city?: City
}

export interface UserAccess {
  id: string
  user_id: string
  city_id: string
  purchased_at: string
  valid_until: string | null
  payment_method: string
  transaction_id: string | null
  amount_eur: number | null
}

export interface ContributorProfile {
  id: string
  user_id: string
  display_name: string
  bio: string | null
  avatar_url: string | null
  website_url: string | null
  specializations: string[]
  total_pois: number
  avg_rating: number | null
  total_ratings: number
  is_verified: boolean
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface PoiRating {
  id: string
  poi_id: string
  user_id: string | null
  device_id: string | null
  rating: number
  reason: string | null
  comment: string | null
  is_hidden: boolean
  lang_code: string
  created_at: string
}

export interface AdminStats {
  registered_users: number
  anonymous_users: number
  active_pois: number
  active_cities: number
  total_purchases: number
  total_revenue_eur: number
  free_visits_this_month: number
  pending_revolut: number
  total_contributors: number
  verified_contributors: number
  total_poi_ratings: number
  global_avg_rating: number | null
}

export interface AdminUserView {
  id: string
  email: string
  is_anonymous: boolean
  created_at: string
  last_sign_in_at: string | null
  email_confirmed_at: string | null
  access_count: number
  total_spent: number
  status: 'active' | 'deactivated'
  language: string
  user_number: number | null
  backup_email: string | null
  display_name: string | null
}

export interface RevenueByMonth {
  month: string
  revenue: number
  count: number
}

export interface DailyActivity {
  day: string
  visits: number
  new_users: number
}

export interface PaymentConfig {
  id: string
  operator_name: string
  revolut_username: string | null
  revolut_iban: string | null
  stripe_publishable_key: string | null
  stripe_secret_key: string | null
  google_pay_merchant_id: string | null
  apple_pay_merchant_id: string | null
  free_pois_per_month: number
  max_geofences: number
  max_photo_size_mb: number
  max_audio_size_mb: number
  admin_pin_attempts: number
  admin_pin_lockout_minutes: number
  receipt_prefix: string
  updated_at: string
}

export interface HallOfFameEntry {
  rank: number
  contributor_id: string
  display_name: string
  avatar_url: string | null
  is_verified: boolean
  city_poi_count: number
  city_avg_rating: number
  city_total_ratings: number
  hof_score: number
  sample_poi_names: Record<string, string>[]
}

export interface PoiTypeStats {
  type_id: string
  type_name: Record<string, string>
  slug: string
  icon_name: string
  color_hex: string
  poi_count: number
}

export interface PoiPremiumContent {
  id: string
  poi_id: string
  audio_url: string | null
  text_content: string | null
  extra_photos: string[]
  related_poi_ids: string[]
  created_at: string
  updated_at: string
}

export interface UserPoiPurchase {
  id: string
  user_id: string
  poi_id: string
  purchased_at: string
  price_paid: number | null
  payment_id: string | null
  stripe_session_id: string | null
}

export interface PoiAudioGuide {
  id: string
  poi_id: string
  lang_code: string
  title: string
  url: string
  duration_sec: number | null
  sort_order: number
  uploaded_by: string | null
  avg_rating: number | null
  total_ratings: number
  created_at: string
  updated_at: string
}

export interface UserAllPurchase {
  purchase_type: 'poi' | 'city_premium' | 'city_access'
  user_id: string
  purchased_at: string
  price_paid: number | null
  payment_id: string | null
  item_id: string
  item_name: string
  item_slug: string | null
  city_slug: string | null
  city_name: string
}
