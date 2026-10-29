# Deploying Socials to Fly.io

One always-on shared-cpu-1x 256 MB machine in London (lhr), plus a 1 GB volume. About $2.35/month.
Measured locally: about 51 MB RSS idle and 55 MB under 200 parallel requests, so 256 MB has plenty of room.

flyctl is installed on the box at `~/.fly/bin/flyctl` (`fly` works too after `source ~/.bashrc`).

## 0. Sign in (Lee, once)
    fly auth login        # or: export FLY_API_TOKEN=... (don't commit it)
    fly auth whoami

## 1. Create the app (one time)
    cd /workspace/socials
    fly apps create socials
    # If the name is taken:
    #   fly apps create socials-lee && sed -i 's/^app = "socials"/app = "socials-lee"/' fly.toml

## 2. Create the volume (one time, it must be in the same region)
    fly volumes create socials_data --size 1 --region lhr --yes

## 3. Secrets (one time; nothing is echoed or saved to a file)
ADMIN_PASSWORD is Lee's choice (16+ characters). The prompt keeps it out of shell history:

    read -rsp "Socials admin password (16+ chars): " P && echo && fly secrets set ADMIN_PASSWORD="$P" --stage && unset P

ENCRYPTION_KEY encrypts the stored social-account credentials. Generate it straight into Fly without printing it:

    fly secrets set ENCRYPTION_KEY="$(python3 -c 'import secrets;print(secrets.token_hex(32))')" --stage

(If ENCRYPTION_KEY isn't set, the app makes /data/credentials.key on the volume itself. A Fly secret is better because the key then doesn't sit next to the data. Never change it after accounts are connected, or saved credentials can't be decrypted.)

## 4. Deploy
    fly deploy --ha=false

`--ha=false` keeps it at exactly one machine. Socials uses one SQLite database and must never run two machines.

## 5. Check
    fly status
    curl -sI https://socials.fly.dev/ | head -1     # expect 200 (or socials-lee.fly.dev)
    curl -sI http://socials.fly.dev/ | head -3      # expect a redirect to https
    fly logs

Open https://socials.fly.dev/app and sign in with the admin password.

## Notes
- Never scale above 1 machine (`fly scale count 1`). The app locks the database to a single process.
- Backups: `fly ssh console -C "python -c \"import sqlite3;s=sqlite3.connect('/data/socials.sqlite');s.backup(sqlite3.connect('/data/backup.sqlite'))\""`, then `fly ssh sftp get /data/backup.sqlite`. Fly also snapshots volumes daily.
- Custom domain later: `fly certs add socials.example.com`, then add the DNS records it shows.
