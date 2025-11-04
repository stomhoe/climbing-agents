#!/usr/bin/env bash
source "venv/bin/activate"

EXPERIMENT_NAME="editor_$(date +'%B%d-%H:%M:%S')"

python stable_baselines3_example.py  --experiment_name="$EXPERIMENT_NAME" --timesteps=100_000_000_000 --n_climbers=50 --round_duration=60 --speedup=10

