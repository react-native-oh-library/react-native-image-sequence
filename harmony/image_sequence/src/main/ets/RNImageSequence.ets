import { Descriptor, ComponentBuilderContext, ViewRawrawProps, Tag } from '@rnoh/react-native-openharmony';
import { RNComponentFactory, RNOHContext, RNViewBase } from '@rnoh/react-native-openharmony';
// import { ImageLoaderTurboModule } from '@rnoh/react-native-openharmony/src/main/ets/RNOHCorePackage/turboModules';
import image from '@ohos.multimedia.image';
import  resourceManager  from '@ohos.resourceManager';
import { BusinessError } from '@ohos.base';

export const IMAGE_SEQUENCE_TYPE: string = "ImageSequenceView"

export interface ImageSequencerawProps extends ViewRawrawProps {
  loop: boolean,
  images: Array<string>,
  startFrameIndex: number,
  framesPerSecond: number,
  downsampleWidth: number,
  downsampleHeight: number
}

// export type ImageSequenceDescriptor = Descriptor<"ImageSequenceView", ImageSequencerawProps>
export type ImageSequenceDescriptor = Descriptor<"ImageSequenceView", ViewRawrawProps, [], ImageSequencerawProps>
export interface ImageData {
  src: string | Resource,
  width: number
}

const context: Context = getContext(this);
const resourceMgr: resourceManager.ResourceManager = context.resourceManager;

@Component
export struct RNImageSequence {
  ctx!: RNOHContext;
  tag: number = 0;
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void;
  @State descriptor: ImageSequenceDescriptor = {} as ImageSequenceDescriptor;
  private unregisterDescriptorChangesListener?: () => void = undefined;
  @State ImageList: (Resource | string | PixelMap)[] = [];
  @State duration: number = 0;
  @State timer: number = 0;
  @State num: number = 0;
  @State isLocalResource: boolean = false;
  @State finishCount: number = 0;
  @State localIndex: number[] = [];

  aboutToAppear() {
    this.descriptor = this.ctx.descriptorRegistry.getDescriptor<ImageSequenceDescriptor>(this.tag);
    this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (newDescriptor) => {
        this.descriptor = (newDescriptor as ImageSequenceDescriptor)
      }
    )

    this.duration = 1000 / this.descriptor.rawProps.framesPerSecond;
    const sourceList = this.descriptor.rawProps.images;
    this.ImageList.length = sourceList.length;

    sourceList.forEach((item, index)=>{
      if (item.startsWith("asset://")) {
        this.getRawFileContent(item.replace("asset://", "assets/"), index)
      } else {
        this.ImageList[index] = this.getSource(item);
        this.finishCount +=1
      }
    })
    if (this.descriptor.rawProps.loop) {
      this.num = 0;
      this.timer = setInterval(()=>{
        this.num++;
        if (this.num > this.ImageList.length) {
          this.num = 0;
        }
      },this.duration)
    } else {
      this.num = 0;
      clearInterval(this.timer);
    }
  }

  getRawFileContent(img:string, index:number) {
    resourceMgr.getRawFileContent(img).then((fileData: Uint8Array) => {
      const buffer = fileData.buffer.slice(0);
      this.imageEdit(buffer, index);
    }).catch((err: BusinessError) => {
      console.error(`getRawFileContent failed: ${err.code}`)
    })
  }

  getSource(source:string) {
    if (source.startsWith("asset://")) {
      return $rawfile(source.replace("asset://", "assets/"))
    }
    if (source.startsWith("file://assets/src/assets/")) {
      return $rawfile(source.replace("file://assets/src/assets/", "assets/"));
    }
    // const filePath = this.ctx.rnInstance.getTurboModule<ImageLoaderTurboModule>("ImageLoader").getCachedImage(source);
    // return filePath ?? source;
    return source;
  }

  calculateInSampleSize(width: number, height: number):number {
    let inSampleSize = 1;
    let reqWidth: number = this.descriptor.rawProps.downsampleWidth;
    let reqHeight: number = this.descriptor.rawProps.downsampleHeight;

    if (height > reqHeight || width > reqWidth) {
      let halfHeight = height / 2;
      let halWidth = width/ 2;
      while ((halfHeight / inSampleSize) >= reqHeight && (halWidth / inSampleSize) >= reqWidth) {
        inSampleSize *= 2;
      }
    }
    return inSampleSize;
  }

  async imageEdit(imageData:ArrayBuffer, index:number) {
    let imageSourceApi:image.ImageSource = image.createImageSource(imageData);
    let pixelMap = await imageSourceApi.createPixelMap();
    const imageInfo = await pixelMap.getImageInfo();
    const width = imageInfo.size.width;
    const height = imageInfo.size.height;
    const sampleSize = this.calculateInSampleSize(width, height);
    const decodeOptions:image.DecodingOptions = {
      desiredSize: {
        width: width / sampleSize,
        height: height / sampleSize
      }
    }

    pixelMap = await imageSourceApi.createPixelMap(decodeOptions);
    this.isLocalResource = true;
    this.ImageList[index] = pixelMap;
    this.finishCount +=1;
    this.localIndex.push(index);
    imageSourceApi.release();
  }
  aboutToDisappear() {
    this.unregisterDescriptorChangesListener?.()
    clearInterval(this.timer);
    if (this.isLocalResource) {
      this.localIndex.forEach(lIndex => {
        const item: PixelMap = this.ImageList[lIndex] as PixelMap;
        item.release();
      })
    }
  }

  build() {
    RNViewBase({ctx: this.ctx, tag: this.tag}) {
      if (this.finishCount === this.ImageList.length) {
        Image(this.ImageList[this.num]).objectFit(ImageFit.Fill).draggable(false).width('100%').height('100%').onComplete(()=>{
          console.log(`加载完成：${new Date().getTime()}`)
        })
      }
    }
  }
}