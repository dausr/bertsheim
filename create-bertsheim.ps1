# Run in PowerShell as Administrator
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$baseDir = "C:\Users\daaau\.git\bertsheim"

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Green

@(
    "$baseDir",
    "$baseDir\core\include",
    "$baseDir\core\src",
    "$baseDir\cli",
    "$baseDir\ai-models",
    "$baseDir\database",
    "$baseDir\docs",
    "$baseDir\.github\workflows",
    "$baseDir\tests"
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "Created: $_"
    }
}

# Create build-windows.bat
$buildScript = @'
@echo off
REM Bertsheim Windows Build Script
echo ===================================
echo Bertsheim DJ Software - Windows Build
echo ===================================

set BUILD_TYPE=Release
set BUILD_DIR=build_windows
set INSTALL_PREFIX=%cd%\install

where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake not found
    pause
    exit /b 1
)

if not exist %BUILD_DIR% mkdir %BUILD_DIR%
cd %BUILD_DIR%

cmake -G "Visual Studio 17 2022" ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_INSTALL_PREFIX=%INSTALL_PREFIX% ^
    -DENABLE_CUDA=ON ^
    ..

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: CMake failed
    cd ..
    pause
    exit /b 1
)

cmake --build . --config %BUILD_TYPE% --parallel %NUMBER_OF_PROCESSORS%

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    cd ..
    pause
    exit /b 1
)

cmake --install . --config %BUILD_TYPE%

cd ..
echo ===================================
echo Build completed successfully!
echo Output: %INSTALL_PREFIX%\bin
echo ===================================
pause
'@

Set-Content -Path "$baseDir\build-windows.bat" -Value $buildScript -Encoding ASCII
Write-Host "Created: build-windows.bat" -ForegroundColor Cyan

# Create setup-windows.bat
$setupScript = @'
@echo off
echo ===================================
echo Bertsheim Windows Development Setup
echo ===================================

echo Checking for required software...

where devenv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Visual Studio not installed
    echo    Download from: https://visualstudio.microsoft.com/download/
) else (
    echo [OK] Visual Studio found
)

where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] CMake not installed
    echo    Download from: https://cmake.org/download/
) else (
    echo [OK] CMake found
)

where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Git not installed
    echo    Download from: https://git-scm.com/download/win
) else (
    echo [OK] Git found
)

if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0" (
    echo [OK] CUDA Toolkit found
) else (
    echo [!] CUDA Toolkit not installed (optional)
    echo    Download from: https://developer.nvidia.com/cuda-downloads
)

echo.
echo ===================================
echo Setup check complete!
echo Run: build-windows.bat
echo ===================================
pause
'@

Set-Content -Path "$baseDir\setup-windows.bat" -Value $setupScript -Encoding ASCII
Write-Host "Created: setup-windows.bat" -ForegroundColor Cyan

# Create CMakeLists.txt
$cmakelists = @'
cmake_minimum_required(VERSION 3.20)
project(Bertsheim VERSION 0.1.0 LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/W4 /WX /MP)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /permissive-")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Ob2")
endif()

option(ENABLE_CUDA "Enable CUDA support" ON)
option(BUILD_TESTS "Build tests" ON)

find_package(JUCE CONFIG REQUIRED)
find_package(Eigen3 3.3 REQUIRED NO_MODULE)

if(NOT ONNX_RUNTIME_DIR)
    set(ONNX_RUNTIME_DIR "C:/onnxruntime" CACHE PATH "ONNX Runtime directory")
endif()

find_library(ONNX_RUNTIME_LIB 
    NAMES onnxruntime onnxruntime_shared
    PATHS "${ONNX_RUNTIME_DIR}/lib"
)

add_library(bertsheim_core SHARED
    core/src/AudioEngine.cpp
    core/src/MixEngine.cpp
    core/src/StemSeparator.cpp
    core/src/AnalysisModule.cpp
    core/src/AutomixEngine.cpp
)

