#!/usr/bin/env bash
source "venv/bin/activate"

NEW_RUN=false
VIZ=""
# Parse arguments
for arg in "$@"; do
    if [ "$arg" = "n" ]; then
        NEW_RUN=true
    fi
    if [ "$arg" = "v" ]; then
        VIZ="--viz"
    fi
done

set_resume_arg() {
    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
}

if [ "$NEW_RUN" = false ]; then
    set_resume_arg
    RANDOM_ARG="--random=0.5"
    RAND_INCR=""
    RAND_CAP="--rand_cap=0.5"
else
    RESUME_ARG=""
    RANDOM_ARG="--random=0.5"
    RAND_INCR="--rand_incr=0.01"
    RAND_CAP="--rand_cap=0.5"
fi
set_exp_name() {
    echo "$([ "$VIZ" = "--viz" ] && echo "viz-")nocol$(date +'%B%d-%H:%M:%S')"
}


while true; do
    python stable_baselines3_example.py \
        --n_climbers=$([ "$VIZ" = "--viz" ] && echo 10 || echo 40) \
        $RANDOM_ARG \
        $RAND_INCR \
        $RAND_CAP \
        --infection_ratio=0.0 \
        --round_duration=$([ "$VIZ" = "--viz" ] && echo 60 || echo 60) \
        --n_arenas=1 \
        --pvp=-1 \
        $VIZ \
        --n_parallel=$([ "$VIZ" = "--viz" ] && echo 1 || echo 4) \
        --onnx_export_path=$(set_exp_name).onnx \
        $([ "$VIZ" != "--viz" ] && echo "--save_model_path=logs/sb3/$(set_exp_name)_saved.zip") \
        $([ "$VIZ" != "--viz" ] && echo "--save_checkpoint_frequency=200_000") \
        --speedup=$([ "$VIZ" = "--viz" ] && echo 10 || echo 10) \
        --env_path=godo.x86_64 \
        --experiment_name=$(set_exp_name) \
        --timesteps=100_000_000_000 \
        --height_to_win=1300.0 \
        $RESUME_ARG

    set_resume_arg
    
done
