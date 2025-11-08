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
    RANDOM_ARG="--random=1.0"
    RAND_INCR=""
    RAND_CAP=""
else
    RESUME_ARG=""
    RANDOM_ARG="--random=1.0"
    RAND_INCR="--rand_incr=0.01"
    RAND_CAP="--rand_cap=1"
fi
set_exp_name() {
    EXPERIMENT_NAME="$([ "$VIZ" = "--viz" ] && echo "viz-")nocol$(date +'%B%d-%H:%M:%S')"
}

set_exp_name

while true; do
    python stable_baselines3_example.py \
        --n_climbers=$([ "$VIZ" = "--viz" ] && echo 5 || echo 60) \
        $RANDOM_ARG \
        $RAND_INCR \
        $RAND_CAP \
        --infection_ratio=0.0 \
        --round_duration=$([ "$VIZ" = "--viz" ] && echo 30 || echo 60) \
        --n_arenas=1 \
        --pvp=-1 \
        $VIZ \
        --n_parallel=$([ "$VIZ" = "--viz" ] && echo 1 || echo 5) \
        --onnx_export_path=model.onnx \
        $([ "$VIZ" != "--viz" ] && echo "--save_checkpoint_frequency=100_000") \
        --speedup=$([ "$VIZ" = "--viz" ] && echo 1 || echo 10) \
        --env_path=godo.x86_64 \
        --experiment_name="$EXPERIMENT_NAME" \
        --timesteps=100_000_000_000 \
        $RESUME_ARG

    set_resume_arg
    set_exp_name
done
