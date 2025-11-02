#!/bin/bash
set -e
echo "Starting OctoPrint with Orange Pi GPIO support..."

# Run GPIO setup
if [ -x "/usr/local/bin/gpio-setup.sh" ]; then
    /usr/local/bin/gpio-setup.sh
fi

# Start OctoPrint
exec octoprint serve --iknowwhatimdoing
