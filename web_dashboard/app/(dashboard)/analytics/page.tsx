"use client"

import { useEffect, useState } from "react"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts"
import { createClient } from "@/lib/supabase"
import type { Profile } from "@/lib/auth-context"

const TOOLTIP_STYLE = {
  background: "#11192e",
  border: "1px solid rgba(255,255,255,0.08)",
  borderRadius: "8px",
  color: "#dfe4fe",
  fontSize: "12px",
  fontFamily: "Manrope",
}

const CURSOR_STYLE = { fill: "rgba(133, 173, 255, 0.05)" }
const TICK_STYLE = { fontSize: 10, fill: "#6f758b", fontFamily: "Inter" }

export default function AnalyticsPage() {
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      const supabase = createClient()
      const { data } = await supabase.from("profiles").select("*")
      setProfiles(data ?? [])
      setLoading(false)
    }
    fetchData()
  }, [])

  const withBoth = profiles.filter((p) => p.home_lat && p.work_lat).length
  const homeOnly = profiles.filter((p) => p.home_lat && !p.work_lat).length
  const workOnly = profiles.filter((p) => !p.home_lat && p.work_lat).length
  const neither = profiles.filter((p) => !p.home_lat && !p.work_lat).length

  const locationPie = [
    { name: "Home & Work", value: withBoth, color: "#85adff" },
    { name: "Home Only", value: homeOnly, color: "#2ff801" },
    { name: "Work Only", value: workOnly, color: "#81ecff" },
    { name: "No Locations", value: neither, color: "#41475b" },
  ].filter((d) => d.value > 0)

  const completenessData = [
    { field: "Full Name", set: profiles.filter((p) => p.full_name).length, missing: profiles.filter((p) => !p.full_name).length },
    { field: "Username", set: profiles.filter((p) => p.username).length, missing: profiles.filter((p) => !p.username).length },
    { field: "Home", set: profiles.filter((p) => p.home_lat).length, missing: profiles.filter((p) => !p.home_lat).length },
    { field: "Work", set: profiles.filter((p) => p.work_lat).length, missing: profiles.filter((p) => !p.work_lat).length },
    { field: "Birthday", set: profiles.filter((p) => p.date_of_birth).length, missing: profiles.filter((p) => !p.date_of_birth).length },
  ]

  const pinData = profiles
    .filter((p) => Array.isArray(p.custom_pins) && p.custom_pins.length > 0)
    .map((p) => ({
      name: p.full_name || p.username || p.id.slice(0, 6),
      pins: (p.custom_pins as any[]).length,
    }))
    .sort((a, b) => b.pins - a.pins)

  if (loading) {
    return (
      <div className="space-y-5">
        <div>
          <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Analytics</h1>
          <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Spatial data intelligence</p>
        </div>
        <div className="grid gap-4 grid-cols-1 lg:grid-cols-2">
          {[...Array(2)].map((_, i) => (
            <div key={i} className="content-tile rounded-xl h-72 animate-pulse" />
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Analytics</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Spatial data intelligence · {profiles.length} total nodes</p>
      </div>

      <div className="grid gap-4 grid-cols-1 lg:grid-cols-2">
        {/* Location coverage */}
        <div className="content-tile rounded-xl p-6">
          <div className="mb-4">
            <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Location Coverage</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">Home & work location completion across users</p>
          </div>
          <div className="h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={locationPie}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={90}
                  label={({ name, percent }) => `${(percent * 100).toFixed(0)}%`}
                  labelLine={{ stroke: "#41475b" }}
                >
                  {locationPie.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Legend
                  formatter={(value) => <span style={{ color: "#a5aac2", fontSize: "11px" }}>{value}</span>}
                />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Profile completeness */}
        <div className="content-tile rounded-xl p-6">
          <div className="mb-4">
            <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Profile Completeness</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">How many users have each field filled</p>
          </div>
          <div className="h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={completenessData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#41475b" strokeOpacity={0.3} />
                <XAxis dataKey="field" tick={TICK_STYLE} axisLine={false} tickLine={false} />
                <YAxis allowDecimals={false} tick={TICK_STYLE} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={TOOLTIP_STYLE} cursor={CURSOR_STYLE} />
                <Legend formatter={(value) => <span style={{ color: "#a5aac2", fontSize: "11px" }}>{value}</span>} />
                <Bar dataKey="set" name="Filled" fill="#85adff" radius={[4, 4, 0, 0]} stackId="a" />
                <Bar dataKey="missing" name="Missing" fill="#41475b" radius={[4, 4, 0, 0]} stackId="a" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {pinData.length > 0 && (
        <div className="content-tile rounded-xl p-6">
          <div className="mb-4">
            <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Waypoints Per Node</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">Users who have saved custom pins</p>
          </div>
          <div className="h-[220px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={pinData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#41475b" strokeOpacity={0.3} />
                <XAxis dataKey="name" tick={TICK_STYLE} axisLine={false} tickLine={false} />
                <YAxis allowDecimals={false} tick={TICK_STYLE} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={TOOLTIP_STYLE} cursor={CURSOR_STYLE} />
                <Bar dataKey="pins" name="Pins" fill="#81ecff" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </div>
  )
}
