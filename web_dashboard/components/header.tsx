"use client"

import { useState, useEffect, useRef } from "react"
import { Bell, LogOut, Search, X, User, MapPin, Pin, Clock } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { useAuth } from "@/lib/auth-context"
import { createClient } from "@/lib/supabase"

function getInitials(name: string | null, email: string | null): string {
  if (name) {
    const parts = name.trim().split(" ")
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
    return name.slice(0, 2).toUpperCase()
  }
  if (email) return email.slice(0, 2).toUpperCase()
  return "??"
}

interface SearchResult {
  id: string
  email: string
  full_name: string | null
  username: string | null
  home_lat: number | null
  work_lat: number | null
  custom_pins: any[]
}

interface ActivityItem {
  id: string
  full_name: string | null
  username: string | null
  updated_at: string
  home_lat: number | null
}

export function Header() {
  const { user, profile, signOut } = useAuth()
  const [searchOpen, setSearchOpen] = useState(false)
  const [notifOpen, setNotifOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<SearchResult[]>([])
  const [searching, setSearching] = useState(false)
  const [activity, setActivity] = useState<ActivityItem[]>([])
  const searchRef = useRef<HTMLInputElement>(null)

  const displayName = profile?.full_name || profile?.username || user?.email?.split("@")[0] || "User"
  const displayEmail = user?.email ?? ""
  const initials = getInitials(profile?.full_name ?? profile?.username ?? null, user?.email ?? null)

  // Auto-focus search input when dialog opens
  useEffect(() => {
    if (searchOpen) {
      setTimeout(() => searchRef.current?.focus(), 100)
      setSearchQuery("")
      setSearchResults([])
    }
  }, [searchOpen])

  // Live search
  useEffect(() => {
    if (!searchOpen) return
    if (!searchQuery.trim()) { setSearchResults([]); return }

    const timeout = setTimeout(async () => {
      setSearching(true)
      const supabase = createClient()
      const { data } = await supabase.rpc("get_users_for_admin")
      if (data) {
        const q = searchQuery.toLowerCase()
        const filtered = (data as SearchResult[]).filter(u =>
          u.email?.toLowerCase().includes(q) ||
          (u.full_name?.toLowerCase().includes(q) ?? false) ||
          (u.username?.toLowerCase().includes(q) ?? false)
        ).slice(0, 6)
        setSearchResults(filtered)
      }
      setSearching(false)
    }, 300)

    return () => clearTimeout(timeout)
  }, [searchQuery, searchOpen])

  // Load recent activity for notifications
  useEffect(() => {
    if (!notifOpen) return
    const fetchActivity = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from("profiles")
        .select("id, full_name, username, updated_at, home_lat")
        .order("updated_at", { ascending: false })
        .limit(8)
      if (data) setActivity(data)
    }
    fetchActivity()
  }, [notifOpen])

  return (
    <>
      <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-white/5 bg-[#070d1f]/90 backdrop-blur-xl px-4 sm:px-6">
        {/* Live sync indicator */}
        <div className="hidden md:flex items-center gap-2">
          <div className="relative flex items-center justify-center w-4 h-4">
            <span className="absolute inline-flex h-full w-full rounded-full bg-[#2ff801] opacity-20 animate-ping" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-[#2ff801]" />
          </div>
          <span className="hud-label">Live Sync</span>
        </div>

        <div className="flex items-center gap-1 ml-auto">
          {/* Search */}
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 text-[#6f758b] hover:text-[#dfe4fe] hover:bg-white/5"
            onClick={() => setSearchOpen(true)}
            title="Search"
          >
            <Search className="h-4 w-4" />
          </Button>

          {/* Notifications */}
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 text-[#6f758b] hover:text-[#dfe4fe] hover:bg-white/5 relative"
            onClick={() => setNotifOpen(true)}
            title="Notifications"
          >
            <Bell className="h-4 w-4" />
            <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 rounded-full bg-[#2ff801]" />
          </Button>

          {/* User info */}
          <div className="flex items-center gap-2.5 pl-3 ml-1 border-l border-white/10">
            <Avatar className="h-7 w-7">
              <AvatarFallback className="bg-[#85adff]/15 text-[#85adff] text-[10px] font-semibold">
                {initials}
              </AvatarFallback>
            </Avatar>
            <div className="hidden lg:block">
              <p className="text-xs font-medium text-[#dfe4fe] leading-tight">{displayName}</p>
              <p className="hud-label leading-tight">{displayEmail.split("@")[0]} · Verified</p>
            </div>
          </div>

          {/* Logout */}
          <Button
            variant="ghost"
            size="icon"
            onClick={() => signOut()}
            title="Sign out"
            className="h-8 w-8 text-[#6f758b] hover:text-[#ff716c] hover:bg-[#ff716c]/10 ml-1 transition-colors"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </header>

      {/* Search Dialog */}
      <Dialog open={searchOpen} onOpenChange={setSearchOpen}>
        <DialogContent className="max-w-lg bg-[#0c1326] border-white/10 text-[#dfe4fe] p-0 gap-0">
          <div className="flex items-center gap-3 px-4 py-3 border-b border-white/5">
            <Search className="h-4 w-4 text-[#6f758b] shrink-0" />
            <Input
              ref={searchRef}
              placeholder="Search users by name, email, username..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="border-0 bg-transparent text-[#dfe4fe] placeholder:text-[#6f758b] text-sm focus-visible:ring-0 px-0 h-auto"
            />
            {searchQuery && (
              <button onClick={() => setSearchQuery("")} className="text-[#6f758b] hover:text-[#dfe4fe]">
                <X className="h-4 w-4" />
              </button>
            )}
          </div>

          <div className="max-h-80 overflow-y-auto">
            {searching && (
              <div className="px-4 py-6 text-center hud-label">Searching...</div>
            )}
            {!searching && searchQuery && searchResults.length === 0 && (
              <div className="px-4 py-6 text-center hud-label">No results found</div>
            )}
            {!searching && !searchQuery && (
              <div className="px-4 py-6 text-center hud-label">Type to search across user nodes</div>
            )}
            {searchResults.map((result) => {
              const name = result.full_name || result.username || result.email
              const pins = Array.isArray(result.custom_pins) ? result.custom_pins.length : 0
              return (
                <button
                  key={result.id}
                  className="w-full flex items-center gap-3 px-4 py-3 hover:bg-white/5 transition-colors text-left border-b border-white/5 last:border-0"
                  onClick={() => {
                    setSearchOpen(false)
                    window.location.href = `/users`
                  }}
                >
                  <div className="w-8 h-8 rounded-full bg-[#85adff]/15 flex items-center justify-center shrink-0">
                    <User className="h-3.5 w-3.5 text-[#85adff]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[#dfe4fe] truncate">{name}</p>
                    <p className="text-xs text-[#a5aac2] truncate">{result.email}</p>
                  </div>
                  <div className="flex items-center gap-3 text-[10px] text-[#6f758b] shrink-0">
                    {result.home_lat && <span className="flex items-center gap-1"><MapPin className="h-3 w-3 text-[#2ff801]" />Home</span>}
                    {pins > 0 && <span className="flex items-center gap-1"><Pin className="h-3 w-3" />{pins}</span>}
                  </div>
                </button>
              )
            })}
          </div>

          <div className="px-4 py-2 border-t border-white/5 flex items-center justify-between">
            <span className="hud-label">Press ESC to close</span>
            <button
              className="hud-label text-[#85adff] hover:text-[#dfe4fe] transition-colors"
              onClick={() => { setSearchOpen(false); window.location.href = "/users" }}
            >
              View all users →
            </button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Notifications Dialog */}
      <Dialog open={notifOpen} onOpenChange={setNotifOpen}>
        <DialogContent className="max-w-sm bg-[#0c1326] border-white/10 text-[#dfe4fe]">
          <DialogHeader className="pb-0">
            <div className="flex items-center justify-between">
              <DialogTitle className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">
                Recent Activity
              </DialogTitle>
              <div className="flex items-center gap-1.5">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#2ff801] opacity-40" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-[#2ff801]" />
                </span>
                <span className="hud-label text-[#2ff801]">Live</span>
              </div>
            </div>
          </DialogHeader>

          <div className="space-y-1.5 max-h-72 overflow-y-auto">
            {activity.length === 0 ? (
              <p className="text-center hud-label py-6">Loading activity...</p>
            ) : activity.map((item) => {
              const name = item.full_name || item.username || `Node ${item.id.slice(0, 6)}`
              const ago = (() => {
                const diff = Date.now() - new Date(item.updated_at).getTime()
                const mins = Math.floor(diff / 60000)
                if (mins < 60) return `${mins}m ago`
                const hrs = Math.floor(mins / 60)
                if (hrs < 24) return `${hrs}h ago`
                return `${Math.floor(hrs / 24)}d ago`
              })()
              return (
                <div key={item.id} className="flex items-start gap-3 p-2.5 rounded-lg hover:bg-white/5 transition-colors">
                  <div className="w-7 h-7 rounded-full bg-[#85adff]/15 flex items-center justify-center shrink-0 mt-0.5">
                    <User className="h-3 w-3 text-[#85adff]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-medium text-[#dfe4fe] truncate">{name}</p>
                    <p className="hud-label mt-0.5">
                      {item.home_lat ? "Profile with home location" : "Profile updated"}
                    </p>
                  </div>
                  <span className="hud-label shrink-0 flex items-center gap-1">
                    <Clock className="h-2.5 w-2.5" />{ago}
                  </span>
                </div>
              )
            })}
          </div>

          <div className="pt-2 border-t border-white/5">
            <button
              className="w-full py-2 rounded-lg text-xs font-medium bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors"
              onClick={() => setNotifOpen(false)}
            >
              Dismiss All
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
