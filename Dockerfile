FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ── 1. Dependencias base y herramientas de compilación ──────────────────────
RUN apt-get update && apt-get install -y \
    wget gnupg2 git cmake build-essential ninja-build \
    python3 python3-pip python3-venv libmsgpack-dev \
    libnuma-dev gfortran \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Repositorio ROCm 6.3.3 oficial ───────────────────────────────────────
RUN mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
    printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.3.3 jammy main\n' \
    > /etc/apt/sources.list.d/rocm.list && \
    printf 'Package: *\nPin: origin repo.radeon.com\nPin-Priority: 1000\n' \
    > /etc/apt/preferences.d/rocm-pin

RUN apt-get update && apt-get install -y \
    rocm-dev hip-dev rocm-cmake hipblaslt-dev hipblas-dev rocsparse-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Configuración de Entorno ─────────────────────────────────────────────────
ENV PATH=/opt/rocm/bin:/opt/rocm-6.3.3/bin:$PATH
ENV PYTHONPATH=/opt/rocm/lib/python3.10/site-packages:$PYTHONPATH

RUN pip3 install --no-cache-dir joblib msgpack PyYAML

# ── 3. Compilar rocBLAS desde cero (SIN AVX para el Celeron) ────────────────
RUN git clone --depth=1 https://github.com/ROCm/rocBLAS.git -b rocm-6.3.3 && \
    cd rocBLAS && mkdir build && cd build && \
    cmake .. \
        -GNinja \
        -DCMAKE_CXX_COMPILER=amdclang++ \
        -DCMAKE_C_COMPILER=amdclang \
        -DAMDGPU_TARGETS="gfx1010" \
        -DCMAKE_CXX_FLAGS="-march=x86-64 -mno-avx -mno-avx2 -mno-fma -mno-bmi2" \
        -DCMAKE_C_FLAGS="-march=x86-64 -mno-avx -mno-avx2 -mno-fma -mno-bmi2" \
        -DCMAKE_INSTALL_PREFIX=/opt/rocm \
        -DBUILD_CLIENTS_TESTS=OFF \
        -DBUILD_CLIENTS_BENCHMARKS=OFF \
        -DBUILD_CLIENTS_SAMPLES=OFF && \
    ninja install && \
    cd / && rm -rf rocBLAS

# ── 4. Compilar llama-cpp-turboquant ────────────────────────────────────────
WORKDIR /app
RUN git clone https://github.com/TheTom/llama-cpp-turboquant.git . && \
    git checkout feature/turboquant-kv-cache

RUN mkdir build && cd build && \
    HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake .. \
        -GNinja \
        -DCMAKE_CXX_COMPILER=amdclang++ \
        -DCMAKE_C_COMPILER=amdclang \
        -DGGML_HIP=ON \
        -DAMDGPU_TARGETS=gfx1010 \
        -DGPU_TARGETS=gfx1010 \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_NATIVE=OFF \
        -DGGML_AVX=OFF \
        -DGGML_AVX2=OFF \
        -DGGML_FMA=OFF \
        -DGGML_F16C=OFF \
        -DGGML_BMI2=OFF \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF \
        -DCMAKE_PREFIX_PATH="/opt/rocm;/opt/rocm/hip" \
        -DCMAKE_CXX_FLAGS="-march=x86-64 -mno-avx -mno-avx2 -mno-fma -mno-bmi2" \
        -DCMAKE_C_FLAGS="-march=x86-64 -mno-avx -mno-avx2 -mno-fma -mno-bmi2" && \
    ninja -j$(nproc)

# ── 5. Configuración de Runtime ──────────────────────────────────────────────
ENV HSA_OVERRIDE_GFX_VERSION=10.1.0
ENV LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:/opt/rocm-6.3.3/lib:$LD_LIBRARY_PATH

ENTRYPOINT ["/app/build/bin/llama-cli"]