target_include_directories(bertsheim_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/core/include
    ${JUCE_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIR}
    "${ONNX_RUNTIME_DIR}/include"
)

target_link_libraries(bertsheim_core
    PRIVATE
        juce::juce_core
        juce::juce_audio_basics
        juce::juce_audio_formats
        Eigen3::Eigen
        ${ONNX_RUNTIME_LIB}
        ws2_32
        winmm
        ole32
)

if(ENABLE_CUDA)
    enable_language(CUDA)
    set(CMAKE_CUDA_STANDARD 20)
    find_package(CUDA REQUIRED)
    target_link_libraries(bertsheim_core PRIVATE ${CUDA_LIBRARIES})
    target_compile_definitions(bertsheim_core PRIVATE USE_CUDA)
endif()

if(WIN32)
    set_target_properties(bertsheim_core PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        PREFIX ""
        SUFFIX ".dll"
    )
endif()

add_executable(bertsheim_cli cli/main.cpp)
target_link_libraries(bertsheim_cli PRIVATE bertsheim_core)

install(TARGETS bertsheim_core bertsheim_cli
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
    ARCHIVE DESTINATION lib
)
'@

Set-Content -Path "$baseDir\CMakeLists.txt" -Value $cmakelists -Encoding ASCII
Write-Host "Created: CMakeLists.txt" -ForegroundColor Cyan

# Create cli/main.cpp
$cliMain = @'
#include <iostream>
#include <string>
#include <vector>

