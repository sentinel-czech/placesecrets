import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useEffect } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { Toaster } from '@/components/ui/sonner'

import { AdminGuard } from '@/components/layout/AdminGuard'
import { AccountGuard } from '@/components/layout/AccountGuard'
import { AppShell } from '@/components/layout/AppShell'
import { AccountShell } from '@/components/layout/AccountShell'

import LandingPage from '@/pages/LandingPage'
import LoginPage from '@/pages/LoginPage'
import RegisterPage from '@/pages/RegisterPage'
import ForgotPasswordPage from '@/pages/ForgotPasswordPage'
import ResetPasswordPage from '@/pages/ResetPasswordPage'
import TermsPage from '@/pages/legal/TermsPage'
import PrivacyPage from '@/pages/legal/PrivacyPage'
import AboutPage from '@/pages/legal/AboutPage'
import ContactPage from '@/pages/legal/ContactPage'
import FaqPage from '@/pages/legal/FaqPage'
import AdminPinPage from '@/pages/AdminPinPage'
import ForceChangePinPage from '@/pages/ForceChangePinPage'
import UnauthorizedPage from '@/pages/UnauthorizedPage'
import ContributorRegisterPage from '@/pages/register/ContributorRegisterPage'
import PlaceDetailPage from '@/pages/PlaceDetailPage'
import CityPricingPage from '@/pages/cities/CityPricingPage'
import PurchasesOverviewPage from '@/pages/purchases/PurchasesOverviewPage'

import DashboardPage from '@/pages/DashboardPage'
import CitiesPage from '@/pages/cities/CitiesPage'
import CityNewPage from '@/pages/cities/CityNewPage'
import CityEditPage from '@/pages/cities/CityEditPage'
import PoisPage from '@/pages/pois/PoisPage'
import PoiNewPage from '@/pages/pois/PoiNewPage'
import PoiEditPage from '@/pages/pois/PoiEditPage'
import PoiTypesPage from '@/pages/poi-types/PoiTypesPage'
import UsersPage from '@/pages/users/UsersPage'
import UserDetailPage from '@/pages/users/UserDetailPage'
import PaymentsPage from '@/pages/payments/PaymentsPage'
import PaymentDetailPage from '@/pages/payments/PaymentDetailPage'
import ContributorsPage from '@/pages/contributors/ContributorsPage'
import ContributorDetailPage from '@/pages/contributors/ContributorDetailPage'
import HallOfFamePage from '@/pages/hall-of-fame/HallOfFamePage'
import SettingsPage from '@/pages/SettingsPage'
import LandingConfigPage from '@/pages/LandingConfigPage'
import AclManagementPage from '@/pages/AclManagementPage'

import MyPoisPage from '@/pages/my-pois/MyPoisPage'
import MyPoiEditorPage from '@/pages/my-pois/MyPoiEditorPage'
import AdminProfilePage from '@/pages/AdminProfilePage'

import AccountExplorePage from '@/pages/account/AccountExplorePage'
import AccountHistoryPage from '@/pages/account/AccountHistoryPage'
import AccountProfilePage from '@/pages/account/AccountProfilePage'
import SearchPage from '@/pages/account/SearchPage'
import CitiesCatalogPage from '@/pages/account/CitiesCatalogPage'
import CityPlacesPage from '@/pages/account/CityPlacesPage'

export default function App() {
  const initialize = useAuthStore(s => s.initialize)

  useEffect(() => {
    initialize()
  }, [initialize])

  return (
    <BrowserRouter>
      <Routes>
        {/* Public routes */}
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/terms" element={<TermsPage />} />
        <Route path="/privacy" element={<PrivacyPage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/contact" element={<ContactPage />} />
        <Route path="/faq" element={<FaqPage />} />
        <Route path="/unauthorized" element={<UnauthorizedPage />} />
        <Route path="/register/contributor" element={<ContributorRegisterPage />} />
        <Route path="/:countryCode/:citySlug/:poiSlug" element={<PlaceDetailPage />} />

        {/* Force change PIN (outside admin shell, needs its own layout) */}
        <Route path="/admin/force-change-pin" element={<ForceChangePinPage />} />

        {/* Admin routes (all roles including contributor) */}
        <Route element={<AdminGuard />}>
          <Route element={<AppShell />}>
            <Route path="/admin/dashboard" element={<DashboardPage />} />
            <Route path="/admin/cities" element={<CitiesPage />} />
            <Route path="/admin/cities/new" element={<CityNewPage />} />
            <Route path="/admin/cities/:id" element={<CityEditPage />} />
            <Route path="/admin/cities/:cityId/pois" element={<PoisPage />} />
            <Route path="/admin/cities/:cityId/pois/new" element={<PoiNewPage />} />
            <Route path="/admin/cities/:cityId/pois/:poiId" element={<PoiEditPage />} />
            <Route path="/admin/cities/:cityId/pricing" element={<CityPricingPage />} />
            <Route path="/admin/purchases/premium" element={<PurchasesOverviewPage />} />
            <Route path="/admin/poi-types" element={<PoiTypesPage />} />
            <Route path="/admin/users" element={<UsersPage />} />
            <Route path="/admin/users/:id" element={<UserDetailPage />} />
            <Route path="/admin/payments" element={<PaymentsPage />} />
            <Route path="/admin/payments/:id" element={<PaymentDetailPage />} />
            <Route path="/admin/contributors" element={<ContributorsPage />} />
            <Route path="/admin/contributors/:id" element={<ContributorDetailPage />} />
            <Route path="/admin/hall-of-fame" element={<HallOfFamePage />} />
            <Route path="/admin/settings" element={<SettingsPage />} />
            <Route path="/admin/landing" element={<LandingConfigPage />} />
            <Route path="/admin/acl" element={<AclManagementPage />} />
            <Route path="/admin/my-pois" element={<MyPoisPage />} />
            <Route path="/admin/my-pois/new" element={<MyPoiEditorPage />} />
            <Route path="/admin/my-pois/:poiId" element={<MyPoiEditorPage />} />
            <Route path="/admin/profile" element={<AdminProfilePage />} />
          </Route>
        </Route>

        {/* Account routes (regular users) */}
        <Route element={<AccountGuard />}>
          <Route element={<AccountShell />}>
            <Route path="/account/explore" element={<AccountExplorePage />} />
            <Route path="/account/search" element={<SearchPage />} />
            <Route path="/account/cities" element={<CitiesCatalogPage />} />
            <Route path="/account/cities/:countryCode/:citySlug" element={<CityPlacesPage />} />
            <Route path="/account/history" element={<AccountHistoryPage />} />
            <Route path="/account/profile" element={<AccountProfilePage />} />
            <Route path="/admin-pin" element={<AdminPinPage />} />
          </Route>
        </Route>

        {/* Redirects from old contributor routes */}
        <Route path="/contributor/dashboard" element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="/contributor/pois" element={<Navigate to="/admin/my-pois" replace />} />
        <Route path="/contributor/pois/new" element={<Navigate to="/admin/my-pois/new" replace />} />
        <Route path="/contributor/pois/:poiId" element={<Navigate to="/admin/my-pois/:poiId" replace />} />
        <Route path="/contributor/profile" element={<Navigate to="/admin/profile" replace />} />

        {/* Redirects from old account routes */}
        <Route path="/account/dashboard" element={<Navigate to="/account/explore" replace />} />
        <Route path="/account/receipts" element={<Navigate to="/account/profile?tab=purchases" replace />} />
        <Route path="/account/settings" element={<Navigate to="/account/profile?tab=settings" replace />} />

        {/* Catch-all redirect */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <Toaster />
    </BrowserRouter>
  )
}
