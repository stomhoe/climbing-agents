#!/usr/bin/env bash
source "venv/bin/activate"

RESUME_PATH=$(find logs -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py --n_climbers=15 --onnx_export_path=model.onnx --env_path=godo.x86_64 --experiment_name="$EXPERIMENT_NAME" --timesteps=100_000_000_000 --save_checkpoint_frequency=200_000 --speedup=10 --n_parallel=20 --resume_model_path="$RESUME_PATH"
