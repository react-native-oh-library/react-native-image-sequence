package dk.madslee.imageSequence;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.AnimationDrawable;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.Log;
import android.os.AsyncTask;
import android.os.Handler;
import android.util.SparseArray;

import java.io.File;
import java.io.InputStream;
import java.net.URI;
import java.net.URL;
import java.util.ArrayList;
import java.util.concurrent.RejectedExecutionException;
import androidx.appcompat.widget.AppCompatImageView;


public class RCTImageSequenceView extends AppCompatImageView {
    private static final String TAG = RCTImageSequenceView.class.getName();

    private final Handler handler = new Handler();

    private Integer framesPerSecond = 24;
    private Boolean loop = true;
    private Integer downsampleWidth = -1;
    private Integer downsampleHeight = -1;
    private ArrayList<AsyncTask> activeTasks = null;
    private SparseArray<Bitmap> bitmaps = null;
    private RCTResourceDrawableIdHelper resourceDrawableIdHelper;
    private Boolean animate = true;

    public RCTImageSequenceView(Context context) {
        super(context);

        resourceDrawableIdHelper = new RCTResourceDrawableIdHelper();
    }

    private class DownloadImageTask extends AsyncTask<String, Void, Bitmap> {
        private final Integer index;
        private final String uri;
        private final Context context;

        public DownloadImageTask(Integer index, String uri, Context context) {
            this.index = index;
            this.uri = uri;
            this.context = context;
        }

        @Override
        protected Bitmap doInBackground(String... params) {
            try {
                if (this.uri.startsWith("http")) {
                    return this.loadBitmapByExternalURL(this.uri);
                } else if (this.uri.startsWith("file://")) {
                    File file = new File(new URI(this.uri));
                    return BitmapFactory.decodeFile(file.getAbsolutePath());
                }

                return this.loadBitmapByLocalResource(this.uri);
            } catch (Exception e) {

            }
            return null;
        }

        private Bitmap loadBitmapByLocalResource(String uri) {
            Resources res = this.context.getResources();
            int resId = resourceDrawableIdHelper.getResourceDrawableId(this.context, uri);

            if (downsampleWidth <= 0 || downsampleHeight <= 0) {
                // Downsampling is not set so just decode normally
                return BitmapFactory.decodeResource(res, resId);
            }

            // First decode with inJustDecodeBounds=true to check dimensions
            final BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeResource(res, resId, options);

            // Calculate inSampleSize
            options.inSampleSize = RCTImageSequenceView.calculateInSampleSize(options, downsampleWidth, downsampleHeight);

            // Decode bitmap with inSampleSize set
            options.inJustDecodeBounds = false;
            return BitmapFactory.decodeResource(res, resId, options);
        }

        private Bitmap loadBitmapByExternalURL(String uri) {
            Bitmap bitmap = null;
            InputStream in = null;

            try {
                in = new URL(uri).openStream();
                bitmap = BitmapFactory.decodeStream(in);
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
                    if (in != null) {
                        in.close();
                    }
                } catch (Exception e) {
                }
            }

            return bitmap;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            if (!isCancelled() && bitmap != null) {
                onTaskCompleted(this, index, bitmap);
            }
        }
    }

    private void onTaskCompleted(DownloadImageTask downloadImageTask, Integer index, Bitmap bitmap) {
        if (index == 0) {
            // first image should be displayed as soon as possible.
            this.setImageBitmap(bitmap);
        }

        bitmaps.put(index, bitmap);
        activeTasks.remove(downloadImageTask);

        if (activeTasks.isEmpty()) {
            setupAnimationDrawable();
        }
    }

    public static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        // Raw height and width of image
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while ((halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    public void setImages(final ArrayList<String> uris) {
        // Cancel any previously queued Runnables
        handler.removeCallbacksAndMessages(null);

        Drawable drawable = getDrawable();
        if(drawable instanceof AnimationDrawable){
            ((AnimationDrawable)drawable).stop();
        }

        if (isLoading()) {
            // Cancel ongoing tasks (if still loading previous images)
            for (int index = 0; index < activeTasks.size(); index++) {
                activeTasks.get(index).cancel(true);
            }
        }

        activeTasks = null;
        bitmaps = null;

        final Runnable r = new Runnable() {
            public void run() {
                activeTasks = new ArrayList<>(uris.size());
                bitmaps = new SparseArray<>(uris.size());

                for (int index = 0; index < uris.size(); index++) {
                    DownloadImageTask task = new DownloadImageTask(index, uris.get(index), getContext());
                    activeTasks.add(task);

                    try {
                        task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
                    } catch (RejectedExecutionException e){
                        Log.e(TAG, "DownloadImageTask failed" + e.getMessage());
                        break;
                    }
                }
            }
        };

        // Delay for 1ms to make sure that all the props have been set properly before starting processing
        final boolean added = handler.postDelayed(r, 1);
        if (!added) {
            Log.e(TAG, "Failed to place Runnable in to the message queue");
        }
    }

    public void setFramesPerSecond(Integer framesPerSecond) {
        this.framesPerSecond = framesPerSecond;

        // updating frames per second, results in building a new AnimationDrawable (because we cant alter frame duration)
        if (isLoaded()) {
            setupAnimationDrawable();
        }
    }

    public void setLoop(Boolean loop) {
        this.loop = loop;

        // updating looping, results in building a new AnimationDrawable
        if (isLoaded()) {
            setupAnimationDrawable();
        }
    }

    public void setDownsampleWidth(Integer downsampleWidth) {
        this.downsampleWidth = downsampleWidth;
    }

    public void setDownsampleHeight(Integer downsampleHeight) {
        this.downsampleHeight = downsampleHeight;
    }

    public void setAnimate(Boolean animate) {
        Drawable drawable = getDrawable();
        if(drawable instanceof AnimationDrawable){
            AnimationDrawable animationDrawable = (AnimationDrawable)drawable;
            if (animate && !animationDrawable.isRunning()) {
                animationDrawable.start();
            } else if (!animate && animationDrawable.isRunning()) {
                animationDrawable.stop();
                animationDrawable.selectDrawable(0);
            }
        }
        this.animate = animate;
    }

    private boolean isLoaded() {
        return !isLoading() && bitmaps != null && bitmaps.size() > 0;
    }

    private boolean isLoading() {
        return activeTasks != null && !activeTasks.isEmpty();
    }

    private void setupAnimationDrawable() {
        AnimationDrawable animationDrawable = new AnimationDrawable();
        for (int index = 0; index < bitmaps.size(); index++) {
            BitmapDrawable drawable = new BitmapDrawable(this.getResources(), bitmaps.get(index));
            animationDrawable.addFrame(drawable, 1000 / framesPerSecond);
        }

        animationDrawable.setOneShot(!this.loop);

        this.setImageDrawable(animationDrawable);
        if (this.animate) {
            animationDrawable.start();
        }
    }
}