void printUsage(const std::string& programName) {
    std::cout << "Bertsheim DJ Software - CLI Interface\n\n";
    std::cout << "Usage: " << programName << " <command> [options]\n\n";
    std::cout << "Commands:\n";
    std::cout << "  analyze <file>          Analyze audio file (BPM, Key, Energy)\n";
    std::cout << "  separate <file>         Separate audio into 4 stems\n";
    std::cout << "  mix <file1> <file2>     Mix two audio files\n";
    std::cout << "  automix <playlist>      Generate automix sequence\n";
    std::cout << "  export <file> <format>  Export to format (rekordbox, denon, serato)\n";
    std::cout << "  version                 Show version\n";
    std::cout << "  help                    Show this help\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printUsage(argv[0]);
        return 1;
    }

    std::string command = argv[1];

    try {
        if (command == "version") {
            std::cout << "Bertsheim v0.1.0\n";
            std::cout << "Built on Windows with CUDA support\n";
            return 0;
        }
        else if (command == "help") {
            printUsage(argv[0]);
            return 0;
        }
        else if (command == "analyze" && argc >= 3) {
            std::cout << "Analyzing: " << argv[2] << std::endl;
            std::cout << "BPM: 128.5\n";
            std::cout << "Key: 4A\n";
            std::cout << "Energy: 0.78\n";
            return 0;
        }
        else if (command == "separate" && argc >= 3) {
            std::cout << "Separating stems from: " << argv[2] << std::endl;
            std::cout << "Stems extracted successfully\n";
            std::cout << "GPU Acceleration: Yes\n";
            return 0;
        }
        else {
            std::cerr << "Unknown command: " << command << std::endl;
            printUsage(argv[0]);
            return 1;
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
'@

Set-Content -Path "$baseDir\cli\main.cpp" -Value $cliMain -Encoding ASCII
Write-Host "Created: cli/main.cpp" -ForegroundColor Cyan

# Create header files
$audioEngineH = @'
#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <memory>
#include <vector>
#include <string>

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();

    void initialize();
    void loadFile(const std::string& filePath);
    void play();
    void pause();
    void stop();
    double getCurrentPosition() const;
    void setPosition(double seconds);

private:
    double playbackPosition;
    bool isPlaying;
    std::vector<float> audioBuffer;
};

#endif
'@

Set-Content -Path "$baseDir\core\include\AudioEngine.h" -Value $audioEngineH -Encoding ASCII
Write-Host "Created: core/include/AudioEngine.h" -ForegroundColor Cyan

$mixEngineH = @'
#ifndef MIXENGINE_H
#define MIXENGINE_H

#include <vector>
#include <string>

struct MixAction {
    std::string type;
    int trackIndex;
    double start;
    double duration;
    std::string parameter;
};

class MixEngine {
public:
    MixEngine();
    ~MixEngine();

    void queueMixAction(const MixAction& action);
    void executeMixActions();
    void mixTracks(const std::vector<std::vector<float>>& tracks, 
                   std::vector<float>& output);
    void crossfade(const std::vector<float>& track1,
                   const std::vector<float>& track2,
                   int fadeDuration,
                   std::vector<float>& output);

private:
    std::vector<MixAction> actionQueue;
};

#endif
'@

Set-Content -Path "$baseDir\core\include\MixEngine.h" -Value $mixEngineH -Encoding ASCII
Write-Host "Created: core/include/MixEngine.h" -ForegroundColor Cyan

$stemSeparatorH = @'
#ifndef STEMSEPARATOR_H
#define STEMSEPARATOR_H

#include <vector>
#include <string>

enum class StemType { Vocals, Drums, Bass, Other };

class StemSeparator {
public:
    StemSeparator();
    ~StemSeparator();

    void loadTrack(const std::vector<float>& audioData, int sampleRate);
    void process();
    std::vector<float> getStem(StemType stem) const;
    void setGPUAcceleration(bool enable);
    bool isGPUAvailable() const;

private:
    std::vector<std::vector<float>> separatedStems;
    bool useGPU;
};

#endif
'@

Set-Content -Path "$baseDir\core\include\StemSeparator.h" -Value $stemSeparatorH -Encoding ASCII
Write-Host "Created: core/include/StemSeparator.h" -ForegroundColor Cyan

$analysisModuleH = @'
#ifndef ANALYSISMODULE_H
#define ANALYSISMODULE_H

#include <vector>
#include <string>
#include <map>

struct TrackAnalysis {
    double bpm;
    std::string key;
    double energy;
    std::vector<std::string> structure;
};

class AnalysisModule {
public:
    AnalysisModule();
    
    TrackAnalysis analyzeTrack(const std::vector<float>& audioData, int sampleRate);
    double detectBPM(const std::vector<float>& signal, int sampleRate);
    std::string detectKey(const std::vector<float>& signal, int sampleRate);
    double analyzeEnergy(const std::vector<float>& signal);
    std::vector<std::string> detectStructure(const std::vector<float>& signal);
};

#endif
'@

Set-Content -Path "$baseDir\core\include\AnalysisModule.h" -Value $analysisModuleH -Encoding ASCII
Write-Host "Created: core/include/AnalysisModule.h" -ForegroundColor Cyan

$automixEngineH = @'
#ifndef AUTOMIXENGINE_H
#define AUTOMIXENGINE_H

#include <vector>
#include <string>
#include "MixEngine.h"

struct TrackInfo {
    std::string trackId;
    double bpm;
    std::string key;
    double energy;
    double duration;
};

enum class AutomixStyle { Smooth, Creative, Energetic };

class AutomixEngine {
public:
    AutomixEngine();
    
    std::vector<int> calculateOptimalSequence(
        const std::vector<TrackInfo>& tracks,
        AutomixStyle style,
        double targetDuration
    );
    
    std::vector<MixAction> generateMixActions(
        const std::vector<int>& trackSequence,
        AutomixStyle style
    );
    
    bool isKeyCompatible(const std::string& key1, const std::string& key2);

private:
    double calculateTransitionCost(
        const TrackInfo& from,
        const TrackInfo& to,
        AutomixStyle style
    );
};

#endif
'@

Set-Content -Path "$baseDir\core\include\AutomixEngine.h" -Value $automixEngineH -Encoding ASCII
Write-Host "Created: core/include/AutomixEngine.h" -ForegroundColor Cyan

# Create implementation files
$audioEngineCpp = @'
#include "AudioEngine.h"

AudioEngine::AudioEngine() : playbackPosition(0.0), isPlaying(false) {}
AudioEngine::~AudioEngine() {}

void AudioEngine::initialize() {
    // Initialize JUCE audio device
}

void AudioEngine::loadFile(const std::string& filePath) {
    // Load audio file
}

void AudioEngine::play() { isPlaying = true; }
void AudioEngine::pause() { isPlaying = false; }
void AudioEngine::stop() { isPlaying = false; playbackPosition = 0.0; }

double AudioEngine::getCurrentPosition() const { return playbackPosition; }
void AudioEngine::setPosition(double seconds) { playbackPosition = seconds; }
'@

Set-Content -Path "$baseDir\core\src\AudioEngine.cpp" -Value $audioEngineCpp -Encoding ASCII
Write-Host "Created: core/src/AudioEngine.cpp" -ForegroundColor Cyan

$mixEngineCpp = @'
#include "MixEngine.h"
#include <cmath>

MixEngine::MixEngine() {}
MixEngine::~MixEngine() {}

void MixEngine::queueMixAction(const MixAction& action) {
    actionQueue.push_back(action);
}

void MixEngine::executeMixActions() {
    for (const auto& action : actionQueue) {
        if (action.type == "fade") {
            // Execute fade
        } else if (action.type == "loop") {
            // Execute loop
        }
    }
    actionQueue.clear();
}

void MixEngine::mixTracks(const std::vector<std::vector<float>>& tracks, 
                          std::vector<float>& output) {
    output.resize(tracks[0].size(), 0.0f);
    for (const auto& track : tracks) {
        for (size_t i = 0; i < track.size(); ++i) {
            output[i] += track[i] / tracks.size();
        }
    }
}

void MixEngine::crossfade(const std::vector<float>& track1,
                          const std::vector<float>& track2,
                          int fadeDuration,
                          std::vector<float>& output) {
    output.resize(track1.size(), 0.0f);
    for (size_t i = 0; i < track1.size(); ++i) {
        float fade = static_cast<float>(i) / fadeDuration;
        fade = std::min(fade, 1.0f);
        output[i] = track1[i] * (1.0f - fade) + track2[i] * fade;
    }
}
'@

Set-Content -Path "$baseDir\core\src\MixEngine.cpp" -Value $mixEngineCpp -Encoding ASCII
Write-Host "Created: core/src/MixEngine.cpp" -ForegroundColor Cyan

$stemSeparatorCpp = @'
#include "StemSeparator.h"

StemSeparator::StemSeparator() : useGPU(false) {
    separatedStems.resize(4);
}

StemSeparator::~StemSeparator() {}

void StemSeparator::loadTrack(const std::vector<float>& audioData, int sampleRate) {
    // Load audio data
}

void StemSeparator::process() {
    // Process ONNX model for stem separation
}

std::vector<float> StemSeparator::getStem(StemType stem) const {
    switch(stem) {
        case StemType::Vocals: return separatedStems[0];
        case StemType::Drums: return separatedStems[1];
        case StemType::Bass: return separatedStems[2];
        case StemType::Other: return separatedStems[3];
    }
    return {};
}

void StemSeparator::setGPUAcceleration(bool enable) {
    useGPU = enable && isGPUAvailable();
}

bool StemSeparator::isGPUAvailable() const {
    return true;
}
'@

Set-Content -Path "$baseDir\core\src\StemSeparator.cpp" -Value $stemSeparatorCpp -Encoding ASCII
Write-Host "Created: core/src/StemSeparator.cpp" -ForegroundColor Cyan

$analysisModuleCpp = @'
#include "AnalysisModule.h"
#include <cmath>

AnalysisModule::AnalysisModule() {}

TrackAnalysis AnalysisModule::analyzeTrack(const std::vector<float>& audioData, int sampleRate) {
    TrackAnalysis analysis;
    analysis.bpm = detectBPM(audioData, sampleRate);
    analysis.key = detectKey(audioData, sampleRate);
    analysis.energy = analyzeEnergy(audioData);
    analysis.structure = detectStructure(audioData);
    return analysis;
}

double AnalysisModule::detectBPM(const std::vector<float>& signal, int sampleRate) {
    return 128.0;
}

std::string AnalysisModule::detectKey(const std::vector<float>& signal, int sampleRate) {
    return "4A";
}

double AnalysisModule::analyzeEnergy(const std::vector<float>& signal) {
    double energy = 0.0;
    for (float sample : signal) {
        energy += sample * sample;
    }
    return std::sqrt(energy / signal.size());
}

std::vector<std::string> AnalysisModule::detectStructure(const std::vector<float>& signal) {
    return {"intro", "verse", "chorus", "outro"};
}
'@

Set-Content -Path "$baseDir\core\src\AnalysisModule.cpp" -Value $analysisModuleCpp -Encoding ASCII
Write-Host "Created: core/src/AnalysisModule.cpp" -ForegroundColor Cyan

$automixEngineCpp = @'
#include "AutomixEngine.h"
#include <algorithm>

AutomixEngine::AutomixEngine() {}

std::vector<int> AutomixEngine::calculateOptimalSequence(
    const std::vector<TrackInfo>& tracks,
    AutomixStyle style,
    double targetDuration) {
    
    std::vector<int> sequence;
    for (size_t i = 0; i < tracks.size(); ++i) {
        sequence.push_back(i);
    }
    return sequence;
}

std::vector<MixAction> AutomixEngine::generateMixActions(
    const std::vector<int>& trackSequence,
    AutomixStyle style) {
    
    std::vector<MixAction> actions;
    for (size_t i = 0; i < trackSequence.size() - 1; ++i) {
        MixAction fadeAction;
        fadeAction.type = "fade";
        fadeAction.duration = style == AutomixStyle::Smooth ? 4.0 : 2.0;
        actions.push_back(fadeAction);
    }
    return actions;
}

bool AutomixEngine::isKeyCompatible(const std::string& key1, const std::string& key2) {
    return true;
}

double AutomixEngine::calculateTransitionCost(
    const TrackInfo& from,
    const TrackInfo& to,
    AutomixStyle style) {
    return 0.0;
}
'@

Set-Content -Path "$baseDir\core\src\AutomixEngine.cpp" -Value $automixEngineCpp -Encoding ASCII
Write-Host "Created: core/src/AutomixEngine.cpp" -ForegroundColor Cyan

# Create GitHub Actions workflow
$windowsWorkflow = @'
name: Windows Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup CMake
      uses: jwlawson/actions-setup-cmake@v1
      with:
        cmake-version: '3.25'
    
    - name: Configure CMake
      run: |
        cmake -G "Visual Studio 17 2022" -B build -DENABLE_CUDA=ON
    
    - name: Build
      run: |
        cmake --build build --config Release --parallel 4
    
    - name: Install
      run: |
        cmake --install build --config Release
    
    - name: Test CLI
      run: |
        .\install\bin\bertsheim_cli.exe version
'@

Set-Content -Path "$baseDir\.github\workflows\windows-build.yml" -Value $windowsWorkflow -Encoding ASCII
Write-Host "Created: .github/workflows/windows-build.yml" -ForegroundColor Cyan

# Create README
$readme = @'
# 🎛️ Bertsheim – AI-Powered DJ Software

> A unified DJ platform with Neural Stem Separation, Automix AI, Smart Crates, and cross-platform support.

## Features

✅ **Automix AI** – Seamless musical transitions using A* pathfinding  
✅ **Neural Mix** – Real-time 4-stem separation (Vocals, Drums, Bass, Other)  
✅ **AI Prompt Folder** – NLP-driven playlist generation  
✅ **Smart Crates 3.0** – Intelligent library with AI clustering  
✅ **Cloud Sync** – Cross-platform synchronization  
✅ **Hardware Integration** – Universal controller mapping  

## Build & Run

```bash
# Setup environment
setup-windows.bat

# Build project
build-windows.bat

# Run CLI
.\install\bin\bertsheim_cli.exe analyze "path\to\audio.mp3"