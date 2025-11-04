#!/usr/bin/env bash
source "venv/bin/activate"

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="new_$(date +'%B%d-%H:%M')"
python stable_baselines3_example.py \
    --n_parallel=14 \
    --random=0.3 \
    --n_climbers=15 \
    --round_duration=300 \
    --onnx_export_path=model.onnx \
    --save_checkpoint_frequency=200_000 \
    --speedup=30 \
    --env_path=godo.x86_64 \
    --experiment_name=$EXPERIMENT_NAME \
    --timesteps=200_000_000
