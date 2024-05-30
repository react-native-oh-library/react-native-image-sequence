import { forwardRef, memo } from 'react';
import { View, Image } from 'react-native';
import ImagesequenceView from './src/ImageSequenceNativeComponent'

function ImageSequenceBase({
  images,
  startFrameIndex,
  framesPerSecond,
  loop,
  downsampleHeight,
  downsampleWidth,
  forwardRef,
  ...props
}) {
  let images2 = [];
  images.forEach(item => {
    if (item.uri) {
      images2.push(item.uri);
    } else {
      let resolvedSource = Image.resolveAssetSource(item);
      images2.push(resolvedSource.uri);
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
      />
    </View>
  )
}

const ImageSequenceMemo = memo(ImageSequenceBase)

const ImageSequenceComponent = forwardRef(
  (props, ref) => (
    <ImageSequenceMemo forwardRef={ref} {...props} />
  ),
)
ImageSequenceComponent.displayName = 'ImageSequence';
const ImageSequence = ImageSequenceComponent;
export default ImageSequence;