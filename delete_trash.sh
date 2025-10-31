EXPS_DIR="logs"

find "$EXPS_DIR" -maxdepth 2 -type d \( -name 'editor*' -o -name 'resume_vis*' -o -name 'resvis*' \) -exec rm -rf {} +

find "$EXPS_DIR" -type d -empty -delete
