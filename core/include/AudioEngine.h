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
