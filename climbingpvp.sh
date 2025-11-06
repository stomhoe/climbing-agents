#!/usr/bin/env bash
source "venv/bin/activate"

RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="pvpclimb-reslat$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py \
    --n_climbers=5 \
    --random=1.0 \
    --infection_ratio=0.0 \
    --round_duration=300 \
    --n_arenas=10 \
    --pvp=0 \
    --collision_enabled=false \
    --n_parallel=6 \
    --onnx_export_path=model.onnx \
    --save_checkpoint_frequency=200_000 \
    --speedup=10 \
    --env_path=godo.x86_64 \
    --experiment_name="$EXPERIMENT_NAME" \
    --timesteps=100_000_000_000 \
    --resume_model_path="$RESUME_PATH"                                                                                                                                                                                                                                      