"use client"

import { useEffect, useState } from "react"
import { Input } from "@/components/ui/input"
import { Separator } from "@/components/ui/separator"
import { User, Shield, Check, MapPin, Pin, Cake } from "lucide-react"
import { createClient } from "@/lib/supabase"
import { useAuth } from "@/lib/auth-context"
import { cn } from "@/lib/utils"

export default function AccountSettingsPage() {
  const { user, profile, refreshProfile } = useAuth()
  const [fullName, setFullName] = useState("")
  const [username, setUsername] = useState("")
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null)

  useEffect(() => {
    if (profile) {
      setFullName(profile.full_name ?? "")
      setUsername(profile.username ?? "")
    }
  }, [profile])

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return
    setSaving(true)
    setMessage(null)

    const supabase = createClient()
    const { error } = await supabase
      .from("profiles")
      .update({ full_name: fullName || null, username: username || null })
      .eq("id", user.id)

    if (error) {
      setMessage({ type: "error", text: error.message })
    } else {
      setMessage({ type: "success", text: "Profile updated successfully." })
      await refreshProfile()
    }
    setSaving(false)
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Account Settings</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Admin profile and security configuration</p>
      </div>

      <div className="grid gap-5 grid-cols-1 lg:grid-cols-2">
        {/* Profile editing */}
        <div className="content-tile rounded-xl">
          <div className="flex items-center gap-2.5 p-5 border-b border-white/5">
            <div className="p-1.5 rounded-lg bg-[#85adff]/15">
              <User className="h-4 w-4 text-[#85adff]" />
            </div>
            <div>
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Profile</h2>
              <p className="text-xs text-[#a5aac2] mt-0.5">Update your name and username</p>
            </div>
          </div>
          <div className="p-5">
            <form onSubmit={handleSave} className="space-y-4">
              {message && (
                <div className={cn(
                  "p-3 text-xs rounded-lg border flex items-center gap-2",
                  message.type === "success"
                    ? "bg-[#2ff801]/10 text-[#2ff801] border-[#2ff801]/20"
                    : "bg-[#ff716c]/10 text-[#ff716c] border-[#ff716c]/20"
                )}>
                  {message.type === "success" && <Check className="h-3.5 w-3.5 shrink-0" />}
                  {message.text}
                </div>
              )}

              <div className="space-y-1.5">
                <label className="hud-label">Email (read-only)</label>
                <Input
                  value={user?.email ?? ""}
                  disabled
                  className="bg-[#0c1326] border-white/5 text-[#6f758b] opacity-60 h-9"
                />
                <p className="hud-label">Email can only be changed via the User Management page.</p>
              </div>

              <div className="space-y-1.5">
                <label className="hud-label">Full Name</label>
                <Input
                  placeholder="Your full name"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="bg-[#0c1326] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] h-9 focus-visible:ring-[#85adff]/30"
                />
              </div>

              <div className="space-y-1.5">
                <label className="hud-label">Username</label>
                <Input
                  placeholder="username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="bg-[#0c1326] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] h-9 focus-visible:ring-[#85adff]/30"
                />
              </div>

              <button
                type="submit"
                disabled={saving}
                className="w-full py-2 rounded-xl text-xs font-medium bg-gradient-to-r from-[#85adff] to-[#6c9fff] text-[#002c65] hover:opacity-90 transition-opacity disabled:opacity-50"
              >
                {saving ? "Saving..." : "Save Profile"}
              </button>
            </form>
          </div>
        </div>

        {/* Account Info */}
        <div className="content-tile rounded-xl">
          <div className="flex items-center gap-2.5 p-5 border-b border-white/5">
            <div className="p-1.5 rounded-lg bg-[#81ecff]/15">
              <Shield className="h-4 w-4 text-[#81ecff]" />
            </div>
            <div>
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Account Info</h2>
              <p className="text-xs text-[#a5aac2] mt-0.5">Your node identity and access details</p>
            </div>
          </div>
          <div className="p-5 space-y-4">
            <div>
              <p className="hud-label mb-1">Node ID</p>
              <p className="text-xs text-[#a5aac2] font-label break-all">{user?.id ?? "—"}</p>
            </div>

            <Separator className="bg-white/5" />

            <div>
              <p className="hud-label mb-1.5">Access Level</p>
              <span className={cn(
                "inline-flex items-center gap-1.5 px-2.5 py-1 text-[10px] font-label rounded-full uppercase tracking-wider",
                profile?.is_admin
                  ? "bg-[#85adff]/15 text-[#85adff]"
                  : "bg-white/5 text-[#a5aac2]"
              )}>
                <Shield className="h-2.5 w-2.5" />
                {profile?.is_admin ? "System Admin" : "Standard User"}
              </span>
            </div>

            <Separator className="bg-white/5" />

            {profile?.date_of_birth && (
              <>
                <div>
                  <p className="hud-label mb-1 flex items-center gap-1.5"><Cake className="h-3 w-3" /> Date of Birth</p>
                  <p className="text-sm text-[#dfe4fe]">
                    {new Date(profile.date_of_birth).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
                  </p>
                </div>
                <Separator className="bg-white/5" />
              </>
            )}

            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 rounded-lg bg-[#0c1326]">
                <p className="hud-label mb-1 flex items-center gap-1"><MapPin className="h-2.5 w-2.5" /> Home Anchor</p>
                <p className="text-xs text-[#dfe4fe]">
                  {profile?.home_lat
                    ? `${profile.home_lat.toFixed(4)}, ${profile.home_lon?.toFixed(4)}`
                    : <span className="text-[#6f758b]">Not set</span>}
                </p>
              </div>
              <div className="p-3 rounded-lg bg-[#0c1326]">
                <p className="hud-label mb-1 flex items-center gap-1"><MapPin className="h-2.5 w-2.5" /> Work Beacon</p>
                <p className="text-xs text-[#dfe4fe]">
                  {profile?.work_lat
                    ? `${profile.work_lat.toFixed(4)}, ${profile.work_lon?.toFixed(4)}`
                    : <span className="text-[#6f758b]">Not set</span>}
                </p>
              </div>
            </div>

            <div className="p-3 rounded-lg bg-[#0c1326] flex items-center gap-2">
              <Pin className="h-3 w-3 text-[#81ecff]" />
              <span className="text-xs text-[#dfe4fe]">
                {Array.isArray(profile?.custom_pins) ? profile.custom_pins.length : 0} custom waypoints saved
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
