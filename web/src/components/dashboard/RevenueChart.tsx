import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { RevenueByMonth } from '@/lib/supabase/types'

interface RevenueChartProps {
  data: RevenueByMonth[]
}

export function RevenueChart({ data }: RevenueChartProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Příjmy (EUR)</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={250}>
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" fontSize={12} label={{ value: 'Měsíc', position: 'insideBottom', offset: -5, fontSize: 11 }} />
            <YAxis fontSize={12} />
            <Tooltip formatter={(value) => [`${value} EUR`, 'Příjmy']} labelFormatter={(label) => `Měsíc: ${label}`} />
            <Bar dataKey="revenue" name="Příjmy" fill="oklch(0.44 0.1 160)" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
