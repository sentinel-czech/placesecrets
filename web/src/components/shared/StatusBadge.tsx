import { Badge } from '@/components/ui/badge'

const statusVariants: Record<string, string> = {
  completed: 'bg-green-100 text-green-800 hover:bg-green-100',
  pending: 'bg-yellow-100 text-yellow-800 hover:bg-yellow-100',
  refunded: 'bg-red-100 text-red-800 hover:bg-red-100',
  disputed: 'bg-orange-100 text-orange-800 hover:bg-orange-100',
}

export function StatusBadge({ status }: { status: string }) {
  return (
    <Badge variant="secondary" className={statusVariants[status] || ''}>
      {status}
    </Badge>
  )
}

export function ActiveBadge({ active }: { active: boolean }) {
  return (
    <Badge variant="secondary" className={active ? 'bg-green-100 text-green-800 hover:bg-green-100' : 'bg-zinc-100 text-zinc-500 hover:bg-zinc-100'}>
      {active ? 'Active' : 'Inactive'}
    </Badge>
  )
}

export function VerifiedBadge({ verified }: { verified: boolean }) {
  return (
    <Badge variant="secondary" className={verified ? 'bg-blue-100 text-blue-800 hover:bg-blue-100' : 'bg-orange-100 text-orange-800 hover:bg-orange-100'}>
      {verified ? 'Verified' : 'Pending'}
    </Badge>
  )
}
