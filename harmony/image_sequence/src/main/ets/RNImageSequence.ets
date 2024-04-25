import { Descriptor, ComponentBuilderContext, ViewRawProps, Tag } from '@rnoh/react-native-openharmony';
import { RNComponentFactory, RNOHContext, RNViewBase } from '@rnoh/react-native-openharmony';
// import { ImageLoaderTurboModule } from '@rnoh/react-native-openharmony/src/main/ets/RNOHCorePackage/turboModules';
import image from '@ohos.multimedia.image';
import  resourceManager  from '@ohos.resourceManager';
import { BusinessError } from '@ohos.base';
import { RNC } from '@rnoh/react-native-openharmony/generated/ts'

export const IMAGE_SEQUENCE_TYPE: string = "ImageSequenceView"

export interface ImageSequencerawProps extends ViewRawProps {
  loop: boolean,
  images: Array<string>,
  startFrameIndex: number,
  framesPerSecond: number,
  downsampleWidth: number,
  downsampleHeight: number
}

// export type ImageSequenceDescriptor = Descriptor<"ImageSequenceView", ImageSequencerawProps>
// export type ImageSequenceDescriptor = Descriptor<"ImageSequenceView", ViewRawProps, [], ImageSequencerawProps>
export interface ImageData {
  src: string | Resource,
  width: number
}

const context: Context = getContext(this);
const resourceMgr: resourceManager.ResourceManager = context.resourceManager;

@Component
export struct RNImageSequence {
  public static readonly NAME: string = RNC.ImageSequenceView.NAME;
  ctx!: RNOHContext;
  tag: number = 0;
  @BuilderParam buildCustomComponent: (componentBuilderContext: ComponentBuilderContext) => void;
  // @State descriptor: ImageSequenceDescriptor = {} as ImageSequenceDescriptor;
  // private unregisterDescriptorChangesListener?: () => void = undefined;
  @State descriptorWrapper: RNC.ImageSequenceView.DescriptorWrapper = {} as RNC.ImageSequenceView.DescriptorWrapper;
  @State cleanUpCallbacks: (()=>void)[]=[]
  @State ImageList: (Resource | string | PixelMap)[] = [];
  @State duration: number = 0;
  @State timer: number = 0;
  @State num: number = 0;
  @State isLocalResource: boolean = false;
  @State finishCount: number = 0;
  @State localIndex: number[] = [];

  aboutToAppear() {
    // this.descriptor = this.ctx.descriptorRegistry.getDescriptor<ImageSequenceDescriptor>(this.tag);
    // this.unregisterDescriptorChangesListener = this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
    //   (newDescriptor) => {
    //     this.descriptor = (newDescriptor as ImageSequenceDescriptor)
    //   }
    // )
    this.onDescriptorWrapperChange(this.ctx.descriptorRegistry.findDescriptorWrapperByTag<RNC.ImageSequenceView.DescriptorWrapper>(this.tag)!)
    this.cleanUpCallbacks.push(this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag,
      (descriptor) => {
        this.onDescriptorWrapperChange(new RNC.ImageSequenceView.DescriptorWrapper(descriptor))
      }))

    this.duration = 1000 / this.descriptorWrapper.props.framesPerSecond;
    const sourceList = this.descriptorWrapper.props.images;
    this.ImageList.length = sourceList.length;

    sourceList.forEach((item, index)=>{
      if (item.startsWith("asset://")) {
        this.getRawFileContent(item.replace("asset://", "assets/"), index)
      } else {
        this.ImageList[index] = this.getSource(item);
        this.finishCount +=1
      }
    })
    if (this.descriptorWrapper.props.loop) {
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

  private onDescriptorWrapperChange(descriptorWrapper: RNC.ImageSequenceView.DescriptorWrapper) {
    this.descriptorWrapper = descriptorWrapper
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
    let reqWidth: number = this.descriptorWrapper.props.downsampleWidth;
    let reqHeight: number = this.descriptorWrapper.props.downsampleHeight;

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
    // this.unregisterDescriptorChangesListener?.()
    this.cleanUpCallbacks.forEach(cb => cb())
    clearInterval(this.timer);
    if (this.isLocalResource) {
      this.localIndex.forEach(lIndex => {
        const item: PixelMap = this.ImageList[lIndex] as PixelMap;
        item.release();
      })
    }
    this.ImageList.length = 0;
  }

  build() {
    RNViewBase({ctx: this.ctx, tag: this.tag}) {
      if (this.finishCount === this.ImageList.length) {
        Image(this.ImageList[this.num]).objectFit(ImageFit.Fill).draggable(false).width('100%').height('100%').onComplete(()=>{
          console.log(`加载完成：${new Date().getTime()}`)
        }).key('image_sequence')
      }
    }
  }
}