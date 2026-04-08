"use client"

import { useState } from "react"
import { FileText, Download, Calendar, Filter, Printer, ShieldCheck, X } from "lucide-react"

const ALL_REPORTS = [
  { id: 1, name: "User Activity Report", type: "Users", date: "2024-01-20", size: "245 KB" },
  { id: 2, name: "Map Usage Analytics", type: "Maps", date: "2024-01-19", size: "128 KB" },
  { id: 3, name: "Revenue Report", type: "Finance", date: "2024-01-18", size: "512 KB" },
  { id: 4, name: "System Performance", type: "System", date: "2024-01-17", size: "89 KB" },
  { id: 5, name: "Location Analytics", type: "Analytics", date: "2024-01-16", size: "320 KB" },
  { id: 6, name: "Auth Audit Log", type: "System", date: "2024-01-15", size: "156 KB" },
  { id: 7, name: "Pin Usage Report", type: "Maps", date: "2024-01-14", size: "98 KB" },
]

const TYPE_COLOR: Record<string, string> = {
  Users: "#85adff",
  Maps: "#2ff801",
  Finance: "#81ecff",
  System: "#a5aac2",
  Analytics: "#85adff",
}

type StatFilter = "all" | "week" | "downloads" | "size"

export default function ReportsPage() {
  const [typeFilter, setTypeFilter] = useState<string | null>(null)
  const [sortBy, setSortBy] = useState<"date" | "size" | "name">("date")
  const [downloading, setDownloading] = useState<number | null>(null)

  const filtered = ALL_REPORTS
    .filter(r => !typeFilter || r.type === typeFilter)
    .sort((a, b) => {
      if (sortBy === "size") return parseFloat(b.size) - parseFloat(a.size)
      if (sortBy === "name") return a.name.localeCompare(b.name)
      return new Date(b.date).getTime() - new Date(a.date).getTime()
    })

  const thisWeek = ALL_REPORTS.filter(r => {
    const d = new Date(r.date)
    const now = new Date()
    const diff = (now.getTime() - d.getTime()) / (1000 * 60 * 60 * 24 * 7)
    return diff <= 4 // within last 4 weeks (demo data is old)
  }).length

  const handleDownload = (id: number, name: string) => {
    setDownloading(id)
    setTimeout(() => {
      setDownloading(null)
      // Create a mock download
      const blob = new Blob([`Report: ${name}\nGenerated: ${new Date().toISOString()}\n\nThis is a demo report export.`], { type: "text/plain" })
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `${name.replace(/\s+/g, "_")}.txt`
      a.click()
      URL.revokeObjectURL(url)
    }, 800)
  }

  const handleExportAll = () => {
    const content = filtered.map(r => `${r.name} | ${r.type} | ${r.date} | ${r.size}`).join("\n")
    const blob = new Blob([`Mapy Engine — Audit Export\n${new Date().toISOString()}\n\n${content}`], { type: "text/plain" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "mapy_audit_export.txt"
    a.click()
    URL.revokeObjectURL(url)
  }

  const statTiles = [
    { label: "Total Reports", value: ALL_REPORTS.length, icon: FileText, accent: "#85adff", action: () => setTypeFilter(null), desc: "All types" },
    { label: "This Period", value: thisWeek, icon: Calendar, accent: "#2ff801", action: () => setSortBy("date"), desc: "Sort by date" },
    { label: "Sort by Size", value: `${Math.max(...ALL_REPORTS.map(r => parseFloat(r.size)))} KB`, icon: Download, accent: "#81ecff", action: () => setSortBy("size"), desc: "Largest first" },
    { label: "Compliance", value: ALL_REPORTS.filter(r => r.type === "System").length, icon: ShieldCheck, accent: "#85adff", action: () => setTypeFilter("System"), desc: "System reports" },
  ]

  return (
    <div className="space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <h1 className="font-headline text-2xl sm:text-3xl font-bold text-[#dfe4fe] tracking-tight">Audit & Compliance</h1>
          <p className="text-xs font-label text-[#6f758b] uppercase tracking-widest mt-1">System telemetry logs and compliance records</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setTypeFilter(null)}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors border border-white/10"
          >
            <Filter className="h-3.5 w-3.5" /> {typeFilter ? `Clear Filter` : "Filter"}
          </button>
          <button
            onClick={handleExportAll}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium bg-gradient-to-r from-[#85adff] to-[#6c9fff] text-[#002c65] hover:opacity-90 transition-opacity"
          >
            <Download className="h-3.5 w-3.5" /> Export All
          </button>
        </div>
      </div>

      {/* Stat tiles — click to filter/sort */}
      <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
        {statTiles.map((stat) => (
          <button
            key={stat.label}
            onClick={stat.action}
            className="content-tile rounded-xl p-4 text-left w-full cursor-pointer hover:border-white/15 hover:bg-[#0c1326] transition-all duration-200 active:scale-[0.97]"
          >
            <div className="flex items-center justify-between mb-3">
              <div className="p-1.5 rounded-lg" style={{ background: `${stat.accent}18` }}>
                <stat.icon className="h-3.5 w-3.5" style={{ color: stat.accent }} />
              </div>
            </div>
            <div className="font-headline text-xl font-bold text-[#dfe4fe]">{stat.value}</div>
            <p className="hud-label mt-0.5">{stat.label}</p>
            <p className="text-[10px] text-[#85adff] mt-1">{stat.desc} →</p>
          </button>
        ))}
      </div>

      {/* Type filter chips */}
      <div className="flex flex-wrap gap-2">
        {["Users", "Maps", "Finance", "System", "Analytics"].map(type => (
          <button
            key={type}
            onClick={() => setTypeFilter(f => f === type ? null : type)}
            className={`px-3 py-1 rounded-full text-[10px] font-label uppercase tracking-wider transition-colors ${
              typeFilter === type
                ? "border"
                : "bg-white/5 text-[#a5aac2] hover:bg-white/10"
            }`}
            style={typeFilter === type ? {
              background: `${TYPE_COLOR[type]}18`,
              color: TYPE_COLOR[type],
              borderColor: `${TYPE_COLOR[type]}40`,
            } : {}}
          >
            {type}
          </button>
        ))}
        <button
          onClick={() => setSortBy(s => s === "date" ? "name" : "date")}
          className="px-3 py-1 rounded-full text-[10px] font-label uppercase tracking-wider bg-white/5 text-[#a5aac2] hover:bg-white/10 transition-colors"
        >
          Sort: {sortBy}
        </button>
      </div>

      {/* Reports table */}
      <div className="content-tile rounded-xl">
        <div className="p-5 border-b border-white/5 flex items-center justify-between">
          <div>
            <h2 className="font-headline text-sm font-semibold text-[#dfe4fe] uppercase tracking-widest">Audit Logs</h2>
            <p className="text-xs text-[#a5aac2] mt-0.5">
              Showing {filtered.length} of {ALL_REPORTS.length} records
              {typeFilter ? ` · ${typeFilter}` : ""}
            </p>
          </div>
          {typeFilter && (
            <button onClick={() => setTypeFilter(null)} className="flex items-center gap-1 hud-label text-[#ff716c] hover:text-[#dfe4fe] transition-colors">
              <X className="h-3 w-3" /> Clear filter
            </button>
          )}
        </div>
        <div className="p-4 space-y-2">
          {filtered.length === 0 ? (
            <p className="text-sm text-[#a5aac2] text-center py-8">No reports match the current filter.</p>
          ) : filtered.map((report) => (
            <div
              key={report.id}
              className="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3.5 rounded-xl bg-[#0c1326] border border-white/5 hover:bg-[#11192e] transition-colors gap-3"
            >
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="p-2 rounded-lg bg-[#85adff]/10">
                  <FileText className="h-4 w-4 text-[#85adff]" />
                </div>
                <div>
                  <p className="font-medium text-sm text-[#dfe4fe]">{report.name}</p>
                  <div className="flex flex-wrap items-center gap-2 sm:gap-3 mt-0.5">
                    <span className="flex items-center gap-1 hud-label"><Calendar className="h-3 w-3" />{report.date}</span>
                    <span className="hud-label">{report.size}</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-2 ml-11 sm:ml-0">
                <button
                  onClick={() => setTypeFilter(t => t === report.type ? null : report.type)}
                  className="px-2 py-0.5 text-[10px] font-label rounded-full uppercase tracking-wider transition-colors"
                  style={{
                    background: `${TYPE_COLOR[report.type] ?? "#85adff"}18`,
                    color: TYPE_COLOR[report.type] ?? "#85adff",
                  }}
                >
                  {report.type}
                </button>
                <button
                  onClick={() => handleDownload(report.id, report.name)}
                  disabled={downloading === report.id}
                  className="p-1.5 rounded-lg text-[#6f758b] hover:text-[#2ff801] hover:bg-[#2ff801]/10 transition-colors disabled:opacity-50"
                  title="Download"
                >
                  {downloading === report.id
                    ? <span className="text-[10px] font-label text-[#2ff801]">...</span>
                    : <Download className="h-3.5 w-3.5" />}
                </button>
                <button
                  onClick={() => window.print()}
                  className="p-1.5 rounded-lg text-[#6f758b] hover:text-[#dfe4fe] hover:bg-white/5 transition-colors"
                  title="Print"
                >
                  <Printer className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
