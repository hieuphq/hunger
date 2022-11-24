#!/bin/sh
set -e

# Run the migration first using the custom release task
# /opt/hunger/bin/hunger eval "Crawler.Release.migrate"

# Launch the OTP release and replace the caller as Process #1 in the container
exec /opt/hunger/bin/hunger "$@"
