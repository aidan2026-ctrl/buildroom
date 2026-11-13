# Buildroom: going live

Right now the site runs in **demo mode**: it works, but everything is saved only in the browser you're using.
To make it a real network where everyone sees the same posts and messages, connect it to Supabase (free).

## 1. Create the database (about 5 minutes)
1. Go to supabase.com and sign up (GitHub or Google login is fine).
2. Click **New project**. Pick any name and a database password (save it somewhere), and choose the region closest to you (Central US).
3. Wait about a minute for it to finish setting up.
4. In the left sidebar, open **SQL Editor**, then **New query**.
5. Open `schema.sql` from this folder, copy everything, paste it in, and click **Run**. It should say "Success".

## 2. Connect the site
1. In Supabase, go to **Project Settings → API** (sometimes under "Data API" / "API Keys").
2. Copy the **Project URL** and the **anon / public** key. Never use the `service_role` key, which is secret.
3. Open `config.js` in this folder with a text editor and paste them in:
   ```
   SUPABASE_URL: "https://xxxx.supabase.co",
   SUPABASE_ANON_KEY: "eyJ...",
   ```
4. Save the file.

## 3. Tell Supabase your site address
1. In Supabase, open **Authentication → URL Configuration**.
2. Set **Site URL** to your Netlify address, e.g. `https://rococo-douhua-517ba7.netlify.app`.
   This makes the "confirm your email" link send people back to your site.

## 4. Upload
Drag this whole folder onto Netlify (your project → **Deploys** → the drop box at the bottom).
Then open your site, sign up, and make your page.

## Moderation
- Reports land in Supabase: **Table Editor → reports**.
- To remove a post: **Table Editor → posts**, then delete the row.
- To ban someone: **Authentication → Users**, then delete the user. Their page, posts and messages go with them.

## Changing things
- Site name, default background video, minimum age: `config.js`.
- Everyone sets their own background video, bio, projects, music and links from **My page → Edit my page**.
