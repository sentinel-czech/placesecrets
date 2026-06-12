import { Link } from 'react-router-dom'
import { Logo } from '@/components/brand/Logo'

export function PublicFooter() {
  return (
    <footer className="border-t border-border bg-[#1A1A2E] py-12 text-white">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid gap-8 sm:grid-cols-3">
          <div>
            <div className="mb-3">
              <Logo variant="full" theme="dark" className="w-40" />
            </div>
            <p className="text-sm text-white/50">
              Your personal audio guide to hidden stories behind every place.
            </p>
          </div>

          <div>
            <h4 className="font-semibold mb-3 text-sm">Explore</h4>
            <nav className="flex flex-col gap-2 text-sm text-white/50">
              <a href="/#explore" className="transition-colors hover:text-white">Map</a>
              <a href="/#how-it-works" className="transition-colors hover:text-white">How It Works</a>
              <a href="/#download" className="transition-colors hover:text-white">Download App</a>
              <Link to="/register/contributor" className="transition-colors hover:text-white">Become a Contributor</Link>
            </nav>
          </div>

          <div>
            <h4 className="font-semibold mb-3 text-sm">Legal</h4>
            <nav className="flex flex-col gap-2 text-sm text-white/50">
              <a href="#" className="transition-colors hover:text-white">Privacy Policy</a>
              <a href="#" className="transition-colors hover:text-white">Terms of Service</a>
              <a href="#" className="transition-colors hover:text-white">Contact</a>
            </nav>
          </div>
        </div>

        <div className="mt-8 border-t border-white/10 pt-8 text-center text-sm text-white/30">
          &copy; {new Date().getFullYear()} Place<span className="text-gold">Secrets</span>. All rights reserved.
        </div>
      </div>
    </footer>
  )
}
