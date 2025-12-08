<script lang="ts">
  interface Props {
    audioContext: AudioContext | null;
    audioBuffer: AudioBuffer | null;
  }

  let { audioContext, audioBuffer }: Props = $props();

  let targetSampleRate = $state(8000);
  let bitDepth = $state(16);
  let isPlaying = $state<'original' | 'resampled' | null>(null);
  let resampledBuffer: AudioBuffer | null = $state(null);
  let currentSource: AudioBufferSourceNode | null = null;

  const sampleRatePresets = [
    { value: 8000, label: '8 kHz (电话质量)', description: '适用于语音' },
    { value: 11025, label: '11.025 kHz', description: '低质量音频' },
    { value: 16000, label: '16 kHz', description: '宽带语音' },
    { value: 22050, label: '22.05 kHz', description: '中等质量' },
    { value: 44100, label: '44.1 kHz (CD质量)', description: '标准音乐质量' },
    { value: 48000, label: '48 kHz', description: '专业音频' }
  ];

  const bitDepthOptions = [
    { value: 4, label: '4-bit', description: '极低质量' },
    { value: 8, label: '8-bit', description: '低质量' },
    { value: 12, label: '12-bit', description: '中等质量' },
    { value: 16, label: '16-bit (CD)', description: '标准质量' },
    { value: 24, label: '24-bit', description: '高质量' }
  ];

  function resampleAudio() {
    if (!audioBuffer || !audioContext) return;

    const channels = audioBuffer.numberOfChannels;
    const duration = audioBuffer.duration;
    const newLength = Math.ceil(duration * targetSampleRate);

    // Create new buffer
    const newBuffer = audioContext.createBuffer(channels, newLength, targetSampleRate);

    // Resample each channel
    for (let channel = 0; channel < channels; channel++) {
      const originalData = audioBuffer.getChannelData(channel);
      const newData = newBuffer.getChannelData(channel);

      for (let i = 0; i < newLength; i++) {
        const originalIndex = (i / newLength) * originalData.length;
        const index0 = Math.floor(originalIndex);
        const index1 = Math.min(index0 + 1, originalData.length - 1);
        const fraction = originalIndex - index0;

        // Linear interpolation
        let sample = originalData[index0] * (1 - fraction) + originalData[index1] * fraction;

        // Apply bit depth quantization
        const levels = Math.pow(2, bitDepth) - 1;
        sample = Math.round(sample * levels) / levels;

        newData[i] = sample;
      }
    }

    resampledBuffer = newBuffer;
  }

  function playOriginal() {
    if (!audioBuffer || !audioContext) return;

    stopPlayback();
    currentSource = audioContext.createBufferSource();
    currentSource.buffer = audioBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'original';
  }

  function playResampled() {
    if (!resampledBuffer || !audioContext) return;

    stopPlayback();
    currentSource = audioContext.createBufferSource();
    currentSource.buffer = resampledBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'resampled';
  }

  function stopPlayback() {
    if (currentSource) {
      try {
        currentSource.stop();
        currentSource.disconnect();
      } catch {
        // Already stopped
      }
      currentSource = null;
    }
    isPlaying = null;
  }

  $effect(() => {
    if (audioBuffer) {
      resampleAudio();
    }
  });
</script>

