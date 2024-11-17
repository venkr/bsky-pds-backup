#!/bin/bash

MODE="unsafe" # read the docs before changing this
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
ENDPOINT_URL=""
BACKUP_DIR="/home/ubuntu/" # where backups are temporarily written to

# Check if required environment variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$ENDPOINT_URL" ]; then
    echo "Error: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and ENDPOINT_URL must be set"
    exit 1
fi

# define filename which is dd-mm-yyyy-hh-mm-ss
FILENAME="backup-$(date +'%d-%m-%Y-%H-%M-%S').tar"

if [ "$MODE" == "safe" ]; then
    echo "Stopping PDS for safe backup..."
    docker pds stop
fi

tar -cf "${BACKUP_DIR}${FILENAME}" /pds/

if [ "$MODE" == "safe" ]; then
    echo "Starting PDS after backup..."
    docker pds start
fi

# upload it to r2/s3
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws --endpoint-url $ENDPOINT_URL s3 cp "${BACKUP_DIR}${FILENAME}" s3://backups/$FILENAME

# delete the local file
rm "${BACKUP_DIR}${FILENAME}"