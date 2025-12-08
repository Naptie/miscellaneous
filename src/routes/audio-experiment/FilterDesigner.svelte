<script lang="ts">
  interface Props {
    audioContext: AudioContext | null;
    audioBuffer: AudioBuffer | null;
  }

  let { audioContext, audioBuffer }: Props = $props();

  let noiseFrequency = $state(50);
  let noiseAmplitude = $state(0.1);
  let hasNoise = $state(false);
  let filterQ = $state(30);
  let filterType = $state<BiquadFilterType>('notch');
  let isPlaying = $state<'original' | 'noisy' | 'filtered' | null>(null);
  let noisyBuffer: AudioBuffer | null = $state(null);
  let filteredBuffer: AudioBuffer | null = $state(null);
  let currentSource: AudioBufferSourceNode | null = null;

  const filterTypes: { value: BiquadFilterType; label: string; description: string }[] = [
    { value: 'notch', label: '带阻滤波器', description: '去除特定频率' },
    { value: 'lowpass', label: '低通滤波器', description: '保留低频' },
    { value: 'highpass', label: '高通滤波器', description: '保留高频' },
    { value: 'bandpass', label: '带通滤波器', description: '保留特定频段' },
    { value: 'lowshelf', label: '低频架式', description: '增强/衰减低频' },
    { value: 'highshelf', label: '高频架式', description: '增强/衰减高频' },
    { value: 'peaking', label: '峰值滤波器', description: '调整特定频段' }
  ];

  function addNoise() {
    if (!audioBuffer || !audioContext) return;

    const sampleRate = audioBuffer.sampleRate;
    const length = audioBuffer.length;
    const channels = audioBuffer.numberOfChannels;

    noisyBuffer = audioContext.createBuffer(channels, length, sampleRate);

    for (let channel = 0; channel < channels; channel++) {
      const originalData = audioBuffer.getChannelData(channel);
      const noisyData = noisyBuffer.getChannelData(channel);

      for (let i = 0; i < length; i++) {
        const t = i / sampleRate;
        const noise = noiseAmplitude * Math.sin(2 * Math.PI * noiseFrequency * t);
        noisyData[i] = originalData[i] + noise;
      }
    }

    hasNoise = true;
    applyFilter();
  }

  function applyFilter() {
    if (!noisyBuffer || !audioContext) return;

    const offlineContext = new OfflineAudioContext(
      noisyBuffer.numberOfChannels,
      noisyBuffer.length,
      noisyBuffer.sampleRate
    );

    const source = offlineContext.createBufferSource();
    source.buffer = noisyBuffer;

    const filter = offlineContext.createBiquadFilter();
    filter.type = filterType;
    filter.frequency.value = noiseFrequency;
    filter.Q.value = filterQ;

    source.connect(filter);
    filter.connect(offlineContext.destination);
    source.start();

    offlineContext.startRendering().then((renderedBuffer) => {
      filteredBuffer = renderedBuffer;
    });
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

  function playNoisy() {
    if (!noisyBuffer || !audioContext) return;
    stopPlayback();

    currentSource = audioContext.createBufferSource();
    currentSource.buffer = noisyBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'noisy';
  }

  function playFiltered() {
    if (!filteredBuffer || !audioContext) return;
    stopPlayback();

    currentSource = audioContext.createBufferSource();
    currentSource.buffer = filteredBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'filtered';
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
</script>

<div class="space-y-6">
  <h2 class="card-title text-2xl">滤波器设计与噪声去除</h2>

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
    <!-- Noise Addition -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">添加噪声信号</h3>
        <p class="text-base-content/70 text-sm">模拟50Hz工频干扰或其他单频噪声</p>

        <div class="form-control">
          <label class="label" for="noise-frequency">
            <span class="label-text">噪声频率 (Hz)</span>
            <span class="label-text-alt">{noiseFrequency} Hz</span>
          </label>
          <input
            id="noise-frequency"
            type="range"
            min="30"
            max="100"
            step="1"
            bind:value={noiseFrequency}
            class="range range-primary"
          />
          <div class="flex w-full justify-between px-2 text-xs">
            <span>30Hz</span>
            <span>50Hz</span>
            <span>60Hz</span>
            <span>100Hz</span>
          </div>
        </div>

        <div class="form-control">
          <label class="label" for="noise-amplitude">
            <span class="label-text">噪声幅度</span>
            <span class="label-text-alt">{(noiseAmplitude * 100).toFixed(0)}%</span>
          </label>
          <input
            id="noise-amplitude"
            type="range"
            min="0"
            max="0.5"
            step="0.01"
            bind:value={noiseAmplitude}
            class="range range-secondary"
          />
        </div>

        <button class="btn btn-warning gap-2" onclick={addNoise}>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          添加 {noiseFrequency}Hz 噪声
        </button>

        {#if hasNoise}
          <div class="mt-4 flex gap-2">
            <button
              class="btn {isPlaying === 'original' ? 'btn-error' : 'btn-outline'} btn-sm flex-1"
              onclick={isPlaying === 'original' ? stopPlayback : playOriginal}
            >
              {isPlaying === 'original' ? '⏹' : '▶'} 原始音频
            </button>
            <button
              class="btn {isPlaying === 'noisy' ? 'btn-error' : 'btn-warning'} btn-sm flex-1"
              onclick={isPlaying === 'noisy' ? stopPlayback : playNoisy}
            >
              {isPlaying === 'noisy' ? '⏹' : '▶'} 含噪声
            </button>
          </div>
        {/if}
      </div>
    </div>

    <!-- Filter Design -->
    {#if hasNoise}
      <div class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title">滤波器参数</h3>

          <div class="form-control">
            <label class="label" for="filter-type">
              <span class="label-text font-semibold">滤波器类型</span>
            </label>
            <select
              id="filter-type"
              class="select select-bordered"
              bind:value={filterType}
              onchange={applyFilter}
            >
              {#each filterTypes as type (type.value)}
                <option value={type.value}>
                  {type.label} - {type.description}
                </option>
              {/each}
            </select>
          </div>

          <div class="form-control">
            <label class="label" for="filter-q">
              <span class="label-text">品质因数 (Q值)</span>
              <span class="label-text-alt">{filterQ.toFixed(1)}</span>
            </label>
            <input
              id="filter-q"
              type="range"
              min="0.1"
              max="50"
              step="0.1"
              bind:value={filterQ}
              oninput={applyFilter}
              class="range range-accent"
            />
            <div class="text-xs opacity-70">Q值越高，滤波器带宽越窄，选择性越强</div>
          </div>

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
              <p>中心频率: {noiseFrequency} Hz</p>
              <p>带宽: 约 {(noiseFrequency / filterQ).toFixed(2)} Hz</p>
            </div>
          </div>

          {#if filteredBuffer}
            <button
              class="btn {isPlaying === 'filtered' ? 'btn-error' : 'btn-success'} gap-2"
              onclick={isPlaying === 'filtered' ? stopPlayback : playFiltered}
            >
              {isPlaying === 'filtered' ? '⏹ 停止' : '▶ 播放滤波后音频'}
            </button>
          {/if}
        </div>
      </div>

      <!-- Filter Analysis -->
      <div class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title">滤波器分析</h3>
          <div class="prose max-w-none">
            <h4>带阻滤波器（Notch Filter）</h4>
            <p>
              专门用于去除特定频率的干扰信号，如50Hz/60Hz工频噪声。通过设置中心频率和Q值，可以精确控制滤波器的阻带特性。
            </p>

            <h4>设计要点</h4>
            <ul>
              <li><strong>中心频率</strong>：设置为噪声频率（如50Hz）</li>
              <li><strong>Q值</strong>：控制带宽，Q值越高带宽越窄，对信号影响越小</li>
              <li><strong>滤波器阶数</strong>：二阶Biquad滤波器提供-40dB/decade的衰减</li>
            </ul>

            <h4>实际应用</h4>
            <p>
              在录音中，50Hz（中国、欧洲）或60Hz（美国、日本）的工频干扰很常见。使用高Q值的带阻滤波器可以有效去除这种噪声，同时保持音频其他部分的完整性。
            </p>
          </div>
        </div>
      </div>
    {/if}
  {/if}
</div>