<div class="space-y-6">
  <h2 class="card-title text-2xl">采样率与量化分析</h2>

  {#if !audioBuffer}
    <div class="alert alert-warning">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-6 w-6 shrink-0 stroke-current"
        fill="none"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
        />
      </svg>
      <span>请先在"录音与上传"标签页中录制或上传音频</span>
    </div>
  {:else}
    <!-- Original Audio Info -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">原始音频信息</h3>
        <div class="stats stats-vertical lg:stats-horizontal shadow">
          <div class="stat">
            <div class="stat-title">采样率</div>
            <div class="stat-value text-primary text-2xl">{audioBuffer.sampleRate} Hz</div>
            <div class="stat-desc">原始采样频率</div>
          </div>
          <div class="stat">
            <div class="stat-title">时长</div>
            <div class="stat-value text-secondary text-2xl">
              {audioBuffer.duration.toFixed(2)} s
            </div>
            <div class="stat-desc">{audioBuffer.length} 采样点</div>
          </div>
          <div class="stat">
            <div class="stat-title">声道数</div>
            <div class="stat-value text-2xl">{audioBuffer.numberOfChannels}</div>
            <div class="stat-desc">音频通道</div>
          </div>
        </div>
        <button
          class="btn {isPlaying === 'original' ? 'btn-error' : 'btn-primary'} btn-wide mt-4"
          onclick={isPlaying === 'original' ? stopPlayback : playOriginal}
        >
          {isPlaying === 'original' ? '⏹ 停止' : '▶ 播放原始音频'}
        </button>
      </div>
    </div>

    <!-- Sampling Controls -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">重采样参数</h3>

        <!-- Sample Rate Selection -->
        <div class="form-control">
          <label class="label" for="sample-rate">
            <span class="label-text font-semibold">目标采样率</span>
          </label>
          <select
            id="sample-rate"
            class="select select-bordered"
            bind:value={targetSampleRate}
            onchange={resampleAudio}
          >
            {#each sampleRatePresets as preset (preset.value)}
              <option value={preset.value}>
                {preset.label} - {preset.description}
              </option>
            {/each}
          </select>
        </div>

        <!-- Bit Depth Selection -->
        <div class="form-control mt-4">
          <label class="label" for="bit-depth">
            <span class="label-text font-semibold">量化位数（比特深度）</span>
          </label>
          <select
            id="bit-depth"
            class="select select-bordered"
            bind:value={bitDepth}
            onchange={resampleAudio}
          >
            {#each bitDepthOptions as option (option.value)}
              <option value={option.value}>
                {option.label} - {option.description}
              </option>
            {/each}
          </select>
        </div>

        <div class="divider"></div>

        {#if resampledBuffer}
          <div class="stats stats-vertical lg:stats-horizontal shadow">
            <div class="stat">
              <div class="stat-title">重采样率</div>
              <div class="stat-value text-primary text-2xl">{targetSampleRate} Hz</div>
              <div class="stat-desc">
                比原始低 {((1 - targetSampleRate / audioBuffer.sampleRate) * 100).toFixed(1)}%
              </div>
            </div>
            <div class="stat">
              <div class="stat-title">量化位数</div>
              <div class="stat-value text-secondary text-2xl">{bitDepth} bit</div>
              <div class="stat-desc">{Math.pow(2, bitDepth)} 量化级别</div>
            </div>
            <div class="stat">
              <div class="stat-title">数据压缩</div>
              <div class="stat-value text-2xl">
                {((targetSampleRate / audioBuffer.sampleRate) * (bitDepth / 16) * 100).toFixed(1)}%
              </div>
              <div class="stat-desc">相对于原始数据</div>
            </div>
          </div>

          <button
            class="btn {isPlaying === 'resampled' ? 'btn-error' : 'btn-success'} btn-wide mt-4"
            onclick={isPlaying === 'resampled' ? stopPlayback : playResampled}
          >
            {isPlaying === 'resampled' ? '⏹ 停止' : '▶ 播放重采样音频'}
          </button>
        {/if}
      </div>
    </div>

    <!-- Analysis and Explanation -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">实验分析</h3>
        <div class="prose max-w-none">
          <h4>采样定理（Nyquist-Shannon）</h4>
          <p>
            采样频率必须至少是信号最高频率的两倍，才能完整重建原始信号。对于人耳可听范围（20Hz-20kHz），标准CD采样率为44.1kHz。
          </p>

          <h4>语音 vs 音乐的采样率要求</h4>
          <ul>
            <li>
              <strong>语音信号</strong
              >：主要频率集中在300Hz-3.4kHz，因此8kHz采样率即可满足电话质量要求
            </li>
            <li>
              <strong>音乐信号</strong
              >：包含更丰富的高频成分和谐波，需要44.1kHz或更高采样率以保持音质
            </li>
          </ul>

          <h4>量化效果</h4>
          <ul>
            <li><strong>16-bit</strong>：CD质量，96dB动态范围</li>
            <li><strong>8-bit</strong>：明显噪声，48dB动态范围</li>
            <li><strong>4-bit</strong>：严重失真，仅24dB动态范围</li>
          </ul>

          <h4>实验建议</h4>
          <p>
            尝试不同的采样率和位深度组合，聆听音质变化。对于语音信号，8kHz/16-bit通常足够；对于音乐，建议至少22.05kHz/16-bit以上。
          </p>
        </div>
      </div>
    </div>
  {/if}
</div>
