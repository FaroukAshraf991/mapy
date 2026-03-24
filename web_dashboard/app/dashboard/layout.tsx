export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="w-64 border-r border-white/5 bg-black/20 backdrop-blur-xl p-6 hidden md:block">
        <div className="flex items-center gap-3 mb-10 px-2">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold">M</div>
          <span className="font-bold tracking-tight">Mapy Admin</span>
        </div>
        
        <nav className="space-y-2">
          <a href="/dashboard" className="flex items-center gap-3 px-4 py-3 rounded-xl bg-blue-600/10 border border-blue-500/20 text-blue-400">
            <span>Dashboard</span>
          </a>
          <a href="/dashboard/users" className="flex items-center gap-3 px-4 py-3 rounded-xl text-white/50 hover:bg-white/5 transition-colors">
            <span>Users</span>
          </a>
          <a href="/dashboard/settings" className="flex items-center gap-3 px-4 py-3 rounded-xl text-white/50 hover:bg-white/5 transition-colors">
            <span>Settings</span>
          </a>
        </nav>
      </aside>

      {/* Content */}
      <main className="flex-1 p-8">
        {children}
      </main>
    </div>
  );
}
