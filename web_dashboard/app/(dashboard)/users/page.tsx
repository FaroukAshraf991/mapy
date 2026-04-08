"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Switch } from "@/components/ui/switch"
import { Separator } from "@/components/ui/separator"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { Search, MapPin, Pin, Briefcase, Shield, Pencil, Eye, EyeOff, Cake, Trash2, Users, Activity, X } from "lucide-react"
import { createClient } from "@/lib/supabase"

interface AdminUser {
  id: string
  email: string
  full_name: string | null
  username: string | null
  is_admin: boolean
  date_of_birth: string | null
  home_lat: number | null
  home_lon: number | null
  work_lat: number | null
  work_lon: number | null
  custom_pins: any[]
  updated_at: string
  created_at: string
}

function getInitials(user: AdminUser): string {
  const name = user.full_name || user.username
  if (name) {
    const parts = name.trim().split(" ")
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
    return name.slice(0, 2).toUpperCase()
  }
  if (user.email) return user.email.slice(0, 2).toUpperCase()
  return "??"
}

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([])
  const [search, setSearch] = useState("")
  const [activeFilter, setActiveFilter] = useState<"all" | "admins" | "withHome" | "withWork">("all")
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<AdminUser | null>(null)
  const [form, setForm] = useState({
    full_name: "",
    username: "",
    email: "",
    password: "",
    date_of_birth: "",
    is_admin: false,
  })
  const [showPassword, setShowPassword] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<AdminUser | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saveMsg, setSaveMsg] = useState<{ type: "success" | "error"; text: string } | null>(null)

  const fetchUsers = async () => {
    const supabase = createClient()
    const { data, error } = await supabase.rpc("get_users_for_admin")
    if (!error) setUsers(data ?? [])
    setLoading(false)
  }

  useEffect(() => { fetchUsers() }, [])

  const openEdit = (user: AdminUser) => {
    setEditing(user)
    setForm({
      full_name: user.full_name ?? "",
      username: user.username ?? "",
      email: user.email ?? "",
      password: "",
      date_of_birth: user.date_of_birth ?? "",
      is_admin: user.is_admin,
    })
    setSaveMsg(null)
    setShowPassword(false)
  }

  const handleSave = async () => {
    if (!editing) return
    setSaving(true)
    setSaveMsg(null)

    const supabase = createClient()
    const { error: profileError } = await supabase
      .from("profiles")
      .update({
        full_name: form.full_name || null,
        username: form.username || null,
        is_admin: form.is_admin,
        date_of_birth: form.date_of_birth || null,
      })
      .eq("id", editing.id)

    if (profileError) {
      setSaveMsg({ type: "error", text: profileError.message })
      setSaving(false)
      return
    }

    const authUpdates: { email?: string; password?: string } = {}
    if (form.email && form.email !== editing.email) authUpdates.email = form.email
    if (form.password) authUpdates.password = form.password

    if (Object.keys(authUpdates).length > 0) {
      const res = await fetch(`/api/admin/users/${editing.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(authUpdates),
      })
      const json = await res.json()
      if (!res.ok) {
        setSaveMsg({ type: "error", text: json.error ?? "Failed to update email/password." })
        setSaving(false)
        return
      }
    }

    setSaveMsg({ type: "success", text: "User updated successfully." })
    await fetchUsers()
    setSaving(false)
  }

  const handleClearLocation = async (field: "home" | "work" | "pins") => {
    if (!editing) return
    setSaving(true)
    setSaveMsg(null)
    const supabase = createClient()
    const updates =
      field === "home" ? { home_lat: null, home_lon: null } :
      field === "work" ? { work_lat: null, work_lon: null } :
      { custom_pins: [] }
    const { error } = await supabase.from("profiles").update(updates).eq("id", editing.id)
    if (error) {
      setSaveMsg({ type: "error", text: error.message })
    } else {
      setSaveMsg({ type: "success", text: `${field === "pins" ? "Waypoints" : field === "home" ? "Home" : "Work"} cleared.` })
      await fetchUsers()
      // Update editing state to reflect cleared values
      setEditing(prev => prev ? { ...prev, ...updates } as AdminUser : null)
    }
    setSaving(false)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    const res = await fetch(`/api/admin/users/${deleteTarget.id}`, { method: "DELETE" })
    const json = await res.json()
    if (!res.ok) {
      alert(json.error ?? "Failed to delete user.")
    } else {
      setDeleteTarget(null)
      setEditing(null)
      await fetchUsers()
    }
    setDeleting(false)
  }

  const filtered = users.filter((u) => {
    const q = search.toLowerCase()
    const matchesSearch =
      u.email?.toLowerCase().includes(q) ||
      (u.full_name?.toLowerCase().includes(q) ?? false) ||
      (u.username?.toLowerCase().includes(q) ?? false) ||
      u.id.toLowerCase().includes(q)
    if (!matchesSearch) return false
    if (activeFilter === "admins") return u.is_admin
    if (activeFilter === "withHome") return u.home_lat !== null
    if (activeFilter === "withWork") return u.work_lat !== null
    return true
  })

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">User Ecosystem</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Authentication nodes and spatial access permissions</p>
      </div>

      {/* Stat tiles — click to filter the list */}
      <div className="grid gap-4 grid-cols-2 sm:grid-cols-4">
        {[
          { label: "Total Active Nodes", value: users.length, icon: Users, accent: "#85adff", filter: "all" as const },
          { label: "Admin Accounts", value: users.filter(u => u.is_admin).length, icon: Shield, accent: "#81ecff", filter: "admins" as const },
          { label: "Home Anchors", value: users.filter(u => u.home_lat !== null).length, icon: MapPin, accent: "#2ff801", filter: "withHome" as const },
          { label: "Work Beacons", value: users.filter(u => u.work_lat !== null).length, icon: Activity, accent: "#85adff", filter: "withWork" as const },
        ].map((stat) => {
          const isActive = activeFilter === stat.filter
          return (
          <button
            key={stat.label}
            onClick={() => setActiveFilter(stat.filter)}
            className={`content-tile rounded-xl p-4 text-left w-full cursor-pointer transition-all duration-200 active:scale-[0.97] ${isActive ? "border-[#85adff]/30 bg-[#85adff]/5" : "hover:border-white/15 hover:bg-[#0c1326]"}`}
          >
            <div className="flex items-center justify-between mb-3">
              <div className="p-1.5 rounded-lg" style={{ background: `${stat.accent}18` }}>
                <stat.icon className="h-3.5 w-3.5" style={{ color: stat.accent }} />
              </div>
              {isActive && <span className="hud-label text-[#85adff]">● active</span>}
            </div>
            <div className="font-headline text-xl font-bold text-[#dfe4fe]">{stat.value}</div>
            <p className="hud-label mt-0.5">{stat.label}</p>
          </button>
          )
        })}
      </div>

      {/* Directory */}
      <div className="content-tile rounded-xl">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 p-5 border-b border-white/5">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Node Directory</h2>
              {activeFilter !== "all" && (
                <button onClick={() => setActiveFilter("all")} className="px-2 py-0.5 rounded-full text-[10px] font-label bg-[#85adff]/15 text-[#85adff] uppercase tracking-wider hover:bg-[#85adff]/25 transition-colors">
                  {activeFilter === "admins" ? "Admins" : activeFilter === "withHome" ? "Has Home" : "Has Work"} ✕
                </button>
              )}
            </div>
            <p className="text-xs text-[#a5aac2] mt-0.5">
              Showing {filtered.length} of {users.length} nodes
              {activeFilter !== "all" ? " (filtered)" : " — click a tile above to filter"}
            </p>
          </div>
          <div className="relative w-full sm:w-60">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#6f758b]" />
            <Input
              placeholder="Search identity, email..."
              className="pl-9 bg-[#0c1326] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] text-sm h-9 focus-visible:ring-[#85adff]/30"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="p-4">
          {loading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-16 animate-pulse rounded-lg bg-[#0c1326]" />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <p className="text-sm text-[#a5aac2] text-center py-10">No nodes found matching query.</p>
          ) : (
            <div className="space-y-2">
              {filtered.map((user) => {
                const displayName = user.full_name || user.username || user.email
                return (
                  <div
                    key={user.id}
                    className="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3.5 rounded-xl bg-[#0c1326] hover:bg-[#11192e] transition-colors gap-3 border border-white/5"
                  >
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9">
                        <AvatarFallback className="bg-[#85adff]/15 text-[#85adff] text-xs font-semibold">
                          {getInitials(user)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-medium text-sm text-[#dfe4fe]">{displayName}</p>
                          {user.is_admin && (
                            <span className="flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-label bg-[#85adff]/15 text-[#85adff] rounded-full uppercase tracking-wider">
                              <Shield className="h-2.5 w-2.5" /> Admin
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-[#a5aac2]">{user.email}</p>
                        {user.date_of_birth && (
                          <p className="text-xs text-[#6f758b] flex items-center gap-1 mt-0.5">
                            <Cake className="h-3 w-3" />
                            {new Date(user.date_of_birth).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })}
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-[#a5aac2] ml-12 sm:ml-0">
                      <button
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium bg-[#85adff]/10 text-[#85adff] hover:bg-[#85adff]/20 transition-colors"
                        onClick={() => openEdit(user)}
                      >
                        <Pencil className="h-3 w-3" /> Edit
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>

      {/* Edit dialog */}
      <Dialog open={!!editing} onOpenChange={(open) => { if (!open) setEditing(null) }}>
        <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto bg-[#0c1326] border-white/10 text-[#dfe4fe]">
          <DialogHeader>
            <DialogTitle className="font-headline text-[#dfe4fe]">Edit Node</DialogTitle>
            <DialogDescription className="font-label text-[10px] break-all text-[#6f758b] uppercase tracking-wider">{editing?.id}</DialogDescription>
          </DialogHeader>

          {saveMsg && (
            <div className={`p-3 text-sm rounded-lg border ${
              saveMsg.type === "success"
                ? "bg-[#2ff801]/10 text-[#2ff801] border-[#2ff801]/20"
                : "bg-[#ff716c]/10 text-[#ff716c] border-[#ff716c]/20"
            }`}>
              {saveMsg.text}
            </div>
          )}

          <div className="space-y-4">
            {[
              { label: "Full Name", key: "full_name" as const, placeholder: "Full name" },
              { label: "Username", key: "username" as const, placeholder: "username" },
            ].map(({ label, key, placeholder }) => (
              <div key={key} className="space-y-2">
                <label className="hud-label">{label}</label>
                <Input
                  placeholder={placeholder}
                  value={form[key]}
                  onChange={(e) => setForm(f => ({ ...f, [key]: e.target.value }))}
                  className="bg-[#11192e] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] focus-visible:ring-[#85adff]/30"
                />
              </div>
            ))}

            <div className="space-y-2">
              <label className="hud-label">Date of Birth</label>
              <Input
                type="date"
                value={form.date_of_birth}
                onChange={(e) => setForm(f => ({ ...f, date_of_birth: e.target.value }))}
                className="bg-[#11192e] border-white/10 text-[#dfe4fe] focus-visible:ring-[#85adff]/30"
              />
            </div>

            <Separator className="bg-white/5" />

            <div className="space-y-2">
              <label className="hud-label">Email Address</label>
              <Input
                type="email"
                placeholder="user@email.com"
                value={form.email}
                onChange={(e) => setForm(f => ({ ...f, email: e.target.value }))}
                className="bg-[#11192e] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] focus-visible:ring-[#85adff]/30"
              />
              <p className="hud-label">Requires service role key to update.</p>
            </div>

            <div className="space-y-2">
              <label className="hud-label">New Password</label>
              <div className="relative">
                <Input
                  type={showPassword ? "text" : "password"}
                  placeholder="Leave blank to keep current"
                  value={form.password}
                  onChange={(e) => setForm(f => ({ ...f, password: e.target.value }))}
                  className="pr-10 bg-[#11192e] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] focus-visible:ring-[#85adff]/30"
                />
                <button
                  type="button"
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#6f758b] hover:text-[#dfe4fe]"
                  onClick={() => setShowPassword(v => !v)}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <Separator className="bg-white/5" />

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[#dfe4fe]">Admin Access</p>
                <p className="hud-label mt-0.5">Grant or revoke admin privileges</p>
              </div>
              <Switch
                checked={form.is_admin}
                onCheckedChange={(checked) => setForm(f => ({ ...f, is_admin: checked }))}
              />
            </div>

            <Separator className="bg-white/5" />

            <div>
              <p className="hud-label mb-2">Location Data</p>
              <div className="space-y-2">
                {/* Home */}
                <div className={`flex items-center justify-between p-2.5 rounded-lg border ${editing?.home_lat ? "bg-[#2ff801]/5 border-[#2ff801]/15" : "bg-[#11192e] border-white/5"}`}>
                  <div className="flex items-center gap-2">
                    <MapPin className={`h-3.5 w-3.5 ${editing?.home_lat ? "text-[#2ff801]" : "text-[#6f758b]"}`} />
                    <div>
                      <p className="text-xs font-medium text-[#dfe4fe]">Home</p>
                      <p className="font-label text-[10px] text-[#a5aac2]">
                        {editing?.home_lat ? `${editing.home_lat.toFixed(4)}, ${editing.home_lon?.toFixed(4)}` : "Not set"}
                      </p>
                    </div>
                  </div>
                  {editing?.home_lat && (
                    <button
                      onClick={() => handleClearLocation("home")}
                      disabled={saving}
                      className="flex items-center gap-1 px-2 py-1 rounded-lg text-[10px] font-label bg-[#ff716c]/10 text-[#ff716c] hover:bg-[#ff716c]/20 transition-colors disabled:opacity-50"
                    >
                      <X className="h-3 w-3" /> Clear
                    </button>
                  )}
                </div>
                {/* Work */}
                <div className={`flex items-center justify-between p-2.5 rounded-lg border ${editing?.work_lat ? "bg-[#85adff]/5 border-[#85adff]/15" : "bg-[#11192e] border-white/5"}`}>
                  <div className="flex items-center gap-2">
                    <Briefcase className={`h-3.5 w-3.5 ${editing?.work_lat ? "text-[#85adff]" : "text-[#6f758b]"}`} />
                    <div>
                      <p className="text-xs font-medium text-[#dfe4fe]">Work</p>
                      <p className="font-label text-[10px] text-[#a5aac2]">
                        {editing?.work_lat ? `${editing.work_lat.toFixed(4)}, ${editing.work_lon?.toFixed(4)}` : "Not set"}
                      </p>
                    </div>
                  </div>
                  {editing?.work_lat && (
                    <button
                      onClick={() => handleClearLocation("work")}
                      disabled={saving}
                      className="flex items-center gap-1 px-2 py-1 rounded-lg text-[10px] font-label bg-[#ff716c]/10 text-[#ff716c] hover:bg-[#ff716c]/20 transition-colors disabled:opacity-50"
                    >
                      <X className="h-3 w-3" /> Clear
                    </button>
                  )}
                </div>
                {/* Waypoints */}
                {(() => {
                  const pins = Array.isArray(editing?.custom_pins) ? editing!.custom_pins : []
                  return (
                    <div className={`flex items-center justify-between p-2.5 rounded-lg border ${pins.length > 0 ? "bg-[#81ecff]/5 border-[#81ecff]/15" : "bg-[#11192e] border-white/5"}`}>
                      <div className="flex items-center gap-2">
                        <Pin className={`h-3.5 w-3.5 ${pins.length > 0 ? "text-[#81ecff]" : "text-[#6f758b]"}`} />
                        <div>
                          <p className="text-xs font-medium text-[#dfe4fe]">{pins.length} Waypoint{pins.length !== 1 ? "s" : ""}</p>
                          {pins.length > 0 && (
                            <p className="font-label text-[10px] text-[#a5aac2] truncate max-w-[160px]">
                              {pins.map((p: any) => p.label || "Pin").join(", ")}
                            </p>
                          )}
                        </div>
                      </div>
                      {pins.length > 0 && (
                        <button
                          onClick={() => handleClearLocation("pins")}
                          disabled={saving}
                          className="flex items-center gap-1 px-2 py-1 rounded-lg text-[10px] font-label bg-[#ff716c]/10 text-[#ff716c] hover:bg-[#ff716c]/20 transition-colors disabled:opacity-50"
                        >
                          <X className="h-3 w-3" /> Clear all
                        </button>
                      )}
                    </div>
                  )
                })()}
              </div>
            </div>

            <div className="p-2.5 bg-[#11192e] rounded-lg">
              <p className="hud-label mb-1">Joined</p>
              <p className="text-xs text-[#dfe4fe]">
                {editing ? new Date(editing.created_at).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" }) : ""}
              </p>
            </div>
          </div>

          <div className="flex items-center justify-between pt-2">
            <button
              className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium bg-[#ff716c]/10 text-[#ff716c] hover:bg-[#ff716c]/20 transition-colors"
              onClick={() => setDeleteTarget(editing)}
            >
              <Trash2 className="h-3.5 w-3.5" /> Delete Account
            </button>
            <div className="flex gap-2">
              <button
                className="px-3 py-2 rounded-lg text-xs font-medium bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors"
                onClick={() => setEditing(null)}
              >
                Cancel
              </button>
              <button
                className="px-3 py-2 rounded-lg text-xs font-medium bg-gradient-to-r from-[#85adff] to-[#6c9fff] text-[#002c65] hover:opacity-90 transition-opacity disabled:opacity-50"
                onClick={handleSave}
                disabled={saving}
              >
                {saving ? "Saving..." : "Save Changes"}
              </button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <Dialog open={!!deleteTarget} onOpenChange={(open) => { if (!open) setDeleteTarget(null) }}>
        <DialogContent className="max-w-sm bg-[#0c1326] border-white/10 text-[#dfe4fe]">
          <DialogHeader>
            <DialogTitle className="font-headline text-[#dfe4fe]">Delete Node</DialogTitle>
            <DialogDescription className="text-[#a5aac2]">
              This will permanently delete <strong className="text-[#dfe4fe]">{deleteTarget?.full_name || deleteTarget?.email}</strong> and all their data. This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-2 pt-2">
            <button
              className="px-3 py-2 rounded-lg text-xs font-medium bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors"
              onClick={() => setDeleteTarget(null)}
              disabled={deleting}
            >
              Cancel
            </button>
            <button
              className="px-3 py-2 rounded-lg text-xs font-medium bg-[#ff716c]/15 text-[#ff716c] hover:bg-[#ff716c]/25 transition-colors disabled:opacity-50"
              onClick={handleDelete}
              disabled={deleting}
            >
              {deleting ? "Deleting..." : "Yes, Delete"}
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
