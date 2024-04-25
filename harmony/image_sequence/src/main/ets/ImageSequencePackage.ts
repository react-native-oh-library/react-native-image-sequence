import { RNPackage } from '@rnoh/react-native-openharmony/ts';
import type {DescriptorWrapperFactoryByDescriptorTypeCtx, DescriptorWrapperFactoryByDescriptorType} from '@rnoh/react-native-openharmony/ts';
import { RNC } from '@rnoh/react-native-openharmony/generated/ts'

export class ImageSequencePackage extends RNPackage {
  createDescriptorWrapperFactoryByDescriptorType(ctx:
          DescriptorWrapperFactoryByDescriptorTypeCtx):
          DescriptorWrapperFactoryByDescriptorType {
    return {
      [RNC.ImageSequenceView.NAME]: (ctx) => new RNC.ImageSequenceView.DescriptorWrapper(ctx.descriptor)
    }
  }
}