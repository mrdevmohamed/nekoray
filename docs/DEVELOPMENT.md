# Development guide

This repository is being prepared as an independently maintained desktop proxy client for Linux and Windows. The current source tree is still based on the upstream NekoRay/NekoBox code; product naming and visual rebranding are intentionally kept separate from this foundation work.

## Project layout

- `CMakeLists.txt` builds the Qt desktop application (C++17).
- `go/cmd/nekobox_core` builds the sing-box-based core executable.
- `go/grpc_server` contains the gRPC bridge used by the desktop application.
- `libs/` contains dependency acquisition, build and packaging scripts.
- `cmake/` contains platform-specific CMake configuration.
- `test/` contains repository integrity and shell syntax checks.

## Linux: configure and build the Qt application

Install CMake, Ninja, a C++17 compiler and Qt 6 development packages. On Ubuntu 24.04:

```sh
sudo apt-get install cmake ninja-build g++ qt6-base-dev qt6-svg-dev qt6-tools-dev qt6-tools-dev-tools
```

Configure and build the desktop application:

```sh
cmake -S . -B build -G Ninja -DQT_VERSION_MAJOR=6 -DNKR_NO_EXTERNAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
```

`NKR_NO_EXTERNAL=ON` disables optional integrations that are built separately (gRPC/protobuf, yaml-cpp, ZXing and QHotkey). This is useful for a first Qt/C++ smoke build; it is not the full release configuration.

## Windows: configure and build the Qt application

Install Visual Studio 2022 with the Desktop development with C++ workload, CMake and Ninja. Install a matching Qt 6 desktop SDK with the MSVC 2022 64-bit kit and the Qt SVG and Qt Tools modules.

From an x64 Native Tools command prompt:

```sh
cmake -S . -B build -G Ninja -DQT_VERSION_MAJOR=6 -DNKR_NO_EXTERNAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 2
```

The CI workflow performs this Qt 6 smoke build on both Linux and Windows.

## Core source layout and build

The core modules currently use pinned revisions in `libs/get_source_env.sh`. `libs/get_source.sh` checks out those exact revisions into sibling directories next to this repository:

- `../sing-box`
- `../sing-quic`
- `../libneko`

This layout is required by the local `replace` directives in `go/cmd/nekobox_core/go.mod`. Do not move these replacements or update the engine revisions independently. Updating sing-box is a separate migration task because the desktop-to-core gRPC bridge and configuration generation must be checked against the new API.

To build the Linux x86-64 core after acquiring the pinned sources:

```sh
bash libs/get_source.sh
GOOS=linux GOARCH=amd64 bash libs/build_go.sh
```

The build script also supports Windows amd64/arm64 and Linux arm64. Check its target mapping before adding another platform.

## Automated checks

Run the lightweight repository checks locally:

```sh
python3 -m unittest discover -s test -p 'test_*.py' -v
bash test/test-shell-syntax.sh
```

The GitHub Actions workflow runs those checks on Linux and Windows and attempts a Qt 6 C++ smoke build on both platforms.

## Development rules

1. Keep core source revisions pinned to full Git commit IDs.
2. Do not mix a sing-box API migration with build-system cleanup in the same change.
3. Preserve Linux and Windows build coverage for every shared C++ change.
4. Add a regression test when fixing parsing, configuration generation or process management.
5. Keep release packaging separate from CI smoke builds.
6. Do not claim a full release build passed when only the `NKR_NO_EXTERNAL` smoke configuration was tested.
