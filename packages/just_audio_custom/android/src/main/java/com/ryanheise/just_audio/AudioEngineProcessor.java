package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Media3 PCM processor used by the custom just_audio AudioSink.
 *
 * Decoded 16-bit PCM is passed through the TIUS native DSP engine before
 * AudioTrack receives it. This is the actual bridge that makes the native
 * EQ / karaoke / spatial effects audible during normal playback.
 */
public final class AudioEngineProcessor implements AudioProcessor {

    private boolean active = false;
    private boolean inputEnded = false;

    private int channelCount = 0;
    private int sampleRate = 0;

    private ByteBuffer outputBuffer = EMPTY_BUFFER;

    private static final ByteBuffer EMPTY_BUFFER =
            ByteBuffer.allocateDirect(0).order(ByteOrder.nativeOrder());

    @Override
    public AudioFormat configure(AudioFormat inputAudioFormat)
            throws UnhandledAudioFormatException {

        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
            active = false;
            channelCount = 0;
            sampleRate = 0;
            return AudioFormat.NOT_SET;
        }

        channelCount = inputAudioFormat.channelCount;
        sampleRate = inputAudioFormat.sampleRate;

        // NativeAudioEngine.process currently operates on interleaved
        // signed 16-bit PCM. It also supports mono, so any positive
        // channel count is valid.
        active = channelCount > 0 && sampleRate > 0;
        inputEnded = false;

        return inputAudioFormat;
    }

    @Override
    public boolean isActive() {
        return active;
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        final int bytes = inputBuffer.remaining();

        if (bytes <= 0 || !active) {
            return;
        }

        // PCM frames must contain a whole number of samples.
        final int bytesPerFrame = channelCount * 2;
        final int processBytes =
                bytesPerFrame > 0
                        ? bytes - (bytes % bytesPerFrame)
                        : 0;

        if (processBytes <= 0) {
            // Preserve an unusual partial buffer rather than dropping it.
            if (outputBuffer.capacity() < bytes) {
                outputBuffer = ByteBuffer.allocateDirect(bytes)
                        .order(ByteOrder.nativeOrder());
            } else {
                outputBuffer.clear();
            }

            outputBuffer.put(inputBuffer);
            outputBuffer.flip();
            return;
        }

        if (outputBuffer.capacity() < processBytes) {
            outputBuffer = ByteBuffer.allocateDirect(processBytes)
                    .order(ByteOrder.nativeOrder());
        } else {
            outputBuffer.clear();
        }

        /*
         * NativeAudioEngine requires direct buffers because JNI obtains their
         * native addresses. Media3 normally supplies direct PCM buffers, but
         * keep a safe fallback for any non-direct input.
         */
        if (inputBuffer.isDirect()) {
            final int originalLimit = inputBuffer.limit();
            inputBuffer.limit(inputBuffer.position() + processBytes);

            NativeAudioEngine.process(
                    inputBuffer,
                    outputBuffer,
                    processBytes / bytesPerFrame,
                    channelCount,
                    sampleRate
            );

            inputBuffer.limit(originalLimit);
            inputBuffer.position(inputBuffer.position() + processBytes);
        } else {
            final ByteBuffer directInput =
                    ByteBuffer.allocateDirect(processBytes)
                            .order(ByteOrder.nativeOrder());

            final int originalLimit = inputBuffer.limit();
            inputBuffer.limit(inputBuffer.position() + processBytes);
            directInput.put(inputBuffer);
            directInput.flip();
            inputBuffer.limit(originalLimit);

            NativeAudioEngine.process(
                    directInput,
                    outputBuffer,
                    processBytes / bytesPerFrame,
                    channelCount,
                    sampleRate
            );
        }

        outputBuffer.limit(processBytes);
        outputBuffer.position(0);
    }

    @Override
    public ByteBuffer getOutput() {
        final ByteBuffer buffer = outputBuffer;
        outputBuffer = EMPTY_BUFFER;
        return buffer;
    }

    @Override
    public void queueEndOfStream() {
        inputEnded = true;
    }

    @Override
    public boolean isEnded() {
        return inputEnded && !outputBuffer.hasRemaining();
    }

    @Override
    public void flush() {
        outputBuffer = EMPTY_BUFFER;
        inputEnded = false;
    }

    @Override
    public void reset() {
        outputBuffer = EMPTY_BUFFER;
        inputEnded = false;
        active = false;
        channelCount = 0;
        sampleRate = 0;
    }
}
