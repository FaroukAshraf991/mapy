"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Input } from "@/components/ui/input"
import { Layers } from "lucide-react"
import { createClient } from "@/lib/supabase"

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError("")

    const supabase = createClient()
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({ email, password })

    if (authError) {
      setError(authError.message)
      setLoading(false)
      return
    }

    // Check admin status
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_admin")
      .eq("id", authData.user.id)
      .single()

    if (!profile?.is_admin) {
      await supabase.auth.signOut()
      setError("Access denied. You are not an admin.")
      setLoading(false)
      return
    }

    router.push("/dashboard")
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-black p-4">
      {/* Background glow */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 rounded-full bg-[#85adff] opacity-[0.04] blur-[120px]" />
      </div>

      <div className="w-full max-w-sm relative">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#85adff] to-[#6c9fff] flex items-center justify-center mb-4">
            <Layers className="h-6 w-6 text-[#002c65]" />
          </div>
          <h1 className="font-headline text-2xl font-bold text-[#dfe4fe] tracking-tight">Mapy Engine</h1>
          <p className="hud-label mt-1">Enterprise HUD · Secure Access</p>
        </div>

        {/* Form card */}
        <div className="content-tile rounded-2xl p-6">
          <div className="mb-5">
            <h2 className="font-headline text-base font-semibold text-[#dfe4fe]">Sign In</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">Authenticate to access the command center</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            {error && (
              <div className="p-3 text-xs rounded-lg bg-[#ff716c]/10 text-[#ff716c] border border-[#ff716c]/20">
                {error}
              </div>
            )}

            <div className="space-y-1.5">
              <label htmlFor="email" className="hud-label">Email Address</label>
              <Input
                id="email"
                type="email"
                placeholder="admin@mapy.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="bg-[#0c1326] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] h-10 focus-visible:ring-[#85adff]/30"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="password" className="hud-label">Password</label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="bg-[#0c1326] border-white/10 text-[#dfe4fe] placeholder:text-[#6f758b] h-10 focus-visible:ring-[#85adff]/30"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 rounded-xl text-sm font-medium bg-gradient-to-r from-[#85adff] to-[#6c9fff] text-[#002c65] hover:opacity-90 transition-opacity disabled:opacity-50 mt-2"
            >
              {loading ? "Authenticating..." : "Sign In"}
            </button>
          </form>
        </div>

        <p className="text-center hud-label mt-5">Mapy Engine v2.4 · Restricted Access</p>
      </div>
    </div>
  )
}
