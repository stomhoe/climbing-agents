#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <resume_model_path>"
    exit 1
fi

RESUME_PATH=$1

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="$(date +'%B%d-%H:%M')"

python stable_baselines3_example.py --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name=$EXPERIMENT_NAME --timesteps=400_000 --viz --resume_model_path=$RESUME_PATH
