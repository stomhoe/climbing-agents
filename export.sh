#!/usr/bin/env bash
source "venv/bin/activate"



set_resume_arg() {
    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
}


set_exp_name() {
    EXPERIMENT_NAME="$([ "$VIZ" = "--viz" ] && echo "viz-")nocol$(date +'%B%d-%H:%M:%S')"
}

set_exp_name

while true; do
    python stable_baselines3_example.py \
        --n_climbers=1 \
        $RANDOM_ARG \
        $RAND_INCR \
        $RAND_CAP \
        --infection_ratio=0.0 \
        --n_arenas=1 \
        --pvp=0 \
        --n_parallel=1 \
        --onnx_export_path="$(pwd)/model.onnx" \
        --env_path=godo.x86_64 \
        --experiment_name="$EXPERIMENT_NAME" \
        --timesteps=10 \
        $RESUME_ARG

    set_resume_arg
    set_exp_name
done
