<script lang="ts">
  interface Props {
    audioContext: AudioContext | null;
    onAudioLoaded: (buffer: AudioBuffer) => void;
  }

  let { audioContext, onAudioLoaded }: Props = $props();

  let isRecording = $state(false);
  let mediaRecorder: MediaRecorder | null = null;
  let audioChunks: Blob[] = [];
  let recordedAudioUrl = $state<string | null>(null);
  let uploadedAudioUrl = $state<string | null>(null);
  let currentAudioBuffer: AudioBuffer | null = $state(null);
  let recordingTime = $state(0);
  let recordingInterval: number | null = null;

  async function startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaRecorder = new MediaRecorder(stream);
      audioChunks = [];
      recordingTime = 0;

      mediaRecorder.ondataavailable = (event) => {
        audioChunks.push(event.data);
      };

      mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
        const url = URL.createObjectURL(audioBlob);
        recordedAudioUrl = url;

        // Convert to AudioBuffer
        const arrayBuffer = await audioBlob.arrayBuffer();
        if (audioContext) {
          const buffer = await audioContext.decodeAudioData(arrayBuffer);
          currentAudioBuffer = buffer;
          onAudioLoaded(buffer);
        }

        // Stop all tracks
        stream.getTracks().forEach((track) => track.stop());
        if (recordingInterval) {
          clearInterval(recordingInterval);
          recordingInterval = null;
        }
      };

      mediaRecorder.start();
      isRecording = true;

      // Update recording time
      recordingInterval = window.setInterval(() => {
        recordingTime += 1;
      }, 1000);
    } catch (error) {
      console.error('Error accessing microphone:', error);
      alert('无法访问麦克风，请检查权限设置');
    }
  }

  function stopRecording() {
    if (mediaRecorder && isRecording) {
      mediaRecorder.stop();
      isRecording = false;
    }
  }

  async function handleFileUpload(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file || !audioContext) return;

    try {
      const arrayBuffer = await file.arrayBuffer();
      const buffer = await audioContext.decodeAudioData(arrayBuffer);
      currentAudioBuffer = buffer;
      uploadedAudioUrl = URL.createObjectURL(file);
      onAudioLoaded(buffer);
    } catch (error) {
      console.error('Error loading audio file:', error);
      alert('无法加载音频文件，请确保文件格式正确');
    }
  }

  function formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
</script>

<div class="space-y-6">
  <h2 class="card-title text-2xl">录音与音频上传</h2>

  <!-- Recording Section -->
  <div class="card bg-base-200">
    <div class="card-body">
      <h3 class="card-title">🎤 录制音频</h3>
      <p class="text-base-content/70 text-sm">使用麦克风录制语音或音乐信号（需要麦克风权限）</p>

      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          {#if !isRecording}
            <button class="btn btn-error gap-2" onclick={startRecording}>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                />
              </svg>
              开始录音
            </button>
          {:else}
            <button class="btn btn-success gap-2" onclick={stopRecording}>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 10h6v4H9z"
                />
              </svg>
              停止录音
            </button>
            <div class="badge badge-error gap-2 p-4">
              <span class="loading loading-dots loading-sm"></span>
              录音中: {formatTime(recordingTime)}
            </div>
          {/if}
        </div>
      </div>

      {#if recordedAudioUrl}
        <div class="mt-4">
          <h4 class="mb-2 font-semibold">录制的音频:</h4>
          <audio controls class="w-full" src={recordedAudioUrl}></audio>
          {#if currentAudioBuffer}
            <div class="mt-2 text-sm">
              <span class="badge badge-outline">
                采样率: {currentAudioBuffer.sampleRate} Hz
              </span>
              <span class="badge badge-outline ml-2">
                时长: {currentAudioBuffer.duration.toFixed(2)} 秒
              </span>
              <span class="badge badge-outline ml-2">
                声道: {currentAudioBuffer.numberOfChannels}
              </span>
            </div>
          {/if}
        </div>
      {/if}
    </div>
  </div>

  <!-- File Upload Section -->
  <div class="card bg-base-200">
    <div class="card-body">
      <h3 class="card-title">📁 上传音频文件</h3>
      <p class="text-base-content/70 text-sm">支持常见音频格式：MP3, WAV, OGG, FLAC 等</p>

      <div class="form-control w-full">
        <input
          type="file"
          accept="audio/*"
          class="file-input file-input-bordered file-input-primary w-full"
          onchange={handleFileUpload}
        />
      </div>

      {#if uploadedAudioUrl}
        <div class="mt-4">
          <h4 class="mb-2 font-semibold">上传的音频:</h4>
          <audio controls class="w-full" src={uploadedAudioUrl}></audio>
          {#if currentAudioBuffer}
            <div class="mt-2 text-sm">
              <span class="badge badge-outline">
                采样率: {currentAudioBuffer.sampleRate} Hz
              </span>
              <span class="badge badge-outline ml-2">
                时长: {currentAudioBuffer.duration.toFixed(2)} 秒
              </span>
              <span class="badge badge-outline ml-2">
                声道: {currentAudioBuffer.numberOfChannels}
              </span>
            </div>
          {/if}
        </div>
      {/if}
    </div>
  </div>

  <!-- Instructions -->
  <div class="alert alert-info">
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      class="h-6 w-6 shrink-0 stroke-current"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      ></path>
    </svg>
    <div class="text-sm">
      <p class="font-semibold">使用提示</p>
      <p>录制或上传音频后，可以在其他标签页中进行采样分析、滤波、回声和均衡器等处理。</p>
    </div>
  </div>
</div>
