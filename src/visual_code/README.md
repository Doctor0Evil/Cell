VCVisualLatentTrace — header checks

This folder contains `VCVisualLatentTrace.hpp` and a minimal compile-time check TU:

- `VCVisualLatentTrace_test_compile.cpp` — minimal translation unit that compiles the header and performs a small runtime smoke test.

How to run locally (Windows):

- Use `tools\build_vcvisual_check.ps1` to compile and run the TU. It will try `cl.exe` first, then `g++`.

CI/CMake:

- You may add an optional CMake target to compile `VCVisualLatentTrace_test_compile.cpp` but it is intentionally kept separate from the main game binary.