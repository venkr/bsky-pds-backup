![alt text](docs/image.png)

# bluesky-pds-backup

This is a simple script + guide to help you set up automatic backups for your bluesky pds instance.

The gist of this is to `tar` and copy the contents of the `/pds` folder to an S3-compatible object storage bucket, based on a cron schedule.

## When to use this?

This isn't the greatest solution, and has some drawbacks we'll get to in a bit.
If you're using a VPS provider that you: a) trust, b) has backups built in - you should just use that! 

The main reasons to use this are:

a) You're using a VPS provider that you don't entirely trust. For example, Oracle Cloud has a generous free tier, and built-in backups, but there are some reports online of accounts being closed (including making it impossible to access backups either)

b) You're using a Raspberry Pi or some other homebrew server, and don't have disk snapshotting available to you.

## Quick set-up

1. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) on your server:
```
sudo snap install aws-cli --classic
```

2. Download the script:
```
wget https://raw.githubusercontent.com/venkr/bsky-pds-backup/refs/heads/main/backup.sh
chmod +x backup.sh
```

3. Set up an S3-compatible object storage bucket. I recommend [R2 by Cloudflare](https://developers.cloudflare.com/r2/), and then modify the script to add in your `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `ENDPOINT_URL`.

4. Test it out with a one-off backup to make sure it adds the file to your bucket:
```
./backup.sh
```

5. Set up a cron job to run the backup on a schedule. Run:
```
sudo crontab -e
```

and then add something like (for a nightly backup):
```
0 0 * * * /home/ubuntu/backup.sh >> /home/ubuntu/backup.logs 2>&1
```

## Additional steps

- You likely are going to want a retention policy on your backups. Both R2 and S3 let you do this from the GUI, you probably want to set it so that old backups are deleted after a week or month or so. 


## Restoring your backup

- Download you backup file, and copy it onto your server.

- Stop your PDS and save a copy of your old PDS data if it still exists:
```
sudo docker stop pds
sudo mv /pds /pds-old
```

- Untar your pds data backup and move it over
```
tar -xf <your-backup-filename>.tar
mv pds /pds
```

- Start your PDS
```
sudo docker stop pds
```

Note: I've not tested this flow when moving to a new server, only replacing my existing PDS data with a backup. Please let me know if you find anything different when testing that out.

## Caveats & better approaches

This approach is pretty naive: it just tars up the entire /pds/ folder. 
In theory, this is not safe - if you get unlucky to copy over a `.sqlite` file and a `.sqlite-wal` file at different times during a transaction, you could end up with database corruption. [Read more here.](https://www.sqlite.org/howtocorrupt.html)

On the other hand: VPS provider disk snapshots happen at a single point in time, and are usually equivalent to a power outage, hence they're usually safe with SQLite + cannot corrupt the database.

In practice: I've tested all SQLite databases in a few backups I've made of a PDS with ~20 user accounts, and they've all been perfectly fine. You can also validate the integrity of all databases within a backup by downloading it, untarring it, and running the validate.sh on the resulting /pds/ folder.

However, as your PDS scales, this may become more of a concern, here's some notes about better steps:
- The included script has a "safe" mode - which stops the PDS server before copying over the files, which should guarantee no SQLite corruption. However: this makes your server unavailable for a couple of seconds, which is undesirable.
- Using SQLite's built-in backup tools is the right solution here, it's a little annoying since you have to do it recursively, and it's slower, but you'd need to recursively call `sudo sqlite3 /pds/{dir}/store.sqlite "VACUUM INTO '/home/ubuntu/backup/pds/{dir}/store.sqlite';"` for each database, while calling a regular `cp` on all non-sqlite files.

