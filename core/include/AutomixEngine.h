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
