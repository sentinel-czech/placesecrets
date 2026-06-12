interface LogoProps {
  variant?: 'full' | 'icon'
  theme?: 'light' | 'dark'
  className?: string
}

export function Logo({ variant = 'full', theme = 'light', className }: LogoProps) {
  const file = variant === 'full'
    ? (theme === 'dark' ? '/logo-dark.svg' : '/logo-light.svg')
    : (theme === 'dark' ? '/icon-dark.svg' : '/icon-light.svg')

  return (
    <img
      src={file}
      alt="PlaceSecrets"
      className={className}
    />
  )
}
