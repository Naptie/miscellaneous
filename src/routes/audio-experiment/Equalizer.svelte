<script lang="ts">
  interface Props {
    audioContext: AudioContext | null;
    audioBuffer: AudioBuffer | null;
  }

  interface EQBand {
    frequency: number;
    gain: number;
    q: number;
    type: BiquadFilterType;
    enabled: boolean;
  }

  let { audioContext, audioBuffer }: Props = $props();

  let eqBands = $state<EQBand[]>([
    { frequency: 60, gain: 0, q: 1.0, type: 'lowshelf', enabled: true },
    { frequency: 170, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 310, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 600, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 1000, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 3000, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 6000, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 12000, gain: 0, q: 1.0, type: 'peaking', enabled: true },
    { frequency: 14000, gain: 0, q: 1.0, type: 'highshelf', enabled: true }
  ]);

  let isPlaying = $state<'original' | 'equalized' | null>(null);
  let equalizedBuffer: AudioBuffer | null = $state(null);
  let currentSource: AudioBufferSourceNode | null = null;
  let presetName = $state('flat');

  const presets: Record<string, number[]> = {
    flat: [0, 0, 0, 0, 0, 0, 0, 0, 0],
    bass_boost: [6, 4, 2, 0, 0, 0, 0, 0, 0],
    treble_boost: [0, 0, 0, 0, 0, 2, 4, 6, 8],
    vocal: [0, -2, -2, 2, 4, 4, 2, 0, 0],
    classical: [0, 0, 0, 0, 0, 0, -2, -2, 0],
    rock: [4, 2, -1, -2, -1, 1, 3, 4, 4],
    jazz: [2, 2, 0, 1, -1, -1, 0, 1, 2],
    pop: [2, 1, 0, 1, 2, 1, 0, -1, -2],
    electronic: [3, 2, 0, -1, -2, 0, 1, 3, 4]
  };

  function applyEqualizer() {
    if (!audioBuffer || !audioContext) return;

    const offlineContext = new OfflineAudioContext(
      audioBuffer.numberOfChannels,
      audioBuffer.length,
      audioBuffer.sampleRate
    );

    const source = offlineContext.createBufferSource();
    source.buffer = audioBuffer;

    let currentNode: AudioNode = source;

    // Create and connect filter chain
    for (const band of eqBands) {
      if (!band.enabled) continue;

      const filter = offlineContext.createBiquadFilter();
      filter.type = band.type;
      filter.frequency.value = band.frequency;
      filter.Q.value = band.q;
      filter.gain.value = band.gain;

      currentNode.connect(filter);
      currentNode = filter;
    }

    currentNode.connect(offlineContext.destination);
    source.start();

    offlineContext.startRendering().then((renderedBuffer) => {
      equalizedBuffer = renderedBuffer;
    });
  }

  function applyPreset(preset: string) {
    presetName = preset;
    const gains = presets[preset];
    if (gains) {
      eqBands.forEach((band, index) => {
        band.gain = gains[index];
      });
      applyEqualizer();
    }
  }

  function resetEQ() {
    applyPreset('flat');
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

  function playEqualized() {
    if (!equalizedBuffer || !audioContext) return;
    stopPlayback();

    currentSource = audioContext.createBufferSource();
    currentSource.buffer = equalizedBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'equalized';
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

  function getBandColorClass(index: number): string {
    const colors = [
      'bg-primary',
      'bg-secondary',
      'bg-accent',
      'bg-info',
      'bg-success',
      'bg-warning',
      'bg-error',
      'bg-primary',
      'bg-secondary'
    ];
    return colors[index % colors.length];
  }

  function getBandToggleClass(index: number): string {
    const colors = [
      'toggle-primary',
      'toggle-secondary',
      'toggle-accent',
      'toggle-info',
      'toggle-success',
      'toggle-warning',
      'toggle-error',
      'toggle-primary',
      'toggle-secondary'
    ];
    return colors[index % colors.length];
  }

  function getBandRangeClass(index: number): string {
    const colors = [
      'range-primary',
      'range-secondary',
      'range-accent',
      'range-info',
      'range-success',
      'range-warning',
      'range-error',
      'range-primary',
      'range-secondary'
    ];
    return colors[index % colors.length];
  }

  $effect(() => {
    if (audioBuffer) {
      applyEqualizer();
    }
  });
</script>

<div class="space-y-6">
  <h2 class="card-title text-2xl">参数均衡器</h2>

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
    <!-- Presets -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">预设效果</h3>
        <div class="flex flex-wrap gap-2">
          {#each Object.keys(presets) as preset (preset)}
            <button
              class="btn btn-sm {presetName === preset ? 'btn-primary' : 'btn-outline'}"
              onclick={() => applyPreset(preset)}
            >
              {preset.toUpperCase()}
            </button>
          {/each}
          <button class="btn btn-error btn-sm" onclick={resetEQ}>重置</button>
        </div>
      </div>
    </div>

    <!-- EQ Bands -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">频段调节</h3>

        <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
          {#each eqBands as band, index (band.frequency)}
            <div class="card bg-base-100 shadow-md">
              <div class="card-body p-4">
                <div class="flex items-center justify-between">
                  <h4 class="font-bold">
                    {band.frequency >= 1000
                      ? `${(band.frequency / 1000).toFixed(1)}k Hz`
                      : `${band.frequency} Hz`}
                  </h4>
                  <input
                    type="checkbox"
                    class="toggle {getBandToggleClass(index)} toggle-sm"
                    bind:checked={band.enabled}
                    onchange={applyEqualizer}
                  />
                </div>

                <div class="form-control">
                  <label class="label py-1" for="gain-{index}">
                    <span class="label-text text-xs">增益</span>
                    <span class="label-text-alt text-xs">{band.gain.toFixed(1)} dB</span>
                  </label>
                  <input
                    id="gain-{index}"
                    type="range"
                    min="-12"
                    max="12"
                    step="0.5"
                    bind:value={band.gain}
                    oninput={applyEqualizer}
                    class="range {getBandRangeClass(index)} range-xs"
                    disabled={!band.enabled}
                  />
                </div>

                <div class="form-control">
                  <label class="label py-1" for="q-{index}">
                    <span class="label-text text-xs">Q值</span>
                    <span class="label-text-alt text-xs">{band.q.toFixed(1)}</span>
                  </label>
                  <input
                    id="q-{index}"
                    type="range"
                    min="0.1"
                    max="10"
                    step="0.1"
                    bind:value={band.q}
                    oninput={applyEqualizer}
                    class="range {getBandRangeClass(index)} range-xs"
                    disabled={!band.enabled}
                  />
                </div>

                <div class="badge badge-outline badge-xs mt-1">
                  {band.type === 'lowshelf'
                    ? '低频架式'
                    : band.type === 'highshelf'
                      ? '高频架式'
                      : '峰值滤波'}
                </div>
              </div>
            </div>
          {/each}
        </div>
      </div>
    </div>

    <!-- Visualization -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">频率响应曲线</h3>
        <div class="bg-base-300 flex h-64 items-end justify-around gap-1 p-4">
          {#each eqBands as band, index (band.frequency)}
            <div class="flex h-full flex-col items-center justify-end gap-1">
              <div
                class="{getBandColorClass(index)} w-8 transition-all duration-100"
                style="height: {((band.gain + 12) / 24) * 100}%"
              ></div>
              <div class="text-xs">
                {band.frequency >= 1000 ? `${(band.frequency / 1000).toFixed(1)}k` : band.frequency}
              </div>
            </div>
          {/each}
        </div>
        <div class="text-center text-sm opacity-70">
          <p>0 dB 基准线位于中间，向上增益，向下衰减</p>
        </div>
      </div>
    </div>

    <!-- Playback Controls -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">播放对比</h3>
        <div class="flex gap-2">
          <button
            class="btn {isPlaying === 'original' ? 'btn-error' : 'btn-outline'} flex-1"
            onclick={isPlaying === 'original' ? stopPlayback : playOriginal}
          >
            {isPlaying === 'original' ? '⏹ 停止' : '▶ 原始音频'}
          </button>
          <button
            class="btn {isPlaying === 'equalized' ? 'btn-error' : 'btn-success'} flex-1"
            onclick={isPlaying === 'equalized' ? stopPlayback : playEqualized}
            disabled={!equalizedBuffer}
          >
            {isPlaying === 'equalized' ? '⏹ 停止' : '▶ 均衡后音频'}
          </button>
        </div>
      </div>
    </div>

    <!-- Technical Info -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">均衡器设计说明</h3>
        <div class="prose max-w-none">
          <h4>滤波器结构</h4>
          <p>
            本均衡器采用级联的二阶Biquad滤波器实现，每个频段使用一个独立的滤波器。低频和高频使用架式滤波器（shelf），中频使用峰值滤波器（peaking）。
          </p>

          <h4>参数说明</h4>
          <ul>
            <li><strong>增益（Gain）</strong>：±12dB范围，正值增强，负值衰减</li>
            <li><strong>Q值（Quality Factor）</strong>：控制带宽，Q值越高影响范围越窄</li>
            <li><strong>频率（Frequency）</strong>：滤波器中心频率</li>
          </ul>

          <h4>设计优势</h4>
          <ul>
            <li>每个频段独立可调，互相影响小</li>
            <li>使用标准二阶滤波器，计算效率高</li>
            <li>可独立启用/禁用每个频段</li>
            <li>覆盖完整的音频频谱范围（60Hz - 14kHz）</li>
          </ul>

          <h4>应用场景</h4>
          <ul>
            <li><strong>语音增强</strong>：提升300-3000Hz频段清晰度</li>
            <li><strong>低音增强</strong>：提升60-170Hz频段</li>
            <li><strong>高音增强</strong>：提升6k-14kHz频段</li>
            <li><strong>去除共振</strong>：衰减特定频率的共振峰</li>
          </ul>
        </div>
      </div>
    </div>
  {/if}
</div>
