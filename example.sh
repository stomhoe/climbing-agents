#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <environment_name>"
    exit 1
fi

ENV_NAME=$1

gdrl.env_from_hub -r edbeeching/godot_rl_$ENV_NAME

chmod +x examples/godot_rl_$ENV_NAME/bin/${ENV_NAME}.x86_64

python examples/stable_baselines3_example.py --env_path=examples/godot_rl_$ENV_NAME/bin/${ENV_NAME}.x86_64 --experiment_name=Experiment_01 --viz