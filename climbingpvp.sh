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

if [ "$NEW_RUN" = false ]; then
    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
    RANDOM_ARG="--random=1.7"
    RAND_INCR=""
    RAND_CAP=""
else
    RESUME_ARG=""
    RANDOM_ARG="--random=0"
    RAND_INCR="--rand_incr=0.01"
    RAND_CAP="--rand_cap=1"
fi
EXPERIMENT_NAME="pvp$(date +'%B%d-%H:%M:%S')"

while true; do
    python stable_baselines3_example.py \
        --n_climbers=2 \
        $RANDOM_ARG \
        $RAND_INCR \
        $RAND_CAP \
        --infection_ratio=0.0 \
        --round_duration=600 \
        --n_arenas=$([ "$VIZ" = "--viz" ] && echo 1 || echo 30) \
        --pvp=0 \
        --collision \
        $VIZ \
        --n_parallel=$([ "$VIZ" = "--viz" ] && echo 1 || echo 7) \
        --onnx_export_path=model.onnx \
        $([ "$VIZ" != "--viz" ] && echo "--save_checkpoint_frequency=10_000") \
        --speedup=$([ "$VIZ" = "--viz" ] && echo 1 || echo 10) \
        --env_path=godo.x86_64 \
        --experiment_name="$EXPERIMENT_NAME" \
        --timesteps=100_000_000_000 \
        $RESUME_ARG

    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
    EXPERIMENT_NAME="pvp$(date +'%B%d-%H:%M:%S')"
done
