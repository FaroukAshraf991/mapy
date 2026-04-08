"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"
import {
  LayoutDashboard, Map, Users, Settings, BarChart3, FileText,
  Menu, X, Plus, HelpCircle, Layers, User, MapPin, Pin, Search
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { createClient } from "@/lib/supabase"

const navigation = [
  { name: "Dashboard Overview", href: "/dashboard", icon: LayoutDashboard },
  { name: "User Management", href: "/users", icon: Users },
  { name: "Spatial Operations", href: "/maps", icon: Map },
  { name: "Analytics", href: "/analytics", icon: BarChart3 },
  { name: "Audit & Compliance", href: "/reports", icon: FileText },
]

interface SpatialUser {
  id: string
  email: string
  full_name: string | null
  username: string | null
  home_lat: number | null
  home_lon: number | null
  work_lat: number | null
  work_lon: number | null
  custom_pins: any[]
}

export function Sidebar() {
  const pathname = usePathname()
  const [mobileOpen, setMobileOpen] = useState(false)
  const [queryOpen, setQueryOpen] = useState(false)
  const [querySearch, setQuerySearch] = useState("")
  const [queryResults, setQueryResults] = useState<SpatialUser[]>([])
  const [queryLoading, setQueryLoading] = useState(false)
  const [allUsers, setAllUsers] = useState<SpatialUser[]>([])

  const openQuery = async () => {
    setQueryOpen(true)
    setQuerySearch("")
    setQueryLoading(true)
    const supabase = createClient()
    const { data } = await supabase.rpc("get_users_for_admin")
    const users = (data ?? []) as SpatialUser[]
    setAllUsers(users)
    setQueryResults(users.filter(u => u.home_lat || u.work_lat))
    setQueryLoading(false)
  }

  const handleQuerySearch = (q: string) => {
    setQuerySearch(q)
    if (!q.trim()) {
      setQueryResults(allUsers.filter(u => u.home_lat || u.work_lat))
      return
    }
    const lower = q.toLowerCase()
    setQueryResults(
      allUsers.filter(u =>
        (u.full_name?.toLowerCase().includes(lower)) ||
        (u.username?.toLowerCase().includes(lower)) ||
        u.email?.toLowerCase().includes(lower)
      )
    )
  }

  const isSettingsActive = pathname.startsWith("/settings")

  return (
    <>
      {/* Mobile toggle */}
      <Button
        variant="ghost"
        size="icon"
        className="md:hidden fixed top-3.5 left-4 z-50 bg-[#11192e] border border-white/10 text-[#dfe4fe] hover:bg-[#171f36]"
        onClick={() => setMobileOpen(!mobileOpen)}
        aria-label="Toggle menu"
      >
        {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
      </Button>

      {mobileOpen && (
        <div className="fixed inset-0 z-30 bg-black/70 md:hidden" onClick={() => setMobileOpen(false)} />
      )}

      <aside className={cn(
        "fixed inset-y-0 left-0 z-40 w-64 flex flex-col transform transition-transform duration-300 md:translate-x-0",
        "bg-[#070d1f] border-r border-white/5",
        mobileOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        {/* Brand */}
        <div className="px-5 py-5 border-b border-white/5">
          <div className="flex items-center gap-2.5 mb-1">
            <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-[#85adff] to-[#6c9fff] flex items-center justify-center shrink-0">
              <Layers className="h-3.5 w-3.5 text-[#002c65]" />
            </div>
            <h1 className="font-headline text-sm font-bold text-[#dfe4fe] tracking-tight">Mapy Engine</h1>
          </div>
          <p className="text-[10px] font-label text-[#6f758b] uppercase tracking-[0.15em] ml-9">Enterprise HUD</p>
        </div>

        {/* New Spatial Query CTA */}
        <div className="px-4 py-4">
          <button
            onClick={openQuery}
            className="w-full flex items-center justify-center gap-2 py-2 px-4 rounded-xl text-xs font-medium text-[#002c65] bg-gradient-to-r from-[#85adff] to-[#6c9fff] hover:opacity-90 transition-opacity active:scale-95"
          >
            <Plus className="h-3.5 w-3.5" />
            New Spatial Query
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-2 space-y-0.5 overflow-y-auto">
          {navigation.map((item) => {
            const isActive = pathname === item.href || (item.href !== "/dashboard" && pathname.startsWith(item.href))
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 text-sm rounded-xl transition-all duration-200",
                  isActive
                    ? "bg-[#85adff]/10 text-[#85adff]"
                    : "text-[#a5aac2] hover:bg-white/5 hover:text-[#dfe4fe]"
                )}
                onClick={() => setMobileOpen(false)}
              >
                <item.icon className={cn("h-4 w-4 shrink-0", isActive ? "text-[#85adff]" : "text-[#6f758b]")} />
                <span className="font-medium text-xs">{item.name}</span>
                {isActive && <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[#85adff] shrink-0" />}
              </Link>
            )
          })}
        </nav>

        {/* Footer — split settings */}
        <div className="px-3 py-4 border-t border-white/5 space-y-0.5">
          {/* Dashboard Settings */}
          <Link
            href="/settings"
            className={cn(
              "flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200",
              pathname === "/settings"
                ? "bg-[#85adff]/10 text-[#85adff]"
                : "text-[#a5aac2] hover:bg-white/5 hover:text-[#dfe4fe]"
            )}
            onClick={() => setMobileOpen(false)}
          >
            <Settings className={cn("h-4 w-4 shrink-0", pathname === "/settings" ? "text-[#85adff]" : "text-[#6f758b]")} />
            <div className="flex-1 min-w-0">
              <p className="font-medium text-xs">Dashboard Settings</p>
              <p className="hud-label" style={{ fontSize: "9px" }}>Display & preferences</p>
            </div>
          </Link>

          {/* Account Settings */}
          <Link
            href="/settings/account"
            className={cn(
              "flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200",
              pathname === "/settings/account"
                ? "bg-[#85adff]/10 text-[#85adff]"
                : "text-[#a5aac2] hover:bg-white/5 hover:text-[#dfe4fe]"
            )}
            onClick={() => setMobileOpen(false)}
          >
            <User className={cn("h-4 w-4 shrink-0", pathname === "/settings/account" ? "text-[#85adff]" : "text-[#6f758b]")} />
            <div className="flex-1 min-w-0">
              <p className="font-medium text-xs">Account Settings</p>
              <p className="hud-label" style={{ fontSize: "9px" }}>Profile & security</p>
            </div>
          </Link>

          {/* Support */}
          <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-[#a5aac2] hover:bg-white/5 hover:text-[#dfe4fe] transition-all duration-200">
            <HelpCircle className="h-4 w-4 shrink-0 text-[#6f758b]" />
            <span className="font-medium text-xs">Support</span>
          </button>
        </div>
      </aside>

      {/* Spatial Query Dialog */}
      <Dialog open={queryOpen} onOpenChange={setQueryOpen}>
        <DialogContent className="max-w-lg bg-[#0c1326] border-white/10 text-[#dfe4fe] p-0 gap-0">
          <DialogHeader className="px-4 pt-4 pb-3 border-b border-white/5">
            <DialogTitle className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">
              Spatial Query
            </DialogTitle>
            <p className="text-xs text-[#a5aac2] mt-0.5">Search user nodes by name and view their spatial anchors</p>
          </DialogHeader>

          {/* Search input */}
          <div className="flex items-center gap-3 px-4 py-3 border-b border-white/5">
            <Search className="h-4 w-4 text-[#6f758b] shrink-0" />
            <Input
              placeholder="Filter by name, username, email..."
              value={querySearch}
              onChange={(e) => handleQuerySearch(e.target.value)}
              className="border-0 bg-transparent text-[#dfe4fe] placeholder:text-[#6f758b] text-sm focus-visible:ring-0 px-0 h-auto"
              autoFocus
            />
          </div>

          {/* Results */}
          <div className="max-h-80 overflow-y-auto">
            {queryLoading ? (
              <div className="px-4 py-6 text-center hud-label">Loading spatial data...</div>
            ) : queryResults.length === 0 ? (
              <div className="px-4 py-6 text-center hud-label">No nodes with spatial data found</div>
            ) : queryResults.map((u) => {
              const name = u.full_name || u.username || u.email
              const pins = Array.isArray(u.custom_pins) ? u.custom_pins.length : 0
              return (
                <div key={u.id} className="flex items-start gap-3 px-4 py-3 border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
                  <div className="w-8 h-8 rounded-full bg-[#85adff]/15 flex items-center justify-center shrink-0 mt-0.5">
                    <User className="h-3.5 w-3.5 text-[#85adff]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[#dfe4fe] truncate">{name}</p>
                    <p className="text-xs text-[#a5aac2] truncate">{u.email}</p>
                    <div className="flex items-center gap-3 mt-1.5">
                      {u.home_lat ? (
                        <span className="flex items-center gap-1 hud-label text-[#2ff801]">
                          <MapPin className="h-2.5 w-2.5" />
                          Home: {u.home_lat.toFixed(3)}, {u.home_lon?.toFixed(3)}
                        </span>
                      ) : (
                        <span className="hud-label">No home</span>
                      )}
                      {u.work_lat && (
                        <span className="flex items-center gap-1 hud-label text-[#85adff]">
                          <MapPin className="h-2.5 w-2.5" />
                          Work set
                        </span>
                      )}
                      {pins > 0 && (
                        <span className="flex items-center gap-1 hud-label text-[#81ecff]">
                          <Pin className="h-2.5 w-2.5" />{pins} pin{pins !== 1 ? "s" : ""}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>

          <div className="px-4 py-3 border-t border-white/5 flex items-center justify-between">
            <span className="hud-label">{queryResults.length} nodes with spatial data</span>
            <button
              className="hud-label text-[#85adff] hover:text-[#dfe4fe] transition-colors"
              onClick={() => { setQueryOpen(false); window.location.href = "/maps" }}
            >
              Open Spatial Operations →
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
