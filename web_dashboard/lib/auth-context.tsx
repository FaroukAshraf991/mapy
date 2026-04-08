"use client"

import { createContext, useContext, useEffect, useState, useCallback } from "react"
import { useRouter } from "next/navigation"
import { createClient } from "./supabase"
import type { User } from "@supabase/supabase-js"

export interface Profile {
  id: string
  full_name: string | null
  username: string | null
  is_admin: boolean
  home_lat: number | null
  home_lon: number | null
  work_lat: number | null
  work_lon: number | null
  custom_pins: { label: string; lat: number; lon: number }[]
  updated_at: string
  date_of_birth: string | null
}

interface AuthContextType {
  user: User | null
  profile: Profile | null
  loading: boolean
  signOut: () => Promise<void>
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  loading: true,
  signOut: async () => {},
  refreshProfile: async () => {},
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  const fetchProfile = useCallback(async (userId: string) => {
    const [{ data: profileData }, { data: { user: authUser } }] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).single(),
      supabase.auth.getUser(),
    ])
    if (profileData) {
      const meta = authUser?.user_metadata ?? {}
      profileData.full_name = profileData.full_name ?? meta.full_name ?? null
      profileData.date_of_birth = profileData.date_of_birth ?? meta.date_of_birth ?? null
    }
    setProfile(profileData)
  }, [supabase])

  const refreshProfile = useCallback(async () => {
    if (user) await fetchProfile(user.id)
  }, [user, fetchProfile])

  useEffect(() => {
    const init = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) {
        router.replace("/login")
        setLoading(false)
        return
      }
      setUser(session.user)
      await fetchProfile(session.user.id)
      setLoading(false)
    }
    init()

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!session) {
        setUser(null)
        setProfile(null)
        router.replace("/login")
      } else {
        setUser(session.user)
        await fetchProfile(session.user.id)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  const signOut = async () => {
    await supabase.auth.signOut()
    router.replace("/login")
  }

  return (
    <AuthContext.Provider value={{ user, profile, loading, signOut, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
