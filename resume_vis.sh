#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_resume_model>"
    exit 1
fi

RESUME_MODEL_PATH=$1
source /home/stefan/Documents/robotica/venv/bin/activate

EXPERIMENT_NAME="resvis-$(date +'%B%d-%H:%M')"

source /home/stefan/Documents/robotica/venv/bin/activate
python stable_baselines3_example.py --viz --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name="$EXPERIMENT_NAME" --timesteps=2_000_000 --save_checkpoint_frequency=100_000 --speedup=1 --resume_model_path="$RESUME_MODEL_PATH"

