llama-turboquant-noavx

ROCm + TurboQuant build for older x86-64 CPUs without AVX/AVX2/FMA support.

This image rebuilds both rocBLAS and llama.cpp/TurboQuant with legacy CPU compatibility flags.

Disabled CPU instruction sets
-DGGML_NATIVE=OFF
-DGGML_AVX=OFF
-DGGML_AVX2=OFF
-DGGML_FMA=OFF
-DGGML_F16C=OFF
-DGGML_BMI2=OFF

Additional compiler flags:

-march=x86-64
-mno-avx
-mno-avx2
-mno-fma
-mno-bmi2
Why?

Most modern llama.cpp / ROCm builds fail on older CPUs with errors like:

Illegal instruction

This image is intended for:

Celeron
Core2Quad
Athlon II
Phenom II
older Xeons
older Opterons
other pre-AVX x86-64 CPUs

while still using GPU acceleration through ROCm/HIP.

Includes
ROCm 6.3.3
rocBLAS rebuilt without AVX assumptions
TurboQuant KV cache
Flash Attention
RDNA1 support (gfx1010)
llama-server

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
