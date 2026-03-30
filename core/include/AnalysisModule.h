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
