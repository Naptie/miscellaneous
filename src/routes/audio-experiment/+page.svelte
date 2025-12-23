<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import AudioRecorder from './AudioRecorder.svelte';
  import SamplingAnalyzer from './SamplingAnalyzer.svelte';
  import FilterDesigner from './FilterDesigner.svelte';
  import EchoProcessor from './EchoProcessor.svelte';
  import Equalizer from './Equalizer.svelte';
  import SpectrumAnalyzer from './SpectrumAnalyzer.svelte';

  let activeTab = $state<'record' | 'sampling' | 'filter' | 'echo' | 'equalizer'>('record');
  let audioBuffer: AudioBuffer | null = $state(null);
  let audioContext: AudioContext | null = $state(null);

  onMount(() => {
    const AudioContextClass =
      window.AudioContext ||
      (window as typeof window & { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    audioContext = new AudioContextClass();
  });

  onDestroy(() => {
    if (audioContext && audioContext.state !== 'closed') {
      audioContext.close();
    }
  });

  function handleAudioLoaded(buffer: AudioBuffer) {
    audioBuffer = buffer;
  }
</script>

<svelte:head>
  <title>语音及音乐信号的采样、滤波及处理</title>
  <meta name="description" content="设计性实验：语音及音乐信号的采样、滤波及处理" />
</svelte:head>

<div class="bg-base-200 min-h-screen p-4">
  <div class="container mx-auto max-w-7xl">
    <div class="mb-6 text-center">
      <h1 class="text-4xl font-bold">语音及音乐信号的采样、滤波及处理</h1>
      <p class="text-base-content/70 mt-2">设计性实验 - 数字信号处理</p>
    </div>

    <!-- Tab Navigation -->
    <div class="tabs tabs-boxed bg-base-100 mb-6 flex justify-center gap-2 p-2">
      <button
        class="tab tab-lg {activeTab === 'record' ? 'tab-active' : ''}"
        onclick={() => (activeTab = 'record')}
      >
        📼 录音与上传
      </button>
      <button
        class="tab tab-lg {activeTab === 'sampling' ? 'tab-active' : ''}"
        onclick={() => (activeTab = 'sampling')}
      >
        📊 采样分析
      </button>
      <button
        class="tab tab-lg {activeTab === 'filter' ? 'tab-active' : ''}"
        onclick={() => (activeTab = 'filter')}
      >
        🔧 滤波器设计
      </button>
      <button
        class="tab tab-lg {activeTab === 'echo' ? 'tab-active' : ''}"
        onclick={() => (activeTab = 'echo')}
      >
        🎵 回声效果
      </button>
      <button
        class="tab tab-lg {activeTab === 'equalizer' ? 'tab-active' : ''}"
        onclick={() => (activeTab = 'equalizer')}
      >
        🎚️ 均衡器
      </button>
    </div>

    <!-- Content Panels -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        {#if activeTab === 'record'}
          <AudioRecorder {audioContext} onAudioLoaded={handleAudioLoaded} />
        {:else if activeTab === 'sampling'}
          <SamplingAnalyzer {audioContext} {audioBuffer} />
        {:else if activeTab === 'filter'}
          <FilterDesigner {audioContext} {audioBuffer} />
        {:else if activeTab === 'echo'}
          <EchoProcessor {audioContext} {audioBuffer} />
        {:else if activeTab === 'equalizer'}
          <Equalizer {audioContext} {audioBuffer} />
        {/if}
      </div>
    </div>

    <!-- Spectrum Analyzer (Always visible at bottom) -->
    {#if audioBuffer}
      <div class="card bg-base-100 mt-6 shadow-xl">
        <div class="card-body">
          <h3 class="card-title">频谱分析器</h3>
          <SpectrumAnalyzer {audioBuffer} />
        </div>
      </div>
    {/if}

    <!-- Experiment Instructions -->
    <div class="collapse-arrow bg-base-100 collapse mt-6 shadow-xl">
      <input type="checkbox" />
      <div class="collapse-title text-xl font-medium">📖 实验说明</div>
      <div class="collapse-content">
        <div class="prose max-w-none">
          <h3>实验目的</h3>
          <ol>
            <li>理解采样率和量化级数对语音信号的影响</li>
            <li>设计滤波器解决实际问题</li>
            <li>了解回声的产生和梳状滤波器</li>
            <li>混音效果的原理和均衡器的设计</li>
          </ol>

          <h3>实验内容</h3>
          <h4>I. 录音与采样分析</h4>
          <ul>
            <li>录制或上传语音信号及音乐信号</li>
            <li>观察不同采样率及量化级数的听觉效果</li>
            <li>分析音乐信号为何需要更高采样率</li>
            <li>设计滤波器去除50Hz噪声干扰</li>
          </ul>

          <h4>II. 信号处理</h4>
          <ul>
            <li>实现回声效果（梳状滤波器和全通滤波器）</li>
            <li>设计均衡器调整频率响应</li>
            <li>比较不同实现方式的区别</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>
