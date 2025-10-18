#!/usr/bin/env bash
source /home/stefan/Documents/robotica/venv/bin/activate

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <resume_model_path>"
    exit 1
fi

RESUME_PATH=$1

python stable_baselines3_example.py --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name=ult --timesteps=100_000_000_000 --save_checkpoint_frequency=200_000 --speedup=10 --n_parallel=10 --save_model_path=nase.zip --resume_model_path="$RESUME_PATH" 




