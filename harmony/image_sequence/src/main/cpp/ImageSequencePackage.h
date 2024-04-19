#include "RNOH/Package.h"
#include "ComponentDescriptors.h"
#include "ImageSequenceJSIBinder.h"
#include "ImageSequenceNapiBinder.h"

namespace rnoh {

class ImageSequencePackage : public Package {
public:
    ImageSequencePackage(Package::Context ctx) : Package(ctx) {}

    std::vector<facebook::react::ComponentDescriptorProvider> createComponentDescriptorProviders() override {
        return {facebook::react::concreteComponentDescriptorProvider<facebook::react::ImageSequenceComponentDescriptor>()};
    }

    ComponentNapiBinderByString createComponentNapiBinderByName() override {
        return {{"ImageSequenceView", std::make_shared<ImageSequenceNapiBinder>()}};
    }

    ComponentJSIBinderByString createComponentJSIBinderByName() override {
        return {{"ImageSequenceView", std::make_shared<ImageSequenceJSIBinder>()}};
    }
};
} // namespace rnoh