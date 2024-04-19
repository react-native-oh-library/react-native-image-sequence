#include "RNOHCorePackage/ComponentBinders/ViewComponentNapiBinder.h"
#include "Props.h"

namespace rnoh {

class ImageSequenceNapiBinder : public ViewComponentNapiBinder {
public:
    napi_value createProps(napi_env env, facebook::react::ShadowView const shadowView) override {
        napi_value napiViewProps = ViewComponentNapiBinder::createProps(env, shadowView);
        if (auto props = std::dynamic_pointer_cast<const facebook::react::ImageSequenceProps>(shadowView.props)) {
            auto images = std::vector<napi_value>();
            auto imageRaw = props->images;
            for (auto imagesItem : imageRaw) {
                auto imagesItemInt = ArkJS(env).createString(imagesItem);
                images.push_back(imagesItemInt);
            }
            auto viewBoxArray = ArkJS(env).createArray(images);
            return ArkJS(env)
                .getObjectBuilder(napiViewProps)
                .addProperty("images", viewBoxArray)
                .addProperty("loop", props->loop)
                .addProperty("startFrameIndex", props->startFrameIndex)
                .addProperty("framesPerSecond", props->framesPerSecond)
                .addProperty("downsampleWidth", props->downsampleWidth)
                .addProperty("downsampleHeight", props->downsampleHeight)
                .build();
        }
        return napiViewProps;
    };
};
} //namespace rnoh