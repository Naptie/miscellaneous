<script lang="ts">
  import { onDestroy } from 'svelte';

  // Runes状态管理
  let frequency = $state(1000); // 频率 (Hz)
  let volume = $state(50); // 音量 (0-100)
  let isPlaying = $state(false);

  // 音频上下文和振荡器
  let audioContext: AudioContext | null = null;
  let oscillator: OscillatorNode | null = null;
  let gainNode: GainNode | null = null;

  // 频率和音量的显示格式化
  const formatFrequency = $derived(
    frequency >= 1000 ? `${(frequency / 1000).toFixed(1)} kHz` : `${frequency} Hz`
  );

  const formatVolume = $derived(`${volume}%`);

  // 初始化音频上下文
  function initAudioContext() {
    if (!audioContext) {
      audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
  }

  // 开始播放
  function startSound() {
    if (isPlaying) return;

    initAudioContext();
    if (!audioContext) return;

    // 创建振荡器和增益节点
    oscillator = audioContext.createOscillator();
    gainNode = audioContext.createGain();

    // 设置振荡器类型为正弦波
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);

    // 设置音量 (0-1范围)
    gainNode.gain.setValueAtTime(volume / 100, audioContext.currentTime);

    // 连接节点
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    // 启动振荡器
    oscillator.start();
    isPlaying = true;
  }

  // 停止播放
  function stopSound() {
    if (!isPlaying || !oscillator) return;

    oscillator.stop();
    oscillator.disconnect();
    if (gainNode) gainNode.disconnect();

    oscillator = null;
    gainNode = null;
    isPlaying = false;
  }

  // 更新频率
  function updateFrequency() {
    if (isPlaying && oscillator && audioContext) {
      oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
    }
  }

  // 更新音量
  function updateVolume() {
    if (isPlaying && gainNode && audioContext) {
      gainNode.gain.setValueAtTime(volume / 100, audioContext.currentTime);
    }
  }

  // 切换播放状态
  function togglePlay() {
    if (isPlaying) {
      stopSound();
    } else {
      startSound();
    }
  }

  // 组件卸载时清理
  onDestroy(() => {
    stopSound();
    if (audioContext) {
      audioContext.close();
    }
  });
</script>

<div class="card bg-base-100 w-full max-w-2xl shadow-xl">
  <div class="card-body">
    <h2 class="card-title mb-4 justify-center text-2xl">🎵 听力测试信号发生器</h2>

    <!-- 频率控制 -->
    <div class="mb-6 flex w-full flex-row items-center justify-between gap-2">
      <label class="label w-1/12" for="frequency-slider">
        <span class="label-text font-semibold">频率</span>
      </label>
      <input
        id="frequency-slider"
        type="range"
        min="20"
        max="20000"
        bind:value={frequency}
        oninput={updateFrequency}
        class="range range-primary w-3/4"
        step="10"
      />
      <span class="label-text-alt badge badge-primary w-1/6 min-w-28">{formatFrequency}</span>
    </div>

    <!-- 音量控制 -->
    <div class="mb-6 flex w-full flex-row items-center justify-between gap-2">
      <label class="label w-1/12" for="volume-slider">
        <span class="label-text font-semibold">音量</span>
      </label>
      <input
        id="volume-slider"
        type="range"
        min="0"
        max="100"
        bind:value={volume}
        oninput={updateVolume}
        class="range range-secondary w-3/4"
        step="1"
      />
      <span class="label-text-alt badge badge-secondary w-1/6 min-w-28">{formatVolume}</span>
    </div>

    <!-- 当前参数显示 -->
    <div class="stats mb-6 shadow">
      <div class="stat">
        <div class="stat-title">当前频率</div>
        <div class="stat-value text-primary text-2xl">{formatFrequency}</div>
      </div>
      <div class="stat">
        <div class="stat-title">当前音量</div>
        <div class="stat-value text-secondary text-2xl">{formatVolume}</div>
      </div>
    </div>

    <!-- 播放控制按钮 -->
    <div class="card-actions justify-center">
      <button
        onclick={togglePlay}
        class="btn btn-lg {isPlaying ? 'btn-error' : 'btn-success'} min-w-[200px] gap-2"
      >
        {#if isPlaying}
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
          停止播放
        {:else}
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
              d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          开始播放
        {/if}
      </button>
    </div>

    <!-- 警告提示 -->
    <div class="alert alert-warning alert-soft mt-6 shadow-lg">
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
      <div class="text-sm">
        <p class="font-semibold">⚠️ 使用提示</p>
        <p>请从低音量开始测试，逐渐调整到舒适的听觉范围。高频或高音量可能对听力造成损害。</p>
      </div>
    </div>
  </div>
</div>

<style>
  /* 自定义样式增强 */
  .range {
    height: 0.5rem;
  }

  .range::-webkit-slider-thumb {
    height: 1.5rem;
    width: 1.5rem;
  }

  .range::-moz-range-thumb {
    height: 1.5rem;
    width: 1.5rem;
  }
</style>
