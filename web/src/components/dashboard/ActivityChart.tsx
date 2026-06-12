import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { DailyActivity } from '@/lib/supabase/types'

interface ActivityChartProps {
  data: DailyActivity[]
}

export function ActivityChart({ data }: ActivityChartProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Denní aktivita</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={250}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="day" fontSize={12} />
            <YAxis fontSize={12} />
            <Tooltip labelFormatter={(label) => `Den: ${label}`} />
            <Legend />
            <Line type="monotone" dataKey="visits" name="Návštěvy" stroke="oklch(0.44 0.1 160)" strokeWidth={2} dot={false} />
            <Line type="monotone" dataKey="new_users" name="Registrace" stroke="oklch(0.62 0.12 90)" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
