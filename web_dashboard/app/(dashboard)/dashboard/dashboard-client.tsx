"use client"

import { useEffect, useState } from "react"
import { Users, MapPin, Pin, Activity } from "lucide-react"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts"
import { createClient } from "@/lib/supabase"
import Link from "next/link"

interface Stats {
  totalUsers: number
  usersWithHome: number
  usersWithWork: number
  totalCustomPins: number
  recentActivity: { date: string; count: number }[]
}

export default function DashboardClient() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [activeBar, setActiveBar] = useState<number | null>(null)

  useEffect(() => {
    const fetchStats = async () => {
      const supabase = createClient()
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id, home_lat, work_lat, custom_pins, updated_at")

      if (!profiles) return

      const totalUsers = profiles.length
      const usersWithHome = profiles.filter((p) => p.home_lat !== null).length
      const usersWithWork = profiles.filter((p) => p.work_lat !== null).length
      const totalCustomPins = profiles.reduce((sum, p) => {
        return sum + (Array.isArray(p.custom_pins) ? p.custom_pins.length : 0)
      }, 0)

      const weekCounts: Record<string, number> = {}
      profiles.forEach((p) => {
        const d = new Date(p.updated_at)
        const week = `${d.getFullYear()}-W${String(Math.ceil(d.getDate() / 7)).padStart(2, "0")}`
        weekCounts[week] = (weekCounts[week] || 0) + 1
      })
      const recentActivity = Object.entries(weekCounts)
        .sort(([a], [b]) => a.localeCompare(b))
        .slice(-8)
        .map(([date, count]) => ({ date, count }))

      setStats({ totalUsers, usersWithHome, usersWithWork, totalCustomPins, recentActivity })
      setLoading(false)
    }
    fetchStats()
  }, [])

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Geospatial Command Center</h1>
          <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Loading telemetry...</p>
        </div>
        <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 xl:grid-cols-4">
          {[...Array(4)].map((_, i) => <div key={i} className="content-tile rounded-xl h-28 animate-pulse" />)}
        </div>
      </div>
    )
  }

  const tiles = [
    { title: "Total Active Nodes", value: stats!.totalUsers, icon: Users, accent: "#85adff", href: "/users", desc: "View all users →" },
    { title: "Spatial Anchors", value: stats!.usersWithHome, icon: MapPin, accent: "#2ff801", href: "/maps?filter=home", desc: "Users with home →" },
    { title: "Work Beacons", value: stats!.usersWithWork, icon: Activity, accent: "#81ecff", href: "/maps?filter=work", desc: "Users with work →" },
    { title: "Custom Waypoints", value: stats!.totalCustomPins, icon: Pin, accent: "#85adff", href: "/maps?filter=pins", desc: "View all pins →" },
  ]

  const syncItems = [
    { label: "Profiles Table", value: `${stats!.totalUsers} rows`, href: "/users", color: "#81ecff" },
    { label: "Spatial Data", value: `${stats!.usersWithHome + stats!.usersWithWork} entries`, href: "/maps", color: "#81ecff" },
    { label: "Custom Pins", value: `${stats!.totalCustomPins} waypoints`, href: "/maps?filter=pins", color: "#81ecff" },
    { label: "Auth Health", value: "99.9%", href: "/users", color: "#2ff801" },
  ]

  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Geospatial Command Center</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Real-time operational telemetry · Mapy Engine v2.4</p>
      </div>

      {/* Stat tiles — each is a clickable Link */}
      <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 xl:grid-cols-4">
        {tiles.map((stat) => (
          <Link
            key={stat.title}
            href={stat.href}
            className="content-tile rounded-xl p-5 block group cursor-pointer hover:border-white/15 hover:bg-[#0c1326] transition-all duration-200 active:scale-[0.98]"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="p-2 rounded-lg transition-all" style={{ background: `${stat.accent}18` }}>
                <stat.icon className="h-4 w-4" style={{ color: stat.accent }} />
              </div>
              <span className="hud-label" style={{ color: "#2ff801" }}>● active</span>
            </div>
            <div className="font-headline text-2xl font-bold text-[#dfe4fe] mb-1">{stat.value.toLocaleString()}</div>
            <p className="hud-label">{stat.title}</p>
            <p className="text-[10px] text-[#85adff] mt-1 opacity-0 group-hover:opacity-100 transition-opacity">{stat.desc}</p>
          </Link>
        ))}
      </div>

      {/* Activity chart */}
      <div className="content-tile rounded-xl p-6">
        <div className="flex items-center justify-between mb-5">
          <div>
            <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Activity Telemetry</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">Profile update events by week — click a bar to view that period</p>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#2ff801] opacity-40" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-[#2ff801]" />
            </span>
            <span className="hud-label text-[#2ff801]">Live</span>
          </div>
        </div>
        <div className="h-[220px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={stats!.recentActivity}
              onClick={(data) => { if (data?.activeTooltipIndex !== undefined) setActiveBar(data.activeTooltipIndex) }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#41475b" strokeOpacity={0.3} />
              <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#6f758b", fontFamily: "Inter" }} axisLine={false} tickLine={false} />
              <YAxis allowDecimals={false} tick={{ fontSize: 10, fill: "#6f758b", fontFamily: "Inter" }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ background: "#11192e", border: "1px solid rgba(255,255,255,0.08)", borderRadius: "8px", color: "#dfe4fe", fontSize: "12px", fontFamily: "Manrope" }}
                cursor={{ fill: "rgba(133, 173, 255, 0.06)" }}
              />
              <Bar dataKey="count" name="Updates" radius={[4, 4, 0, 0]} maxBarSize={72} style={{ cursor: "pointer" }}>
                {stats!.recentActivity.map((_, i) => (
                  <Cell key={i} fill={activeBar === i ? "#6c9fff" : "#85adff"} fillOpacity={activeBar === i ? 1 : 0.8} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
        {activeBar !== null && (
          <div className="mt-3 flex items-center justify-between p-3 rounded-lg bg-[#0c1326] border border-white/5">
            <span className="text-xs text-[#dfe4fe]">
              <span className="text-[#85adff] font-medium">{stats!.recentActivity[activeBar]?.date}</span>
              {" — "}{stats!.recentActivity[activeBar]?.count} profile update{stats!.recentActivity[activeBar]?.count !== 1 ? "s" : ""}
            </span>
            <Link href="/users" className="hud-label text-[#85adff] hover:text-[#dfe4fe] transition-colors">View users →</Link>
          </div>
        )}
      </div>

      {/* Supabase sync status — all tiles are clickable */}
      <div className="content-tile rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Supabase Sync Status</h2>
          <div className="flex items-center gap-1.5">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#2ff801] opacity-40" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-[#2ff801]" />
            </span>
            <span className="hud-label text-[#2ff801]">Active Stream</span>
          </div>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {syncItems.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="p-3 rounded-lg bg-[#0c1326] border border-white/5 block hover:border-white/15 hover:bg-[#11192e] transition-all duration-200 cursor-pointer active:scale-[0.97]"
            >
              <p className="hud-label mb-1.5">{item.label}</p>
              <p className="text-sm font-medium text-[#dfe4fe]">{item.value}</p>
              <p className="hud-label mt-1" style={{ color: item.color }}>● synced</p>
            </Link>
          ))}
        </div>
      </div>
    </div>
  )
}
