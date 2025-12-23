<script lang="ts">
  import { untrack } from 'svelte';

  interface Props {
    audioContext: AudioContext | null;
    audioBuffer: AudioBuffer | null;
  }

  let { audioContext, audioBuffer }: Props = $props();

  let echoType = $state<'comb' | 'allpass'>('comb');
  let echoDelay = $state(0.3);
  let echoDecay = $state(0.5);
  let isPlaying = $state<'original' | 'echo' | null>(null);
  let echoBuffer: AudioBuffer | null = $state(null);
  let currentSource: AudioBufferSourceNode | null = null;

  function applyCombFilterEcho() {
    if (!audioBuffer || !audioContext) return;

    const sampleRate = audioBuffer.sampleRate;
    const channels = audioBuffer.numberOfChannels;
    const delayInSamples = Math.floor(echoDelay * sampleRate);
    const length = audioBuffer.length + delayInSamples;

    echoBuffer = audioContext.createBuffer(channels, length, sampleRate);

    for (let channel = 0; channel < channels; channel++) {
      const input = audioBuffer.getChannelData(channel);
      const output = echoBuffer.getChannelData(channel);

      // Comb filter: y(n) = x(n) + a*x(n-R)
      for (let i = 0; i < length; i++) {
        let sample = 0;

        // Original signal
        if (i < input.length) {
          sample += input[i];
        }

        // Delayed signal
        if (i >= delayInSamples) {
          const delayedIndex = i - delayInSamples;
          if (delayedIndex < input.length) {
            sample += echoDecay * input[delayedIndex];
          }
        }

        output[i] = sample;
      }
    }
  }

  function applyAllpassFilterEcho() {
    if (!audioBuffer || !audioContext) return;

    const sampleRate = audioBuffer.sampleRate;
    const channels = audioBuffer.numberOfChannels;
    const delayInSamples = Math.floor(echoDelay * sampleRate);
    const length = audioBuffer.length + delayInSamples * 2;

    echoBuffer = audioContext.createBuffer(channels, length, sampleRate);

    for (let channel = 0; channel < channels; channel++) {
      const input = audioBuffer.getChannelData(channel);
      const output = echoBuffer.getChannelData(channel);

      // All-pass filter: H(z) = (α + z^-R) / (1 + α*z^-R)
      // Time domain: y(n) = α*x(n) + x(n-R) - α*y(n-R)
      const alpha = echoDecay;

      for (let i = 0; i < length; i++) {
        let sample = 0;

        // α*x(n)
        if (i < input.length) {
          sample += alpha * input[i];
        }

        // x(n-R)
        if (i >= delayInSamples && i - delayInSamples < input.length) {
          sample += input[i - delayInSamples];
        }

        // -α*y(n-R)
        if (i >= delayInSamples) {
          sample -= alpha * output[i - delayInSamples];
        }

        output[i] = sample;
      }
    }
  }

  function applyEcho() {
    if (echoType === 'comb') {
      untrack(() => applyCombFilterEcho());
    } else {
      untrack(() => applyAllpassFilterEcho());
    }
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

  function playEcho() {
    if (!echoBuffer || !audioContext) return;
    stopPlayback();

    currentSource = audioContext.createBufferSource();
    currentSource.buffer = echoBuffer;
    currentSource.connect(audioContext.destination);
    currentSource.onended = () => {
      isPlaying = null;
      currentSource = null;
    };
    currentSource.start();
    isPlaying = 'echo';
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
      applyEcho();
    }
  });
</script>

