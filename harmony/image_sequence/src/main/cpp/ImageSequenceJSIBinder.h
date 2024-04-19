#include "RNOHCorePackage/ComponentBinders/ViewComponentJSIBinder.h"

namespace rnoh {

class ImageSequenceJSIBinder : public ViewComponentJSIBinder {
    facebook::jsi::Object createNativeProps(facebook::jsi::Runtime &rt) override {
        auto object = ViewComponentJSIBinder::createNativeProps(rt);
        object.setProperty(rt, "loop", "boolean");
        object.setProperty(rt, "images", "array");
        object.setProperty(rt, "startFrameIndex", "int");
        object.setProperty(rt, "framesPerSecond", "int");
        object.setProperty(rt, "downsampleWidth", "int");
        object.setProperty(rt, "downsampleHeight", "int");
        return object;
    }
};
} // namespace rnoh