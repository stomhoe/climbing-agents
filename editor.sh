#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate


EXPERIMENT_NAME="editor-$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py  --experiment_name="$EXPERIMENT_NAME" --timesteps=100_000_000_000 --save_checkpoint_frequency=200_000 --viz --n_climbers=10
