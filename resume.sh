#!/usr/bin/env bash
source "venv/bin/activate"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <resume_model_path>"
    exit 1
fi

RESUME_PATH=$1

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="$(date +'%B%d-%H:%M')"
python stable_baselines3_example.py \
    --n_climbers=15 \
    --n_parallel=16 \
    --onnx_export_path=model.onnx \
    --save_checkpoint_frequency=200_000 \
    --speedup=10 \
    --timesteps=100_000_000_000 \
    --env_path=godo.x86_64 \
    --experiment_name="$EXPERIMENT_NAME" \
    --resume_model_path="$RESUME_PATH"
