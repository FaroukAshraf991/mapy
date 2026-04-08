import { Sidebar } from "@/components/sidebar"
import { Header } from "@/components/header"
import { AuthProvider } from "@/lib/auth-context"

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <div className="min-h-screen bg-black">
        <Sidebar />
        <div className="md:ml-64">
          <Header />
          <main className="p-4 md:p-6">{children}</main>
        </div>
      </div>
    </AuthProvider>
  )
}
