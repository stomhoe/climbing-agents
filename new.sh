#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate

# Generate experiment name based on the current date and time
EXPERIMENT_NAME="new_$(date +'%B%d-%H:%M')"
python stable_baselines3_example.py --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name=$EXPERIMENT_NAME --timesteps=200_000_000 --save_checkpoint_frequency=200_000 --speedup=10 --n_parallel=14 
