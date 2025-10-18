#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate
python stable_baselines3_example.py --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name=nase --timesteps=2_000_000 --save_checkpoint_frequency=200_000 --speedup=10 --viz 