<div class="space-y-6">
  <h2 class="card-title text-2xl">回声效果处理</h2>

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
    <!-- Echo Type Selection -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">回声算法选择</h3>
        <div class="form-control">
          <label class="label cursor-pointer">
            <input
              type="radio"
              name="echo-type"
              class="radio radio-primary"
              value="comb"
              bind:group={echoType}
              onchange={applyEcho}
            />
            <span class="label-text">
              <div class="font-semibold">梳状滤波器 (Comb Filter)</div>
              <div class="text-xs opacity-70">y(n) = x(n) + α·x(n-R)</div>
            </span>
          </label>
        </div>
        <div class="form-control">
          <label class="label cursor-pointer">
            <input
              type="radio"
              name="echo-type"
              class="radio radio-secondary"
              value="allpass"
              bind:group={echoType}
              onchange={applyEcho}
            />
            <span class="label-text">
              <div class="font-semibold">全通滤波器 (All-pass Filter)</div>
              <div class="text-xs opacity-70">H(z) = (α + z⁻ᴿ) / (1 + α·z⁻ᴿ)</div>
            </span>
          </label>
        </div>
      </div>
    </div>

    <!-- Echo Parameters -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">回声参数</h3>

        <div class="form-control">
          <label class="label" for="echo-delay">
            <span class="label-text">延迟时间 (R)</span>
            <span class="label-text-alt">{(echoDelay * 1000).toFixed(0)} ms</span>
          </label>
          <input
            id="echo-delay"
            type="range"
            min="0.05"
            max="1.0"
            step="0.01"
            bind:value={echoDelay}
            oninput={applyEcho}
            class="range range-primary w-full"
          />
        </div>

        <div class="form-control">
          <label class="label" for="echo-decay">
            <span class="label-text">衰减系数 (α)</span>
            <span class="label-text-alt">{echoDecay.toFixed(2)}</span>
          </label>
          <input
            id="echo-decay"
            type="range"
            min="0"
            max="0.99"
            step="0.01"
            bind:value={echoDecay}
            oninput={applyEcho}
            class="range range-secondary w-full"
          />
          <div class="text-xs opacity-70">α 必须小于 1 以保证系统稳定性</div>
        </div>

        {#if echoBuffer}
          <div class="stats stats-vertical lg:stats-horizontal shadow">
            <div class="stat">
              <div class="stat-title">延迟采样点</div>
              <div class="stat-value text-primary text-2xl">
                {Math.floor(echoDelay * (audioBuffer?.sampleRate || 44100))}
              </div>
              <div class="stat-desc">R = {(echoDelay * 1000).toFixed(0)} ms</div>
            </div>
            <div class="stat">
              <div class="stat-title">衰减系数</div>
              <div class="stat-value text-secondary text-2xl">{echoDecay.toFixed(2)}</div>
              <div class="stat-desc">α = {echoDecay.toFixed(3)}</div>
            </div>
            <div class="stat">
              <div class="stat-title">算法类型</div>
              <div class="stat-value text-2xl">
                {echoType === 'comb' ? 'Comb' : 'All-pass'}
              </div>
              <div class="stat-desc">
                {echoType === 'comb' ? '梳状滤波器' : '全通滤波器'}
              </div>
            </div>
          </div>

          <div class="mt-4 flex gap-2">
            <button
              class="btn {isPlaying === 'original' ? 'btn-error' : 'btn-outline'} flex-1"
              onclick={isPlaying === 'original' ? stopPlayback : playOriginal}
            >
              {isPlaying === 'original' ? '⏹ 停止' : '▶ 原始音频'}
            </button>
            <button
              class="btn {isPlaying === 'echo' ? 'btn-error' : 'btn-success'} flex-1"
              onclick={isPlaying === 'echo' ? stopPlayback : playEcho}
            >
              {isPlaying === 'echo' ? '⏹ 停止' : '▶ 回声效果'}
            </button>
          </div>
        {/if}
      </div>
    </div>

    <!-- Algorithm Comparison -->
    <div class="card bg-base-200">
      <div class="card-body">
        <h3 class="card-title">算法对比分析</h3>
        <div class="overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>特性</th>
                <th>梳状滤波器</th>
                <th>全通滤波器</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="font-semibold">数学模型</td>
                <td>y(n) = x(n) + α·x(n-R)</td>
                <td>y(n) = α·x(n) + x(n-R) - α·y(n-R)</td>
              </tr>
              <tr>
                <td class="font-semibold">幅度响应</td>
                <td>存在周期性峰值和谷值</td>
                <td>所有频率幅度一致</td>
              </tr>
              <tr>
                <td class="font-semibold">相位响应</td>
                <td>线性相位</td>
                <td>非线性相位</td>
              </tr>
              <tr>
                <td class="font-semibold">反馈</td>
                <td>无反馈（FIR）</td>
                <td>有反馈（IIR）</td>
              </tr>
              <tr>
                <td class="font-semibold">回声特性</td>
                <td>单次回声，能量逐渐衰减</td>
                <td>多次回声，更自然的混响效果</td>
              </tr>
              <tr>
                <td class="font-semibold">稳定性</td>
                <td>始终稳定</td>
                <td>需要 |α| &lt; 1</td>
              </tr>
              <tr>
                <td class="font-semibold">计算复杂度</td>
                <td>低</td>
                <td>中等</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="prose mt-4 max-w-none">
          <h4>为什么会有区别？</h4>
          <p>
            <strong>梳状滤波器</strong
            >是前馈结构（FIR），只使用输入信号的延迟副本。这产生了单次清晰的回声，但在频域会形成周期性的"梳齿"频率响应，某些频率被增强，某些被削弱。
          </p>
          <p>
            <strong>全通滤波器</strong
            >是反馈结构（IIR），使用了输出信号的反馈。这产生了多次衰减的回声，类似真实环境中的混响。其特点是保持所有频率的幅度不变，只改变相位，因此称为"全通"。
          </p>

          <h4>实际应用建议</h4>
          <ul>
            <li><strong>简单回声</strong>：使用梳状滤波器，效果清晰可控</li>
            <li><strong>混响效果</strong>：使用全通滤波器，声音更自然</li>
            <li><strong>音乐制作</strong>：组合多个全通滤波器实现复杂混响</li>
            <li><strong>语音处理</strong>：梳状滤波器更适合，避免过度混响</li>
          </ul>
        </div>
      </div>
    </div>
  {/if}
</div>
