"use client"

import { useEffect, useState } from "react"
import { Separator } from "@/components/ui/separator"
import { Switch } from "@/components/ui/switch"
import { Monitor, LayoutDashboard, RefreshCw, Calendar, Check } from "lucide-react"

const STORAGE_KEY = "mapy_dashboard_prefs"

interface DashboardPrefs {
  defaultPage: string
  rowsPerPage: number
  dateFormat: string
  autoRefresh: boolean
  refreshInterval: number
  compactMode: boolean
  showTelemetry: boolean
}

const defaults: DashboardPrefs = {
  defaultPage: "/dashboard",
  rowsPerPage: 25,
  dateFormat: "MMM D, YYYY",
  autoRefresh: true,
  refreshInterval: 30,
  compactMode: false,
  showTelemetry: true,
}

function loadPrefs(): DashboardPrefs {
  if (typeof window === "undefined") return defaults
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? { ...defaults, ...JSON.parse(raw) } : defaults
  } catch { return defaults }
}

export default function DashboardSettingsPage() {
  const [prefs, setPrefs] = useState<DashboardPrefs>(defaults)
  const [saved, setSaved] = useState(false)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setPrefs(loadPrefs())
    setMounted(true)
  }, [])

  const update = <K extends keyof DashboardPrefs>(key: K, value: DashboardPrefs[K]) => {
    setPrefs(p => ({ ...p, [key]: value }))
    setSaved(false)
  }

  const handleSave = () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs))
    setSaved(true)
    setTimeout(() => setSaved(false), 2500)
  }

  const handleReset = () => {
    setPrefs(defaults)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults))
    setSaved(true)
    setTimeout(() => setSaved(false), 2500)
  }

  if (!mounted) return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Dashboard Settings</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Display preferences and interface configuration</p>
      </div>
      <div className="grid gap-5 grid-cols-1 lg:grid-cols-2">
        {[...Array(3)].map((_, i) => <div key={i} className="content-tile rounded-xl h-64 animate-pulse" />)}
      </div>
    </div>
  )

  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Dashboard Settings</h1>
        <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">Display preferences and interface configuration</p>
      </div>

      <div className="grid gap-5 grid-cols-1 lg:grid-cols-2">

        {/* Navigation preferences */}
        <div className="content-tile rounded-xl">
          <div className="flex items-center gap-2.5 p-5 border-b border-white/5">
            <div className="p-1.5 rounded-lg bg-[#85adff]/15">
              <LayoutDashboard className="h-4 w-4 text-[#85adff]" />
            </div>
            <div>
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Navigation</h2>
              <p className="text-xs text-[#a5aac2] mt-0.5">Default page and layout preferences</p>
            </div>
          </div>
          <div className="p-5 space-y-5">
            <div>
              <label className="hud-label mb-2 block">Default Landing Page</label>
              <div className="space-y-1.5">
                {[
                  { value: "/dashboard", label: "Dashboard Overview" },
                  { value: "/users", label: "User Management" },
                  { value: "/maps", label: "Spatial Operations" },
                  { value: "/analytics", label: "Analytics" },
                ].map(opt => (
                  <button
                    key={opt.value}
                    onClick={() => update("defaultPage", opt.value)}
                    className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-sm transition-all ${
                      prefs.defaultPage === opt.value
                        ? "bg-[#85adff]/15 text-[#85adff] border border-[#85adff]/30"
                        : "bg-[#0c1326] text-[#a5aac2] hover:bg-[#11192e] hover:text-[#dfe4fe] border border-transparent"
                    }`}
                  >
                    <span>{opt.label}</span>
                    {prefs.defaultPage === opt.value && <Check className="h-3.5 w-3.5" />}
                  </button>
                ))}
              </div>
            </div>

            <Separator className="bg-white/5" />

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[#dfe4fe]">Compact Mode</p>
                <p className="hud-label mt-0.5">Reduce padding in tables</p>
              </div>
              <Switch
                checked={prefs.compactMode}
                onCheckedChange={(v) => update("compactMode", v)}
              />
            </div>
          </div>
        </div>

        {/* Data display */}
        <div className="content-tile rounded-xl">
          <div className="flex items-center gap-2.5 p-5 border-b border-white/5">
            <div className="p-1.5 rounded-lg bg-[#81ecff]/15">
              <Monitor className="h-4 w-4 text-[#81ecff]" />
            </div>
            <div>
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Data Display</h2>
              <p className="text-xs text-[#a5aac2] mt-0.5">How data is shown across pages</p>
            </div>
          </div>
          <div className="p-5 space-y-5">
            <div>
              <label className="hud-label mb-2 block">Rows Per Page (User Table)</label>
              <div className="flex gap-2">
                {[10, 25, 50, 100].map(n => (
                  <button
                    key={n}
                    onClick={() => update("rowsPerPage", n)}
                    className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${
                      prefs.rowsPerPage === n
                        ? "bg-[#85adff]/15 text-[#85adff] border border-[#85adff]/30"
                        : "bg-[#0c1326] text-[#a5aac2] hover:bg-[#11192e] hover:text-[#dfe4fe] border border-transparent"
                    }`}
                  >
                    {n}
                  </button>
                ))}
              </div>
            </div>

            <Separator className="bg-white/5" />

            <div>
              <label className="hud-label mb-2 flex items-center gap-1.5">
                <Calendar className="h-3 w-3" /> Date Format
              </label>
              <div className="space-y-1.5">
                {[
                  { value: "MMM D, YYYY", label: "Apr 8, 2026" },
                  { value: "DD/MM/YYYY", label: "08/04/2026" },
                  { value: "MM/DD/YYYY", label: "04/08/2026" },
                  { value: "YYYY-MM-DD", label: "2026-04-08" },
                ].map(opt => (
                  <button
                    key={opt.value}
                    onClick={() => update("dateFormat", opt.value)}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm transition-all ${
                      prefs.dateFormat === opt.value
                        ? "bg-[#85adff]/15 text-[#85adff] border border-[#85adff]/30"
                        : "bg-[#0c1326] text-[#a5aac2] hover:bg-[#11192e] hover:text-[#dfe4fe] border border-transparent"
                    }`}
                  >
                    <span className="font-label">{opt.label}</span>
                    {prefs.dateFormat === opt.value && <Check className="h-3.5 w-3.5" />}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Live data */}
        <div className="content-tile rounded-xl">
          <div className="flex items-center gap-2.5 p-5 border-b border-white/5">
            <div className="p-1.5 rounded-lg bg-[#2ff801]/15">
              <RefreshCw className="h-4 w-4 text-[#2ff801]" />
            </div>
            <div>
              <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Live Data</h2>
              <p className="text-xs text-[#a5aac2] mt-0.5">Sync and telemetry preferences</p>
            </div>
          </div>
          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[#dfe4fe]">Auto-Refresh</p>
                <p className="hud-label mt-0.5">Automatically refresh live data</p>
              </div>
              <Switch
                checked={prefs.autoRefresh}
                onCheckedChange={(v) => update("autoRefresh", v)}
              />
            </div>

            {prefs.autoRefresh && (
              <>
                <Separator className="bg-white/5" />
                <div>
                  <label className="hud-label mb-2 block">Refresh Interval</label>
                  <div className="flex gap-2">
                    {[{ v: 15, l: "15s" }, { v: 30, l: "30s" }, { v: 60, l: "1m" }, { v: 120, l: "2m" }].map(({ v, l }) => (
                      <button
                        key={v}
                        onClick={() => update("refreshInterval", v)}
                        className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${
                          prefs.refreshInterval === v
                            ? "bg-[#2ff801]/15 text-[#2ff801] border border-[#2ff801]/30"
                            : "bg-[#0c1326] text-[#a5aac2] hover:bg-[#11192e] hover:text-[#dfe4fe] border border-transparent"
                        }`}
                      >
                        {l}
                      </button>
                    ))}
                  </div>
                </div>
              </>
            )}

            <Separator className="bg-white/5" />

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[#dfe4fe]">Show Telemetry Panel</p>
                <p className="hud-label mt-0.5">Supabase sync status on dashboard</p>
              </div>
              <Switch
                checked={prefs.showTelemetry}
                onCheckedChange={(v) => update("showTelemetry", v)}
              />
            </div>
          </div>
        </div>

      </div>

      {/* Save bar */}
      <div className="content-tile rounded-xl p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <p className="text-sm font-medium text-[#dfe4fe]">Preferences saved locally</p>
          <p className="hud-label mt-0.5">Settings apply to this browser — changes take effect immediately</p>
        </div>
        <div className="flex gap-2 w-full sm:w-auto">
          <button
            onClick={handleReset}
            className="flex-1 sm:flex-none px-4 py-2.5 rounded-xl text-xs font-medium bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors border border-white/10"
          >
            Reset to Defaults
          </button>
          <button
            onClick={handleSave}
            className="flex-1 sm:flex-none px-4 py-2.5 rounded-xl text-xs font-medium bg-gradient-to-r from-[#85adff] to-[#6c9fff] text-[#002c65] hover:opacity-90 transition-opacity flex items-center justify-center gap-1.5"
          >
            {saved ? <><Check className="h-3.5 w-3.5" /> Saved!</> : "Save Preferences"}
          </button>
        </div>
      </div>
    </div>
  )
}
