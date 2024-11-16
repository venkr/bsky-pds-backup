So, to do a backup, you need some pieces:
- a) you need to copy over the data. It lives in the `pds` folder
- b) you need to zip it up into a single archive, and upload it somewhere
- c) you need a way to trigger this backup script at some interval
- d) you need some retention story etc on your backup storage: ie: you don't wanna grow your dataset without bounds

Here's some notes:
a) is kinda hard - since the /pds/ is actually a collection of SQLite databases. 
Some options on copying it:

1) just tar the whole /pds/ folder up. the issue: this can cause db corruption, specifically: if you get unlucky enough to copy over a .sqlite file and a .sqlite-wal file in a weird order. read this for more: https://www.sqlite.org/howtocorrupt.html

2) stop the server, copy the files over, restart the server. this is `docker pds stop`, then tar, then `docker pds start`.

3) use sqlite's built in tools, but this is tricky since there's tonnes of small dbs. you'd need to recursively copy, but skip all files with "sqlite" in the name, and instead run `sqlite3 /pds/path/to/database.sqlite "VACUUM INTO '/pds-backup/path/to/database.sqlite'"`

b) is easy just tar it up. the upload is usually to s3 or r2. for that we use aws cli, it'd be nice if we could just curl instead though.

c) we just use crontab for this

d) you have two major options:

1) have file names set up that overwrite old backups, eg: use the day of the month as the filename.

2) have some sort of retention policy specified on the bucket