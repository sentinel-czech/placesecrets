interface MaterialIconProps {
  name: string
  className?: string
  style?: React.CSSProperties
}

export function MaterialIcon({ name, className = '', style }: MaterialIconProps) {
  return (
    <span className={`material-icons ${className}`} style={style}>
      {name}
    </span>
  )
}
