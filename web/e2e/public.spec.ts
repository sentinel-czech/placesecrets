import { test, expect } from '@playwright/test'

// Public, backend-light flows. These render and validate client-side without a
// live Supabase backend (network calls fail gracefully). Authenticated flows
// (purchase, OAuth, admin) require a test Supabase project + credentials and are
// out of scope for CI — see RELEASE-CHECKLIST.md.

test('landing page renders with hero and primary navigation', async ({ page }) => {
  await page.goto('/')
  // Hero CTA links to login/register exist somewhere on the page.
  await expect(page.locator('a[href="/login"]').first()).toBeVisible()
  await expect(page).toHaveTitle(/place\s*secrets/i)
})

test('cookie consent banner appears and can be dismissed', async ({ page }) => {
  await page.goto('/')
  const accept = page.getByRole('button', { name: /got it/i })
  await expect(accept).toBeVisible()
  await accept.click()
  await expect(accept).toBeHidden()
  // Stays dismissed after reload (persisted in localStorage).
  await page.reload()
  await expect(page.getByRole('button', { name: /got it/i })).toHaveCount(0)
})

test('login page shows email and password fields', async ({ page }) => {
  await page.goto('/login')
  await expect(page.locator('input[type="email"]')).toBeVisible()
  await expect(page.locator('input[type="password"]')).toBeVisible()
})

test('registration requires accepting terms (consent checkbox present)', async ({ page }) => {
  await page.goto('/register')
  await expect(page.locator('input[type="checkbox"]').first()).toBeVisible()
})

test('legal pages load', async ({ page }) => {
  await page.goto('/terms')
  await expect(page.locator('h1, h2').first()).toBeVisible()
  await page.goto('/privacy')
  await expect(page.locator('h1, h2').first()).toBeVisible()
})
