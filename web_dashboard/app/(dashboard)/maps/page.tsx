"use client"

import { useEffect, useState, Suspense } from "react"
import { useSearchParams } from "next/navigation"
import { Pin, Briefcase, Home, Globe, MapPin, X, ExternalLink, ChevronRight } from "lucide-react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { createClient } from "@/lib/supabase"
import type { Profile } from "@/lib/auth-context"

type FilterType = "all" | "home" | "work" | "pins"

interface MapLocation {
  lat: number
  lon: number
  label: string
  userName: string
}

interface WaypointsUser {
  name: string
  pins: { label: string; lat: number; lon: number }[]
}

function MapDialog({ location, onClose }: { location: MapLocation | null; onClose: () => void }) {
  if (!location) return null
  const { lat, lon, label, userName } = location
  const d = 0.008
  const bbox = `${lon - d}%2C${lat - d}%2C${lon + d}%2C${lat + d}`
  const src = `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat}%2C${lon}`
  const osmLink = `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lon}#map=15/${lat}/${lon}`

  return (
    <Dialog open={!!location} onOpenChange={(open) => { if (!open) onClose() }}>
      <DialogContent className="max-w-lg bg-[#0c1326] border-white/10 text-[#dfe4fe] p-0 overflow-hidden">
        <DialogHeader className="px-5 pt-5 pb-4 border-b border-white/5">
          <DialogTitle className="font-headline text-[#dfe4fe] flex items-center gap-2">
            <MapPin className="h-4 w-4 text-[#85adff]" />
            {label}
          </DialogTitle>
          <p className="hud-label mt-0.5">{userName}</p>
        </DialogHeader>
        <div className="relative w-full h-[320px]">
          <iframe
            src={src}
            width="100%"
            height="100%"
            style={{ border: "none", display: "block" }}
            title={label}
          />
        </div>
        <div className="flex items-center justify-between px-5 py-3 border-t border-white/5">
          <p className="font-label text-[10px] text-[#6f758b] uppercase tracking-wider">
            {lat.toFixed(5)}, {lon.toFixed(5)}
          </p>
          <a
            href={osmLink}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium bg-[#85adff]/10 text-[#85adff] hover:bg-[#85adff]/20 transition-colors"
          >
            <ExternalLink className="h-3 w-3" /> Open in OSM
          </a>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function WaypointsDrawer({
  user,
  onClose,
  onSelectPin,
}: {
  user: WaypointsUser | null
  onClose: () => void
  onSelectPin: (pin: { label: string; lat: number; lon: number }) => void
}) {
  if (!user) return null

  return (
    <Dialog open={!!user} onOpenChange={(open) => { if (!open) onClose() }}>
      <DialogContent className="max-w-sm bg-[#0c1326] border-white/10 text-[#dfe4fe] p-0 overflow-hidden">
        <DialogHeader className="px-5 pt-5 pb-4 border-b border-white/5">
          <DialogTitle className="font-headline text-[#dfe4fe] flex items-center gap-2">
            <Pin className="h-4 w-4 text-[#81ecff]" />
            Waypoints
          </DialogTitle>
          <p className="hud-label mt-0.5">{user.name} · {user.pins.length} saved</p>
        </DialogHeader>
        <div className="p-4 max-h-[60vh] overflow-y-auto space-y-2">
          {user.pins.length === 0 ? (
            <p className="text-sm text-[#a5aac2] text-center py-6">No waypoints saved.</p>
          ) : (
            user.pins.map((pin, i) => (
              <button
                key={i}
                onClick={() => onSelectPin(pin)}
                className="w-full flex items-center justify-between p-3.5 rounded-xl bg-[#11192e] border border-white/5 hover:border-[#81ecff]/20 hover:bg-[#81ecff]/5 transition-all text-left group"
              >
                <div className="flex items-center gap-3">
                  <div className="p-1.5 rounded-lg bg-[#81ecff]/10">
                    <Pin className="h-3.5 w-3.5 text-[#81ecff]" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-[#dfe4fe]">{pin.label || `Waypoint ${i + 1}`}</p>
                    <p className="font-label text-[10px] text-[#a5aac2] mt-0.5">
                      {pin.lat.toFixed(4)}, {pin.lon.toFixed(4)}
                    </p>
                  </div>
                </div>
                <ChevronRight className="h-4 w-4 text-[#6f758b] group-hover:text-[#81ecff] transition-colors" />
              </button>
            ))
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}

function MapsContent() {
  const searchParams = useSearchParams()
  const initialFilter = (searchParams.get("filter") as FilterType) ?? "all"

  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [activeFilter, setActiveFilter] = useState<FilterType>(initialFilter)
  const [mapLocation, setMapLocation] = useState<MapLocation | null>(null)
  const [waypointsUser, setWaypointsUser] = useState<WaypointsUser | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from("profiles")
        .select("id, full_name, username, home_lat, home_lon, work_lat, work_lon, custom_pins, updated_at")
        .order("updated_at", { ascending: false })
      setProfiles((data ?? []) as Profile[])
      setLoading(false)
    }
    fetchData()
  }, [])

  const totalHome = profiles.filter((p) => p.home_lat !== null).length
  const totalWork = profiles.filter((p) => p.work_lat !== null).length
  const totalCustomPins = profiles.reduce((sum, p) => {
    return sum + (Array.isArray(p.custom_pins) ? p.custom_pins.length : 0)
  }, 0)

  const filtered = profiles.filter((p) => {
    if (activeFilter === "home") return p.home_lat !== null
    if (activeFilter === "work") return p.work_lat !== null
    if (activeFilter === "pins") return Array.isArray(p.custom_pins) && p.custom_pins.length > 0
    return true
  })

  const tiles = [
    { label: "All Nodes", value: profiles.length, icon: Globe, accent: "#85adff", filter: "all" as FilterType, desc: "Show all users" },
    { label: "Home Anchors", value: totalHome, icon: Home, accent: "#2ff801", filter: "home" as FilterType, desc: "Users with home saved" },
    { label: "Work Beacons", value: totalWork, icon: Briefcase, accent: "#85adff", filter: "work" as FilterType, desc: "Users with work saved" },
    { label: "Custom Waypoints", value: totalCustomPins, icon: Pin, accent: "#81ecff", filter: "pins" as FilterType, desc: "Total across all users" },
  ]

  const openHome = (profile: Profile, name: string) => {
    if (!profile.home_lat || !profile.home_lon) return
    setMapLocation({ lat: profile.home_lat, lon: profile.home_lon, label: "Home Location", userName: name })
  }

  const openWork = (profile: Profile, name: string) => {
    if (!profile.work_lat || !profile.work_lon) return
    setMapLocation({ lat: profile.work_lat, lon: profile.work_lon, label: "Work Location", userName: name })
  }

  const openWaypoints = (profile: Profile, name: string) => {
    const pins = Array.isArray(profile.custom_pins) ? profile.custom_pins : []
    setWaypointsUser({ name, pins })
  }

  const openPinOnMap = (pin: { label: string; lat: number; lon: number }, userName: string) => {
    setWaypointsUser(null)
    setTimeout(() => {
      setMapLocation({ lat: pin.lat, lon: pin.lon, label: pin.label || "Waypoint", userName })
    }, 150)
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Spatial Operations</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">User location anchors and waypoint telemetry</p>
      </div>

      {/* Filter tiles */}
      <div className="grid gap-4 grid-cols-2 sm:grid-cols-4">
        {tiles.map((stat) => {
          const isActive = activeFilter === stat.filter
          return (
            <button
              key={stat.label}
              onClick={() => setActiveFilter(stat.filter)}
              className={`content-tile rounded-xl p-5 text-left w-full cursor-pointer transition-all duration-200 active:scale-[0.97] ${isActive ? "border-[#85adff]/30 bg-[#85adff]/5" : "hover:border-white/15 hover:bg-[#0c1326]"}`}
            >
              <div className="flex items-start justify-between mb-4">
                <div className="p-2 rounded-lg" style={{ background: `${stat.accent}18` }}>
                  <stat.icon className="h-4 w-4" style={{ color: stat.accent }} />
                </div>
                {isActive && <span className="hud-label text-[#85adff]">● active</span>}
              </div>
              <div className="font-headline text-2xl font-bold text-[#dfe4fe] mb-1">{stat.value.toLocaleString()}</div>
              <p className="hud-label">{stat.label}</p>
              <p className="text-[10px] text-[#a5aac2] mt-0.5">{stat.desc}</p>
            </button>
          )
        })}
      </div>

      {/* Location data */}
      <div className="content-tile rounded-xl">
        <div className="flex items-center justify-between p-5 border-b border-white/5">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">User Location Data</h2>
              {activeFilter !== "all" && (
                <button
                  onClick={() => setActiveFilter("all")}
                  className="px-2 py-0.5 rounded-full text-[10px] font-label bg-[#85adff]/15 text-[#85adff] uppercase tracking-wider hover:bg-[#85adff]/25 transition-colors"
                >
                  {activeFilter === "home" ? "Home" : activeFilter === "work" ? "Work" : "Pins"} ✕
                </button>
              )}
            </div>
            <p className="text-xs text-[#a5aac2] mt-0.5">
              Showing {filtered.length} of {profiles.length} nodes
              {activeFilter !== "all" ? " (filtered)" : " — click a tile above to filter"}
            </p>
          </div>
          <div className="flex items-center gap-1.5">
            <Globe className="h-3.5 w-3.5 text-[#6f758b]" />
            <span className="hud-label">{profiles.length} total</span>
          </div>
        </div>

        <div className="p-4">
          {loading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => <div key={i} className="h-20 animate-pulse rounded-lg bg-[#0c1326]" />)}
            </div>
          ) : filtered.length === 0 ? (
            <p className="text-sm text-[#a5aac2] text-center py-10">No nodes match the current filter.</p>
          ) : (
            <div className="space-y-2">
              {filtered.map((profile) => {
                const name = profile.full_name || profile.username || `Node ${profile.id.slice(0, 6)}`
                const pins = Array.isArray(profile.custom_pins) ? profile.custom_pins : []
                return (
                  <div key={profile.id} className="p-4 rounded-xl bg-[#0c1326] border border-white/5 hover:bg-[#11192e] transition-colors">
                    <div className="flex items-center justify-between mb-3">
                      <p className="font-medium text-sm text-[#dfe4fe]">{name}</p>
                      <span className="font-label text-[10px] text-[#6f758b] uppercase tracking-wider">{profile.id.slice(0, 8)}…</span>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 text-xs">

                      {/* Home — clickable if set */}
                      <button
                        disabled={!profile.home_lat}
                        onClick={() => openHome(profile, name)}
                        className={`flex items-start gap-2 p-2.5 rounded-lg text-left transition-all w-full ${
                          profile.home_lat
                            ? "bg-[#2ff801]/10 border border-[#2ff801]/15 hover:bg-[#2ff801]/20 hover:border-[#2ff801]/30 cursor-pointer active:scale-[0.98]"
                            : "bg-[#11192e] cursor-default"
                        }`}
                      >
                        <Home className={`h-3.5 w-3.5 mt-0.5 shrink-0 ${profile.home_lat ? "text-[#2ff801]" : "text-[#6f758b]"}`} />
                        <div className="min-w-0">
                          <p className="font-medium text-[#dfe4fe] flex items-center gap-1">
                            Home
                            {profile.home_lat && <MapPin className="h-2.5 w-2.5 text-[#2ff801]" />}
                          </p>
                          {profile.home_lat ? (
                            <p className="font-label text-[10px] text-[#a5aac2] mt-0.5">{profile.home_lat.toFixed(4)}, {profile.home_lon?.toFixed(4)}</p>
                          ) : (
                            <p className="text-[#6f758b]">Not set</p>
                          )}
                        </div>
                      </button>

                      {/* Work — clickable if set */}
                      <button
                        disabled={!profile.work_lat}
                        onClick={() => openWork(profile, name)}
                        className={`flex items-start gap-2 p-2.5 rounded-lg text-left transition-all w-full ${
                          profile.work_lat
                            ? "bg-[#85adff]/10 border border-[#85adff]/15 hover:bg-[#85adff]/20 hover:border-[#85adff]/30 cursor-pointer active:scale-[0.98]"
                            : "bg-[#11192e] cursor-default"
                        }`}
                      >
                        <Briefcase className={`h-3.5 w-3.5 mt-0.5 shrink-0 ${profile.work_lat ? "text-[#85adff]" : "text-[#6f758b]"}`} />
                        <div className="min-w-0">
                          <p className="font-medium text-[#dfe4fe] flex items-center gap-1">
                            Work
                            {profile.work_lat && <MapPin className="h-2.5 w-2.5 text-[#85adff]" />}
                          </p>
                          {profile.work_lat ? (
                            <p className="font-label text-[10px] text-[#a5aac2] mt-0.5">{profile.work_lat.toFixed(4)}, {profile.work_lon?.toFixed(4)}</p>
                          ) : (
                            <p className="text-[#6f758b]">Not set</p>
                          )}
                        </div>
                      </button>

                      {/* Waypoints — clickable if any */}
                      <button
                        disabled={pins.length === 0}
                        onClick={() => openWaypoints(profile, name)}
                        className={`flex items-start gap-2 p-2.5 rounded-lg text-left transition-all w-full ${
                          pins.length > 0
                            ? "bg-[#81ecff]/10 border border-[#81ecff]/15 hover:bg-[#81ecff]/20 hover:border-[#81ecff]/30 cursor-pointer active:scale-[0.98]"
                            : "bg-[#11192e] cursor-default"
                        }`}
                      >
                        <Pin className={`h-3.5 w-3.5 mt-0.5 shrink-0 ${pins.length > 0 ? "text-[#81ecff]" : "text-[#6f758b]"}`} />
                        <div className="min-w-0">
                          <p className="font-medium text-[#dfe4fe] flex items-center gap-1">
                            {pins.length} Waypoint{pins.length !== 1 ? "s" : ""}
                            {pins.length > 0 && <ChevronRight className="h-2.5 w-2.5 text-[#81ecff]" />}
                          </p>
                          {pins.length > 0 && (
                            <p className="text-[#a5aac2] mt-0.5 truncate text-[10px]">{pins.map((p: any) => p.label || "Pin").join(", ")}</p>
                          )}
                        </div>
                      </button>

                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>

      {/* Map dialog */}
      <MapDialog location={mapLocation} onClose={() => setMapLocation(null)} />

      {/* Waypoints drawer */}
      <WaypointsDrawer
        user={waypointsUser}
        onClose={() => setWaypointsUser(null)}
        onSelectPin={(pin) => {
          const name = waypointsUser?.name ?? ""
          openPinOnMap(pin, name)
        }}
      />
    </div>
  )
}

export default function MapsPage() {
  return (
    <Suspense fallback={<div className="space-y-5"><div className="content-tile rounded-xl h-24 animate-pulse" /></div>}>
      <MapsContent />
    </Suspense>
  )
}
