import { getSupabaseAdmin } from "@/lib/supabase";
import { format } from "date-fns";

export const dynamic = 'force-dynamic';

export default async function UsersPage() {
  const supabaseAdmin = getSupabaseAdmin();
  
  // Fetch users from Auth (requires Service Role Key)
  let users: any[] = [];
  try {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) throw error;
    users = data.users;
  } catch (e) {
    console.error("Failed to fetch users (check service role key):", e);
  }

  return (
    <div className="space-y-8">
      <header className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">User Directory</h1>
          <p className="text-white/50 mt-1">Manage all application users and permissions.</p>
        </div>
        <div className="flex gap-3">
          <input 
            type="text" 
            placeholder="Search users..." 
            className="px-4 py-2 rounded-xl bg-white/5 border border-white/10 focus:outline-none focus:ring-2 focus:ring-blue-500/50 min-w-[240px]"
          />
        </div>
      </header>

      <div className="glass-card overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="border-b border-white/10 bg-white/5 text-sm font-semibold text-white/70">
              <th className="px-6 py-4">User</th>
              <th className="px-6 py-4">Status</th>
              <th className="px-6 py-4">Created</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {users.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-6 py-12 text-center text-white/30 italic">
                  No users found or Service Role Key not configured.
                </td>
              </tr>
            ) : (
              users.map((user) => (
                <tr key={user.id} className="hover:bg-white/5 transition-colors group">
                  <td className="px-6 py-4">
                    <div className="flex flex-col">
                      <span className="font-medium">{user.email}</span>
                      <span className="text-xs text-white/40 font-mono">{user.id.substring(0, 12)}...</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      user.email_confirmed_at ? "bg-green-500/10 text-green-400 border border-green-500/20" : "bg-orange-500/10 text-orange-400 border border-orange-500/20"
                    }`}>
                      {user.email_confirmed_at ? "Verified" : "Pending"}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-white/50">
                    {format(new Date(user.created_at), "MMM dd, yyyy")}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button className="px-3 py-1 rounded-lg bg-white/5 border border-white/10 hover:bg-white/10 text-xs font-bold">
                        Edit
                      </button>
                      <button className="px-3 py-1 rounded-lg bg-blue-600/20 border border-blue-500/30 text-blue-400 hover:bg-blue-600/30 text-xs font-bold transition-all">
                        Reset Pwd
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
