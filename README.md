# FieldOps — Field Marketing Platform

A complete field marketing management app for your team. Free to host, no servers needed.

---

## What's in the box

| Module | What it does |
|---|---|
| Dashboard | Live KPIs, upcoming events, pending actions |
| Events | Schedule, track, and complete demos |
| Ambassadors | Roster, ratings, assignment |
| Reports | Post-event reports with approval workflow |
| Payments | Log, approve, and pay ambassadors |
| Analytics | Sales lift charts, retailer breakdown |
| Surveys | Shopper feedback collection |
| Store Directory | Retailer locations and manager contacts |

---

## Step 1 — Create your free Supabase database (5 min)

Supabase is a free PostgreSQL database that powers the app.

1. Go to **https://supabase.com** and click **Start for free**
2. Sign up with GitHub or email
3. Click **New project**
   - Name it: `fieldops`
   - Set a database password (save it somewhere safe)
   - Choose the region closest to your team
   - Click **Create new project** (takes ~2 min)
4. Once the project is ready, click **SQL Editor** in the left sidebar
5. Click **New query**
6. Open the file `schema.sql` from this folder, copy **all** of it, paste it into the editor
7. Click **Run** (green button)
   - You should see "Success. No rows returned"
   - This creates all your tables and loads sample data

8. Now get your credentials:
   - Click **Settings** (gear icon, bottom left)
   - Click **API**
   - Copy your **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - Copy your **anon public** key (long string starting with `eyJ...`)
   - Keep this tab open — you'll paste these into the app

---

## Step 2 — Create your free GitHub account (2 min, skip if you have one)

1. Go to **https://github.com** and click **Sign up**
2. Enter your email, create a password, choose a username
3. Verify your email

---

## Step 3 — Upload your files to GitHub (3 min)

1. Go to **https://github.com** and log in
2. Click the **+** button (top right) → **New repository**
3. Fill in:
   - Repository name: `fieldops`
   - Description: `Field Marketing Platform`
   - Set to **Public** ← required for free GitHub Pages hosting
   - Check **Add a README file**
   - Click **Create repository**

4. You're now in your new repo. Click **Add file** → **Upload files**

5. Drag and drop BOTH files into the upload area:
   - `index.html`
   - `schema.sql`

6. At the bottom, type a commit message: `Add FieldOps app`

7. Click **Commit changes**

---

## Step 4 — Enable GitHub Pages (free hosting) (2 min)

1. In your repo, click **Settings** (top tab, not the sidebar gear)
2. Scroll down to **Pages** in the left sidebar
3. Under **Source**, select **Deploy from a branch**
4. Under **Branch**, select `main` and folder `/root`
5. Click **Save**
6. Wait about 60 seconds, then refresh the page
7. You'll see a green banner: **"Your site is live at https://YOUR-USERNAME.github.io/fieldops"**

**That's your team URL.** Share it with everyone.

---

## Step 5 — First launch

1. Open your URL: `https://YOUR-USERNAME.github.io/fieldops`
2. You'll see the **FieldOps Setup** screen
3. Paste in:
   - Your **Supabase Project URL**
   - Your **Supabase anon public key**
   - Your name and role
4. Click **Launch FieldOps**
5. The app loads with your sample data

**Each team member does this setup once on their own device.** The credentials are saved in their browser (localStorage) — not on any server.

---

## Step 6 — Share with your team

Send your team this message:

> Hey team — our new field marketing platform is live!
> 
> Go to: **https://YOUR-USERNAME.github.io/fieldops**
> 
> When it asks for credentials, use:
> - URL: `https://YOUR-PROJECT.supabase.co`
> - Key: `eyJ...` (paste the anon key here)
> 
> Enter your own name and role. All data is shared in real time.

---

## Making updates

When you want to change the app:

1. Edit `index.html` on your computer
2. Go to your GitHub repo
3. Click `index.html` → the pencil icon (Edit) → paste your updated code
4. Click **Commit changes**
5. GitHub Pages updates automatically within ~30 seconds

---

## Troubleshooting

**The app shows a blank page or error**
- Open your browser console (F12 → Console tab) and check for errors
- Make sure you pasted the full Supabase URL including `https://`

**"Could not load data" error**
- Double-check your Supabase URL and anon key — no extra spaces
- Make sure you ran the `schema.sql` successfully in Supabase

**Need to re-enter credentials**
- Open browser console and type: `resetConfig()` then press Enter

**Want to clear sample data**
- Go to Supabase → Table Editor → select each table → Delete all rows

**Want to add a custom domain (e.g. fieldops.yourcompany.com)**
- In GitHub Pages settings, enter your domain under "Custom domain"
- Add a CNAME record with your domain registrar pointing to `YOUR-USERNAME.github.io`

---

## Costs

| Service | Free tier | Limit |
|---|---|---|
| GitHub Pages | Always free | Unlimited |
| Supabase | Free forever | 500MB storage, 50,000 rows, 2GB bandwidth/mo |

For a field marketing team, you will not hit these limits.

---

## Files in this project

```
fieldops/
├── index.html   ← The entire app (open this in a browser)
├── schema.sql   ← Run once in Supabase to create the database
└── README.md    ← This file
```
