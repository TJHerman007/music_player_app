package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;

import java.nio.ByteBuffer;

public final class AudioEngineProcessor implements AudioProcessor {

    private boolean active = false;
    private boolean inputEnded = false;

    private ByteBuffer outputBuffer = EMPTY_BUFFER;

    private static final ByteBuffer EMPTY_BUFFER =
            ByteBuffer.allocateDirect(0);

    @Override
    public AudioFormat configure(AudioFormat inputAudioFormat)
            throws UnhandledAudioFormatException {

        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
            active = false;
            return AudioFormat.NOT_SET;
        }

        active = true;
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

        if (bytes <= 0) {
            return;
        }

        if (outputBuffer.capacity() < bytes) {
            outputBuffer = ByteBuffer.allocateDirect(bytes);
        } else {
            outputBuffer.clear();
        }

        outputBuffer.put(inputBuffer);
        outputBuffer.flip();
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
    }
}