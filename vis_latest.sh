#!/usr/bin/env bash
source "venv/bin/activate"

RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
echo "RESUME_PATH: $RESUME_PATH"

EXPERIMENT_NAME="resvis-$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py \
    --viz \
    --n_climbers=3 \
    --collision_enabled=false \
    --round_duration=120 \
    --random=1.0 \
    --rand_incr=0.01 \
    --rand_cap=1. \
    --n_arenas=1 \
    --infection_ratio=0.0 \
    --pvp=0 \
    --env_path=godo.x86_64 \
    --experiment_name="$EXPERIMENT_NAME" \
    --timesteps=2_000_000 \
    --save_checkpoint_frequency=100_000 \
    --resume_model_path="$RESUME_PATH"
