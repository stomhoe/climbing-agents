#!/usr/bin/env bash
source "venv/bin/activate"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_resume_model>"
    exit 1
fi

RESUME_PATH=$1

EXPERIMENT_NAME="resvis-$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py \
    --viz \
    --n_climbers=5 \
    --n_arenas=2 \
    --random=1.0 \
    --rand_incr=0.01 \
    --rand_cap=1.0 \
    --pvp=0 \
    --infection_ratio=0.0 \
    --round_duration=60 \
    --env_path=godo.x86_64 \
    --experiment_name="$EXPERIMENT_NAME" \
    --timesteps=2_000_000 \
    --save_checkpoint_frequency=100_000 \
    --resume_model_path="$RESUME_PATH"
