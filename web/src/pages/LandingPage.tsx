import { Suspense, lazy, useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { MapPin, Headphones, Star, ArrowRight, Smartphone, Download, Search } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { SocialAuthButtons } from '@/components/auth/SocialAuthButtons'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { PublicFooter } from '@/components/layout/PublicFooter'

const LandingMapSection = lazy(() => import('@/components/landing/LandingMapSection'))

const EXAMPLE_POIS = [
  { name: 'Karlův most', nameEn: 'Charles Bridge', city: 'Prague', lat: 50.0865, lng: 14.4114, desc: 'Iconic medieval stone bridge crossing the Vltava river, adorned with 30 baroque statues.' },
  { name: 'Staroměstské náměstí', nameEn: 'Old Town Square', city: 'Prague', lat: 50.0875, lng: 14.4213, desc: 'Historic square in the heart of Prague\'s Old Town, home to the Astronomical Clock.' },
  { name: 'Náměstí Republiky', nameEn: 'Republic Square', city: 'Plzeň', lat: 49.7474, lng: 13.3776, desc: 'The main square of Plzeň, one of the largest in Europe.' },
  { name: 'Katedrála sv. Bartoloměje', nameEn: 'St. Bartholomew Cathedral', city: 'Plzeň', lat: 49.7472, lng: 13.3775, desc: 'Gothic cathedral with one of the tallest church steeples in Central Europe.' },
  { name: 'Katedrála sv. Petra a Pavla', nameEn: 'Cathedral of St. Peter and Paul', city: 'Brno', lat: 49.1913, lng: 16.6073, desc: 'Dominant landmark of Brno, a national cultural monument on Petrov hill.' },
]

const TESTIMONIALS = [
  { name: 'Jan N.', text: 'The audio guides are fantastic. I discovered places in my own city I never knew existed!', city: 'Prague' },
  { name: 'Marie K.', text: 'Perfect for weekend trips. The stories behind each place make visiting so much more meaningful.', city: 'Brno' },
  { name: 'Peter V.', text: 'As a contributor, it is amazing to share local secrets with travelers from around the world.', city: 'Plzeň' },
]

export default function LandingPage() {
  const { t } = useTranslation()
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const [cityCount, setCityCount] = useState(0)
  const [poiCount, setPoiCount] = useState(0)

  useEffect(() => {
    async function loadStats() {
      const [citiesRes, poisRes] = await Promise.all([
        supabase.from('cities').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('pois').select('id', { count: 'exact', head: true }).eq('is_active', true),
      ])
      if (citiesRes.count) setCityCount(citiesRes.count)
      if (poisRes.count) setPoiCount(poisRes.count)
    }
    loadStats()
  }, [])

  return (
    <div className="min-h-screen flex flex-col">
      <PublicHeader />

      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-br from-[#1A1A2E] via-[#16213E] to-[#0F3460] py-20 sm:py-28 lg:py-36 text-white">
        {/* Animated dots background */}
        <div className="absolute inset-0 -z-0 opacity-20" style={{
          backgroundImage: 'radial-gradient(circle at 2px 2px, rgba(255,255,255,0.3) 1px, transparent 0)',
          backgroundSize: '48px 48px',
        }} />
        {/* Gradient orbs */}
        <div className="absolute top-20 left-10 w-72 h-72 bg-primary/20 rounded-full blur-3xl" />
        <div className="absolute bottom-10 right-10 w-96 h-96 bg-[#B8960C]/15 rounded-full blur-3xl" />

        <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-3xl text-center">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-sm font-medium backdrop-blur-sm">
              <Headphones className="h-4 w-4" />
              {t('landing.tagline')}
            </div>
            <h1 className="text-4xl font-bold tracking-tight sm:text-5xl lg:text-6xl">
              {t('landing.heroTitle1')}{' '}
              <span className="bg-gradient-to-r from-[#2D6A4F] to-[#40916C] bg-clip-text text-transparent">
                {t('landing.heroTitle2')}
              </span>
              <br />
              {t('landing.heroTitle3')}
            </h1>
            <p className="mx-auto mt-6 max-w-2xl text-lg text-white/70 sm:text-xl">
              {t('landing.heroSubtitle')}
            </p>
            <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4">
              <a href="#explore">
                <Button size="lg" className="gap-2 px-8 py-3 text-base bg-primary hover:bg-primary/90">
                  <Search className="h-5 w-5" />
                  {t('landing.explorePlaces')}
                </Button>
              </a>
              {!user && (
                <Link to="/register">
                  <Button variant="outline" size="lg" className="gap-2 px-8 py-3 text-base border-white/30 bg-white/10 text-white hover:bg-white/20 hover:text-white">
                    <ArrowRight className="h-5 w-5" />
                    {t('landing.getStartedFree')}
                  </Button>
                </Link>
              )}
            </div>

            {/* Stats */}
            <div className="mt-16 grid grid-cols-3 gap-8 border-t border-white/10 pt-8">
              <div>
                <div className="text-3xl font-bold">{cityCount || '10+'}</div>
                <div className="text-sm text-white/50">{t('landing.cities')}</div>
              </div>
              <div>
                <div className="text-3xl font-bold">{poiCount || '100+'}</div>
                <div className="text-sm text-white/50">{t('landing.places')}</div>
              </div>
              <div>
                <div className="text-3xl font-bold flex items-center justify-center gap-1">
                  <Headphones className="h-6 w-6" />
                  HD
                </div>
                <div className="text-sm text-white/50">{t('landing.audioGuides')}</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Map Preview Section */}
      <section id="explore" className="bg-white py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              {t('landing.exploreAround')}
            </h2>
            <p className="mx-auto mt-4 max-w-2xl text-muted-foreground">
              {t('landing.exploreAroundDesc')}
            </p>
          </div>

          <div className="mt-10 overflow-hidden rounded-xl ring-1 ring-foreground/10 shadow-lg">
            <Suspense fallback={
              <div className="flex h-[400px] items-center justify-center bg-muted/30 sm:h-[500px]">
                <div className="flex flex-col items-center gap-3 text-muted-foreground">
                  <MapPin className="h-8 w-8 animate-pulse" />
                  <span>{t('landing.loadingMap')}</span>
                </div>
              </div>
            }>
              <LandingMapSection pois={EXAMPLE_POIS} />
            </Suspense>
          </div>

          {!user && (
            <div className="mt-8 flex flex-col items-center gap-4">
              <p className="text-sm text-muted-foreground">
                {t('landing.signInToExplore')}
              </p>
              <div className="flex items-center gap-3">
                <SocialAuthButtons compact />
                <span className="text-xs text-muted-foreground">{t('landing.or')}</span>
                <Link to="/register">
                  <Button variant="outline" size="sm">
                    {t('landing.registerWithEmail')}
                  </Button>
                </Link>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Featured POI Cards */}
      <section className="bg-muted/30 py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              {t('landing.featuredPlaces')}
            </h2>
            <p className="mx-auto mt-4 max-w-2xl text-muted-foreground">
              {t('landing.featuredPlacesDesc')}
            </p>
          </div>

          <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                name: 'Karlův most',
                nameEn: 'Charles Bridge',
                city: 'Prague',
                rating: 4.8,
                reviews: 237,
                access: 'city_access',
                desc: 'Medieval stone bridge crossing the Vltava river, adorned with 30 baroque statues.',
              },
              {
                name: 'Katedrála sv. Bartoloměje',
                nameEn: 'St. Bartholomew Cathedral',
                city: 'Plzeň',
                rating: 4.6,
                reviews: 89,
                access: 'public',
                desc: 'Gothic cathedral with one of the tallest church steeples in Central Europe at 102.6m.',
              },
              {
                name: 'Katedrála sv. Petra a Pavla',
                nameEn: 'Cathedral of St. Peter and Paul',
                city: 'Brno',
                rating: 4.7,
                reviews: 152,
                access: 'premium_poi',
                desc: 'Dominant landmark of Brno, a national cultural monument on Petrov hill.',
              },
            ].map(poi => (
              <div key={poi.name} className="overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10 transition-all hover:shadow-lg hover:-translate-y-0.5">
                <div className="relative h-40 bg-gradient-to-br from-primary/20 via-primary/10 to-[#B8960C]/20">
                  <div className="absolute inset-0 flex items-center justify-center">
                    <MapPin className="h-12 w-12 text-primary/30" />
                  </div>
                  <div className="absolute bottom-3 right-3">
                    {poi.access === 'public' && (
                      <span className="inline-flex items-center rounded-full bg-green-600/90 px-3 py-1 text-xs font-semibold text-white">{t('landing.free')}</span>
                    )}
                    {poi.access === 'city_access' && (
                      <span className="inline-flex items-center rounded-full bg-orange-500/90 px-3 py-1 text-xs font-semibold text-white">{t('landing.cityPass')}</span>
                    )}
                    {poi.access === 'premium_poi' && (
                      <span className="inline-flex items-center rounded-full bg-amber-500/90 px-3 py-1 text-xs font-semibold text-white">{t('landing.premium')}</span>
                    )}
                  </div>
                </div>

                <div className="p-5">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="font-bold text-foreground">{poi.name}</h3>
                      <p className="text-xs text-muted-foreground">{poi.nameEn}</p>
                    </div>
                    <div className="flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1">
                      <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                      <span className="text-sm font-semibold text-foreground">{poi.rating}</span>
                    </div>
                  </div>

                  <div className="mt-1 flex items-center gap-1.5 text-xs text-muted-foreground">
                    <MapPin className="h-3 w-3" />
                    <span>{poi.city}</span>
                    <span className="mx-0.5">·</span>
                    <span>{poi.reviews} {t('landing.reviews')}</span>
                  </div>

                  <p className="mt-3 text-sm leading-relaxed text-muted-foreground line-clamp-2">{poi.desc}</p>

                  <div className="mt-4">
                    <Link to="/login">
                      <Button size="sm" variant="outline" className="w-full gap-2">
                        <Headphones className="h-3.5 w-3.5" />
                        {t('landing.listenToGuide')}
                      </Button>
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="bg-white py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              {t('landing.howItWorks')}
            </h2>
            <p className="mx-auto mt-4 max-w-2xl text-muted-foreground">
              {t('landing.howItWorksDesc')}
            </p>
          </div>

          <div className="mt-12 grid gap-8 sm:grid-cols-3">
            {[
              {
                step: '01',
                icon: Search,
                title: t('landing.step1Title'),
                description: t('landing.step1Desc'),
                color: 'bg-primary/10 text-primary',
              },
              {
                step: '02',
                icon: Headphones,
                title: t('landing.step2Title'),
                description: t('landing.step2Desc'),
                color: 'bg-[#B8960C]/10 text-[#B8960C]',
              },
              {
                step: '03',
                icon: Star,
                title: t('landing.step3Title'),
                description: t('landing.step3Desc'),
                color: 'bg-blue-500/10 text-blue-500',
              },
            ].map((item) => (
              <div key={item.title} className="group relative flex flex-col items-center rounded-xl border border-transparent p-6 text-center transition-all hover:border-border hover:bg-muted/30 hover:shadow-sm">
                <div className="absolute -top-3 left-6 text-5xl font-black text-muted-foreground/10">
                  {item.step}
                </div>
                <div className={`flex h-14 w-14 items-center justify-center rounded-xl ${item.color}`}>
                  <item.icon className="h-7 w-7" />
                </div>
                <h3 className="mt-5 text-lg font-semibold text-foreground">{item.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{item.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="bg-muted/30 py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              {t('landing.whatPeopleSay')}
            </h2>
          </div>
          <div className="grid gap-6 sm:grid-cols-3">
            {TESTIMONIALS.map(tm => (
              <div key={tm.name} className="rounded-xl bg-card p-6 ring-1 ring-foreground/5">
                <div className="flex gap-1 mb-3">
                  {[1, 2, 3, 4, 5].map(i => (
                    <Star key={i} className="h-4 w-4 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <p className="text-sm leading-relaxed text-muted-foreground italic">"{tm.text}"</p>
                <div className="mt-4 flex items-center gap-2">
                  <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-xs font-bold text-primary">
                    {tm.name.charAt(0)}
                  </div>
                  <div>
                    <p className="text-sm font-medium">{tm.name}</p>
                    <p className="text-xs text-muted-foreground">{tm.city}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-br from-[#1A1A2E] to-[#0F3460] py-16 sm:py-20 text-white">
        <div className="mx-auto max-w-3xl px-4 text-center sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            {t('landing.readyToExplore')}
          </h2>
          <p className="mt-4 text-lg text-white/70">
            {t('landing.readyToExploreDesc')}
          </p>
          <div className="mt-8 flex flex-col items-center gap-4">
            {user ? (
              <Button size="lg" className="gap-2 px-8 bg-primary hover:bg-primary/90" onClick={() => navigate('/account/explore')}>
                {t('landing.goToDashboard')}
                <ArrowRight className="h-5 w-5" />
              </Button>
            ) : (
              <>
                <div className="flex items-center gap-3">
                  <SocialAuthButtons compact />
                </div>
                <p className="text-sm text-white/50">{t('landing.or')}</p>
                <Link to="/register">
                  <Button size="lg" variant="outline" className="gap-2 px-8 border-white/30 bg-white/10 text-white hover:bg-white/20 hover:text-white">
                    {t('landing.registerWithEmailCta')}
                    <ArrowRight className="h-5 w-5" />
                  </Button>
                </Link>
              </>
            )}
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" className="bg-white py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <Smartphone className="mx-auto h-12 w-12 text-primary" />
            <h2 className="mt-4 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              Take Place<span className="text-gold">Secrets</span> With You
            </h2>
            <p className="mt-4 text-muted-foreground">
              {t('landing.downloadDesc')}
            </p>

            <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4">
              <button
                disabled
                className="inline-flex h-14 w-52 items-center justify-center gap-3 rounded-xl bg-foreground/90 px-5 text-white opacity-60 cursor-not-allowed"
              >
                <Download className="h-6 w-6" />
                <div className="text-left">
                  <div className="text-[10px] uppercase leading-tight tracking-wide">{t('landing.getItOn')}</div>
                  <div className="text-sm font-semibold leading-tight">{t('landing.googlePlay')}</div>
                </div>
              </button>
              <button
                disabled
                className="inline-flex h-14 w-52 items-center justify-center gap-3 rounded-xl bg-foreground/90 px-5 text-white opacity-60 cursor-not-allowed"
              >
                <Download className="h-6 w-6" />
                <div className="text-left">
                  <div className="text-[10px] uppercase leading-tight tracking-wide">{t('landing.downloadOnThe')}</div>
                  <div className="text-sm font-semibold leading-tight">{t('landing.appStore')}</div>
                </div>
              </button>
            </div>
            <p className="mt-3 text-xs text-muted-foreground">{t('landing.comingSoon')}</p>
          </div>
        </div>
      </section>

      <PublicFooter />
    </div>
  )
}
