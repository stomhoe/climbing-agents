
EXPERIMENT_NAME="vis-$(date +'%B%d-%H:%M')"

source /home/stefan/Documents/robotica/venv/bin/activate
python stable_baselines3_example.py --viz --env_path=/home/stefan/Documents/robotica/godo.x86_64 --experiment_name="$EXPERIMENT_NAME" --timesteps=2_000_000 --save_checkpoint_frequency=100_000 --speedup=1 

