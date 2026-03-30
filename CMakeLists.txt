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
