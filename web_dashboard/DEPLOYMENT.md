# 🚀 Final Deployment Checklist: Mapy Developer Dashboard

Follow these 4 steps to get your dashboard live on Vercel.

## ✅ Step 1: Initialize Database (Supabase)
You must add the admin columns to your database so the dashboard can recognize developers.
1.  Go to **[Supabase SQL Editor](https://supabase.com/dashboard/project/_/sql)**.
2.  Click **"New Query"**.
3.  Copy and paste the code from [schema_update.sql](file:///home/farouk991/.gemini/antigravity/brain/1052019d-ce37-47da-981c-aee1d6dea5a8/schema_update.sql).
4.  Run it.

## ✅ Step 2: Create Developer Accounts
Run this command in your terminal to create your first developer login:
```bash
cd web_dashboard
node scripts/bootstrap.js [ADMIN_EMAIL] [ADMIN_PASSWORD] [SERVICE_ROLE_KEY]
```
> [!IMPORTANT]
> Get your **SERVICE_ROLE_KEY** from: **Settings > API > service_role (secret)**. This key is like a master password; never share it!

## ✅ Step 3: Push to GitHub
If you haven't already, push your `web_dashboard` folder to a repository:
```bash
git add web_dashboard/
git commit -m "Add developer dashboard"
git push origin main
```

## ✅ Step 4: Deploy on Vercel
1.  Go to **[Vercel Dashboard](https://vercel.com/new)**.
2.  Import your repository.
3.  **Critical Setting**: In the "Root Directory" field, select `web_dashboard`.
4.  Add **Environment Variables**:
    - `NEXT_PUBLIC_SUPABASE_URL`
    - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
    - `SUPABASE_SERVICE_ROLE_KEY` (The master key from Step 2)
5.  Click **Deploy**.

---

**Need help with a specific step? Just let me know which one!**
