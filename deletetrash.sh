EXPS_DIR="logs"

# Delete directories matching patterns
find "$EXPS_DIR" -maxdepth 2 -type d \( -name 'editor*' \) -exec rm -rf {} +

# Find the most recently created events.out.tfevents.* file in the logs directory
latest_file=$(find "$EXPS_DIR" -type f -name 'events.out.tfevents.*' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

# Find all events.out.tfevents.* files
find "$EXPS_DIR" -type f -name 'events.out.tfevents.*' | while read -r event_file; do
    if [[ "$event_file" != "$latest_file" ]]; then
        dir_to_delete=$(dirname "$event_file")
        rm -rf "$dir_to_delete"
    fi
done

# Delete empty directories
find "$EXPS_DIR" -type d -empty -delete
