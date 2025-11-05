#!/usr/bin/env bash
source "venv/bin/activate"

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="new_$(date +'%B%d-%H:%M')"
python stable_baselines3_example.py \
    --n_parallel=7 \
    --random=0.0 \
    --rand_incr=0.01 \
    --rand_cap=1. \
    --infection_ratio=0.0 \
    --pvp=5 \
    --n_arenas=18 \
    --n_climbers=4 \
    --round_duration=300 \
    --onnx_export_path=model.onnx \
    --save_checkpoint_frequency=200_000d \
    --speedup=10 \
    --env_path=godo.x86_64 \
    --experiment_name=$EXPERIMENT_NAME \
    --timesteps=200_000_000
