EXPS_DIR="logs"

# Find the latest .zip file by creation time (search recursively)
latest_zip=$(find "$EXPS_DIR" -type f -name '*.zip' -printf '%T@ %p\n' | sort -nr | head -1 | awk '{print $2}')

# Find the latest events.out.tfevents.* file (search recursively)
latest_events_out=$(find "$EXPS_DIR" -type f -name 'events.out.tfevents.*' -printf '%T@ %p\n' | sort -nr | head -1 | awk '{print $2}')

# Delete everything except the latest .zip file and the latest events.out file
if [[ -n "$latest_zip" && -n "$latest_events_out" ]]; then
    find "$EXPS_DIR" -mindepth 1 \( \
        -type f ! -samefile "$latest_zip" ! -samefile "$latest_events_out" \
        -o -type d ! -samefile "$latest_zip" ! -samefile "$latest_events_out" \
    \) -exec rm -rf {} +
else
    echo "No latest .zip or events.out.tfevents.* file found. Nothing to delete."
fi
