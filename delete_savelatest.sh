EXPS_DIR="logs"

# Find the latest .zip file by creation time
latest_zip=$(find "$EXPS_DIR" -maxdepth 1 -type f -name '*.zip' -printf '%T@ %p\n' | sort -nr | head -1 | awk '{print $2}')

# Delete everything except the latest .zip file
find "$EXPS_DIR" -mindepth 1 ! -path "$latest_zip" -exec rm -rf {} +
