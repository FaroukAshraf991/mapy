import { supabase } from "@/lib/supabase";

export default async function DashboardPage() {
  // Mock stats - in a real app, these would be fetched from Supabase
  const stats = [
    { label: "Total Users", value: "1,284", change: "+12%", color: "text-blue-500" },
    { label: "Active Trips", value: "42", change: "+5%", color: "text-green-500" },
    { label: "Avg. Distance", value: "12.4 km", change: "-2%", color: "text-orange-500" },
  ];

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <header>
        <h1 className="text-3xl font-bold tracking-tight">System Overview</h1>
        <p className="text-white/50 mt-1">Real-time metrics for your Mapy ecosystem.</p>
      </header>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {stats.map((stat, i) => (
          <div key={i} className="glass-card p-6 border border-white/10 hover:border-white/20 transition-all group">
            <p className="text-sm font-medium text-white/50 group-hover:text-white/70 transition-colors">{stat.label}</p>
            <div className="flex items-end gap-2 mt-2">
              <span className="text-3xl font-bold">{stat.value}</span>
              <span className={`text-xs font-bold mb-1 ${stat.change.startsWith("+") ? "text-green-500" : "text-red-500"}`}>
                {stat.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="glass-card p-8">
        <h2 className="text-lg font-bold mb-6">Developer Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <button className="p-4 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 hover:scale-[1.02] transition-all text-sm font-medium">
            Reset All Caches
          </button>
          <button className="p-4 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 hover:scale-[1.02] transition-all text-sm font-medium">
            View System Logs
          </button>
          <button className="p-4 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 hover:scale-[1.02] transition-all text-sm font-medium text-red-400 border-red-400/20">
            Maintenance Mode
          </button>
          <button className="p-4 rounded-2xl bg-blue-600 hover:bg-blue-500 hover:scale-[1.02] transition-all text-sm font-bold">
            Deploy Updates
          </button>
        </div>
      </div>
    </div>
  );
}
