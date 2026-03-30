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
