# Rocm6.3.3-gfx1010-llama.cpp-turboquant
Rocm6.3.3-gfx1010-llama.cpp-turboquant

Ejemplo:

docker run -it --rm \
    --device=/dev/kfd --device=/dev/dri \
    --group-add video --ipc=host --shm-size=12g \
    -p 8080:8080 \
    -v /root/models:/app/models \
    --entrypoint /app/build/bin/llama-server \
    llama-turboquant-celeron:latest \
    -m /app/models/gemma-4-31B-it-Q4_K_M.gguf \
    -ngl 99 \
    -fa on \
    -c 16384 \
    --tensor-split 8,6,6 \
    --cache-type-k turbo3 --cache-type-v turbo3 \
    --host 0.0.0.0 --port 8080

Ejemplo:

docker run -it --rm     --device=/dev/kfd     --device=/dev/dri     --group-add video     --ipc=host     --shm-size=8g     -p 8080:8080     -v /root/models:/app/models     --entrypoint /app/build/bin/llama-server     llama-turboquant-celeron:latest     -m /app/models/Qwen3.5-0.8B-UD-Q8_K_XL.gguf     -ngl 99     --host 0.0.0.0     --port 8080

tmux new-session -d -s gpus 'radeontop -b 03' \;   split-window -h 'radeontop -b 06' \;   split-window -v -t 0 'radeontop -b 09' \;   split-window -v -t 1 'radeontop -b 0a' \;   select-layout tiled \;   attach-session -t gpus
