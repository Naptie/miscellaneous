<script>
  import { goto } from '$app/navigation';
</script>

<div class="hero bg-base-200 min-h-screen">
  <div class="hero-content text-center">
    <div class="max-w-2xl">
      <h1 class="text-5xl font-bold">欢迎使用音频处理实验平台</h1>
      <p class="py-6">
        这是一个用于数字信号处理实验的互动平台。您可以进行听力测试、音频采样分析、滤波器设计、回声处理和均衡器调节等实验。
      </p>
      <div class="flex flex-col gap-4 sm:flex-row sm:justify-center">
        <button class="btn btn-primary btn-lg gap-2" onclick={() => goto('/hearing-test')}>
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
              d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"
            />
          </svg>
          听力测试
        </button>
        <button class="btn btn-secondary btn-lg gap-2" onclick={() => goto('/audio-experiment')}>
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
          音频处理实验
        </button>
      </div>
    </div>
  </div>
</div>
