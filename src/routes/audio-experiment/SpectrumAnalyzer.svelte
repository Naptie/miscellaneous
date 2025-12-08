<script lang="ts">
  import { onMount } from 'svelte';

  interface Props {
    audioBuffer: AudioBuffer | null;
  }

  let { audioBuffer }: Props = $props();

  let canvasElement: HTMLCanvasElement;
  let fftSize = $state(2048);
  let showPhase = $state(false);

  const fftSizeOptions = [
    { value: 512, label: '512' },
    { value: 1024, label: '1024' },
    { value: 2048, label: '2048' },
    { value: 4096, label: '4096' },
    { value: 8192, label: '8192' }
  ];

  function analyzeSpectrum() {
    if (!audioBuffer || !canvasElement) return;

    const channelData = audioBuffer.getChannelData(0);
    const sampleRate = audioBuffer.sampleRate;
    const canvas = canvasElement;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Take a sample from the middle of the audio
    const startSample = Math.floor((channelData.length - fftSize) / 2);
    const samples = channelData.slice(startSample, startSample + fftSize);

    // Apply Hamming window
    const windowed = new Float32Array(fftSize);
    for (let i = 0; i < fftSize; i++) {
      const windowValue = 0.54 - 0.46 * Math.cos((2 * Math.PI * i) / (fftSize - 1));
      windowed[i] = samples[i] * windowValue;
    }

    // Perform FFT (simplified using browser's built-in)
    const real = new Float32Array(windowed);

    // Simple DFT implementation (note: real FFT would be more efficient)
    const magnitude = new Float32Array(fftSize / 2);
    const phase = new Float32Array(fftSize / 2);

    for (let k = 0; k < fftSize / 2; k++) {
      let realSum = 0;
      let imagSum = 0;

      for (let n = 0; n < fftSize; n++) {
        const angle = (-2 * Math.PI * k * n) / fftSize;
        realSum += real[n] * Math.cos(angle);
        imagSum += real[n] * Math.sin(angle);
      }

      magnitude[k] = Math.sqrt(realSum * realSum + imagSum * imagSum) / fftSize;
      phase[k] = Math.atan2(imagSum, realSum);
    }

    // Draw spectrum
    const width = canvas.width;
    const height = canvas.height;
    const halfHeight = height / 2;

    // Draw grid
    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 10; i++) {
      const y = (height * i) / 10;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    // Draw frequency scale
    ctx.fillStyle = '#888';
    ctx.font = '10px monospace';
    const freqLabels = [100, 500, 1000, 5000, 10000, 20000];
    for (const freq of freqLabels) {
      const binIndex = Math.floor((freq * fftSize) / sampleRate);
      const x = (binIndex / (fftSize / 2)) * width;
      if (x < width) {
        ctx.fillText(freq >= 1000 ? `${freq / 1000}k` : `${freq}`, x - 15, height - 5);
      }
    }

    if (showPhase) {
      // Draw phase response
      ctx.strokeStyle = '#ff6b6b';
      ctx.lineWidth = 2;
      ctx.beginPath();

      for (let i = 0; i < magnitude.length; i++) {
        const x = (i / magnitude.length) * width;
        const y = halfHeight - (phase[i] / Math.PI) * halfHeight * 0.8;

        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();

      // Draw magnitude response
      ctx.strokeStyle = '#4ecdc4';
      ctx.lineWidth = 2;
      ctx.beginPath();

      const maxMag = Math.max(...magnitude);
      for (let i = 0; i < magnitude.length; i++) {
        const x = (i / magnitude.length) * width;
        const normalized = magnitude[i] / (maxMag || 1);
        const dbValue = 20 * Math.log10(normalized + 0.0001);
        const y = height - ((dbValue + 60) / 60) * halfHeight;

        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    } else {
      // Draw magnitude spectrum as bars
      const barWidth = width / (fftSize / 2);
      const maxMag = Math.max(...magnitude);

      for (let i = 0; i < magnitude.length; i++) {
        const x = i * barWidth;
        const normalized = magnitude[i] / (maxMag || 1);
        const dbValue = 20 * Math.log10(normalized + 0.0001);
        const barHeight = ((dbValue + 60) / 60) * height;

        // Color gradient based on frequency
        const hue = (i / magnitude.length) * 280;
        ctx.fillStyle = `hsl(${hue}, 70%, 50%)`;
        ctx.fillRect(x, height - barHeight, barWidth - 1, barHeight);
      }
    }

    // Draw labels
    ctx.fillStyle = '#fff';
    ctx.font = '12px sans-serif';
    ctx.fillText(`FFT Size: ${fftSize}`, 10, 20);
    ctx.fillText(`Freq Resolution: ${(sampleRate / fftSize).toFixed(2)} Hz/bin`, 10, 35);
  }

  onMount(() => {
    if (audioBuffer) {
      analyzeSpectrum();
    }
  });

  $effect(() => {
    if (audioBuffer) {
      analyzeSpectrum();
    }
  });
</script>

<div class="space-y-4">
  <div class="flex flex-wrap items-center justify-between gap-4">
    <div class="form-control">
      <label class="label" for="fft-size">
        <span class="label-text">FFT 大小</span>
      </label>
      <select
        id="fft-size"
        class="select select-bordered select-sm"
        bind:value={fftSize}
        onchange={analyzeSpectrum}
      >
        {#each fftSizeOptions as option (option.value)}
          <option value={option.value}>{option.label}</option>
        {/each}
      </select>
    </div>

    <div class="form-control">
      <label class="label cursor-pointer gap-2">
        <span class="label-text">显示相位</span>
        <input
          type="checkbox"
          class="toggle toggle-primary toggle-sm"
          bind:checked={showPhase}
          onchange={analyzeSpectrum}
        />
      </label>
    </div>

    <button class="btn btn-primary btn-sm" onclick={analyzeSpectrum}>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-4 w-4"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
        />
      </svg>
      刷新分析
    </button>
  </div>

  <div class="bg-base-300 rounded-lg p-2">
    <canvas
      bind:this={canvasElement}
      width="800"
      height="400"
      class="w-full rounded"
      style="image-rendering: pixelated;"
    ></canvas>
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
      <p class="font-semibold">频谱分析说明</p>
      <p>
        使用快速傅里叶变换(FFT)分析音频信号的频率成分。X轴为频率（Hz），Y轴为幅度（dB）。不同颜色代表不同频率范围。
      </p>
    </div>
  </div>

  <div class="stats stats-vertical lg:stats-horizontal shadow">
    <div class="stat">
      <div class="stat-title">FFT大小</div>
      <div class="stat-value text-2xl">{fftSize}</div>
      <div class="stat-desc">采样点数</div>
    </div>
    <div class="stat">
      <div class="stat-title">频率分辨率</div>
      <div class="stat-value text-2xl">
        {audioBuffer ? (audioBuffer.sampleRate / fftSize).toFixed(1) : '0'}
      </div>
      <div class="stat-desc">Hz/bin</div>
    </div>
    <div class="stat">
      <div class="stat-title">频率范围</div>
      <div class="stat-value text-2xl">
        {audioBuffer ? (audioBuffer.sampleRate / 2 / 1000).toFixed(1) : '0'}k
      </div>
      <div class="stat-desc">Hz (Nyquist频率)</div>
    </div>
  </div>
</div>
