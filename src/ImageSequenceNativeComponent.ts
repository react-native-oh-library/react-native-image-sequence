import type { ViewProps } from 'react-native/Libraries/Components/View/ViewPropTypes';
import { FlexStyle, HostComponent, ShadowStyleIOS, TransformsStyle } from 'react-native';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface ImageStyle extends FlexStyle, TransformsStyle, ShadowStyleIOS {
    backfaceVisibility?: 'visible' | 'hidden';
    borderBottomLeftRadius?: number;
    borderBottomRightRadius?: number;
    backgroundColor?: string;
    borderColor?: string;
    borderWidth?: number;
    borderRadius?: number;
    borderTopLeftRadius?: number;
    borderTopRightRadius?: number;
    overlayColor?: string;
    opacity?: number;
    width?: number;
    height?: number;
}

export interface NativeProps extends ViewProps {
    /** An array of source images. Each element of the array should be the result of a call to require(imagePath). */
    images: any[];
    /** Which index of the images array should the sequence start at. Default: 0 */
    startFrameIndex?: number;
    /** Playback speed of the image sequence. Default: 24 */
    framesPerSecond?: number;
    /** Should the sequence loop. Default: true */
    loop?: boolean;
    /** The width to use for optional downsampling. Both `downsampleWidth` and `downsampleHeight` must be set to a positive number to enable downsampling. Default: -1 */
    downsampleWidth?: number;
    /** The height to use for optional downsampling. Both `downsampleWidth` and `downsampleHeight` must be set to a positive number to enable downsampling. Default: -1 */
    downsampleHeight?: number;
    style?: ImageStyle;
}

export default codegenNativeComponent<NativeProps>(
    'ImageSequenceView',
) as HostComponent<NativeProps>;
