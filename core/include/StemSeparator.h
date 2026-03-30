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
