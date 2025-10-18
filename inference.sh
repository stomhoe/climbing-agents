#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate
python stable_baselines3_example.py --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name=nase --timesteps=400_000 --speedup=1 --viz --resume_model_path=/home/stefan/Documents/robotica/logs/sb3/experiment1_checkpoints/experiment1_1999200_steps.zip
