#!/usr/bin/env bash
source "venv/bin/activate"

NEW_RUN=false
VIZ=""
COLLISION_ENABLED="--collision_enabled=false"

# Parse arguments
for arg in "$@"; do
    if [ "$arg" = "n" ]; then
        NEW_RUN=true
    fi
    if [ "$arg" = "v" ]; then
        VIZ="--viz"
    fi
    if [ "$arg" = "c" ]; then
        COLLISION_ENABLED="--collision_enabled=true"
    fi
done

if [ "$NEW_RUN" = false ]; then
    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
    RANDOM="--random\\=1"
    RAND_INCR=""
    RAND_CAP=""
else
    RESUME_ARG=""
    RANDOM="--random\\=0"
    RAND_INCR="--rand_incr=0.01"
    RAND_CAP="--rand_cap=1"
fi
EXPERIMENT_NAME="nocol$(date +'%B%d-%H:%M:%S')"

while true; do
    python stable_baselines3_example.py \
        --n_climbers=$([ "$VIZ" = "--viz" ] && echo 10 || echo 70) \
        $RANDOM \
        $RAND_INCR \
        $RAND_CAP \
        --infection_ratio=0.0 \
        --round_duration=300 \
        --n_arenas=1 \
        --pvp=0 \
        $COLLISION_ENABLED \
        $VIZ \
        --n_parallel=$([ "$VIZ" = "--viz" ] && echo 1 || echo 7) \
        --onnx_export_path=model.onnx \
        $([ "$VIZ" != "--viz" ] && echo "--save_checkpoint_frequency=50_000") \
        --speedup=$([ "$VIZ" = "--viz" ] && echo 1 || echo 10) \
        --env_path=godo.x86_64 \
        --experiment_name="$EXPERIMENT_NAME" \
        --timesteps=100_000_000_000 \
        $RESUME_ARG

    RESUME_PATH=$(find "$(pwd)/logs" -name "*.zip" -print0 | xargs -0 ls -lt | head -n 1 | awk '{print $9}')
    RESUME_ARG="--resume_model_path=$RESUME_PATH"
    EXPERIMENT_NAME="nocol$(date +'%B%d-%H:%M:%S')"
done
