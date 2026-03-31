"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Users, Map, Activity, TrendingUp } from "lucide-react"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from "recharts"

const stats = [
  { title: "Total Users", value: "2,543", change: "+12.5%", icon: Users, color: "text-blue-600" },
  { title: "Active Maps", value: "156", change: "+8.2%", icon: Map, color: "text-green-600" },
  { title: "Total Sessions", value: "18,294", change: "+24.1%", icon: Activity, color: "text-purple-600" },
  { title: "Growth Rate", value: "94.2%", change: "+3.4%", icon: TrendingUp, color: "text-orange-600" },
]

const chartData = [
  { name: "Jan", users: 1200, sessions: 2400 },
  { name: "Feb", users: 1900, sessions: 1398 },
  { name: "Mar", users: 3000, sessions: 5800 },
  { name: "Apr", users: 2780, sessions: 3908 },
  { name: "May", users: 3490, sessions: 4800 },
  { name: "Jun", users: 4200, sessions: 3800 },
]

const revenueData = [
  { name: "Mon", revenue: 1000 },
  { name: "Tue", revenue: 1200 },
  { name: "Wed", revenue: 900 },
  { name: "Thu", revenue: 1400 },
  { name: "Fri", revenue: 1800 },
  { name: "Sat", revenue: 1600 },
  { name: "Sun", revenue: 1200 },
]

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Dashboard Overview</h1>
      </div>

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title} className="overflow-hidden">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">{stat.change} from last month</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 grid-cols-1 lg:grid-cols-2">
        <Card className="overflow-hidden">
          <CardHeader>
            <CardTitle>User Growth</CardTitle>
            <CardDescription>Monthly active users</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] sm:h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200" />
                  <XAxis dataKey="name" tick={{fontSize: 12}} />
                  <YAxis tick={{fontSize: 12}} />
                  <Tooltip />
                  <Bar dataKey="users" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card className="overflow-hidden">
          <CardHeader>
            <CardTitle>Weekly Revenue</CardTitle>
            <CardDescription>Daily revenue this week</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] sm:h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200" />
                  <XAxis dataKey="name" tick={{fontSize: 12}} />
                  <YAxis tick={{fontSize: 12}} />
                  <Tooltip />
                  <Line type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
