import { forwardRef, memo } from 'react';
import { View, Image } from 'react-native';
import ImagesequenceView, { NativeProps } from './src/ImageSequenceNativeComponent'

interface ImageProps {
  images: any[],
  startFrameIndex?: number,
  framesPerSecond?: number,
  loop?: boolean,
  downsampleWidth?: number,
  downsampleHeight?: number,
  style?:{
    width?: number,
    height?: number
  }
}

function ImageSequenceBase({
  images,
  startFrameIndex,
  framesPerSecond,
  loop,
  downsampleHeight,
  downsampleWidth,
  forwardRef,
  style,
  ...props
}: ImageProps & { forwardRef: React.Ref<any> }) {
  let images2: any[] = [];
  images.forEach(item => {
    if (item.uri) {
      images2.push(item);
    } else {
      let resolvedSource = Image.resolveAssetSource(item);
      images.push(resolvedSource.uri);
    }
  })
  if (startFrameIndex !== 0) {
    images2 = [...images2.slice(startFrameIndex), ...images2.slice(0, startFrameIndex)];
  }
  return (
    <View ref={forwardRef}>
      <ImagesequenceView
        {...props}
        loop={loop}
        startFrameIndex={startFrameIndex}
        framesPerSecond={framesPerSecond}
        downsampleWidth={downsampleWidth}
        downsampleHeight={downsampleHeight}
        images={images2}
        style={style}
      />
    </View>
  )
}

const ImageSequenceMemo = memo(ImageSequenceBase)

const ImageSequenceComponent: React.ComponentType<NativeProps> = forwardRef(
  (props: NativeProps, ref: React.Ref<any>) => (
    <ImageSequenceMemo forwardRef={ref} {...props} />
  ),
)
ImageSequenceComponent.displayName = 'ImageSequence';
const ImageSequence: React.ComponentType<NativeProps> = ImageSequenceComponent as any;
export default ImageSequence;