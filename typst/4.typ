#import "../sjfh-typst/labreport.typ": *
#import "@preview/physica:0.9.2": *
#import "@preview/cetz:0.2.1": *
#import "@preview/zebraw:0.6.0": *

#show: zebraw

#show table: it => block(width: 100%)[
  #set align(center)
  #it
]

#set table(
  stroke: 0.5pt + black,
  inset: 6pt,
)

#show figure: it => block(width: 100%)[
  #set align(center)
  #it
]

#show raw: set text(font: ("CaskaydiaCove NF", "Microsoft YaHei"))

#let r(x, precision) = {
  if x == none {
    return $ dash $
  }
  assert(precision >= 0)
  calc.round(x * calc.pow(10, precision)) / calc.pow(10, precision)
}

#let f(x, precision) = {
  assert(precision >= 0)
  let s = str(calc.round(x, digits: precision))
  let after_dot = s.find(regex("\..*"))
  if after_dot == none {
    s = s + "."
    after_dot = "."
  }
  for i in range(precision - after_dot.len() + 1) {
    s = s + "0"
  }
  if s.ends-with(".") {
    s = s.slice(0, -1)
  }
  s
}

#let m(a, b) = {
  if a == none or b == none {
    none
  } else {
    a - b
  }
}

#let avgDif(x, step, precision) = {
  if x == none {
    none
  } else {
    let sum = 0
    let count = 0
    for i in range(0, step) {
      if x.at(i) != none and x.at(i + step) != none {
        sum = sum + m(x.at(i + step), x.at(i))
        count = count + 1
      }
    }
    if count == 0 {
      none
    } else {
      r(sum / count / step, precision)
    }
  }
}

#let avgDiff(x, step, precision) = {
  if x == none {
    none
  } else {
    let sum = 0
    let count = 0
    for i in range(0, step) {
      if x.at(i) != none and x.at(i + step) != none {
        sum = sum + m(x.at(i + step), x.at(i))
        count = count + 1
      }
    }
    if count == 0 {
      none
    } else {
      [ $ #f(sum / count / step, precision) $ ]
    }
  }
}

#let relErr(x, y, step, precision) = {
  if y == none {
    none
  } else {
    x = avgDif(x, step, precision)
    if x == none {
      none
    } else {
      r(calc.abs(x - y) / y, precision)
    }
  }
}

#let p(x, precision) = {
  [ $ #(f(x * 100, precision))% $ ]
}

#let ls(data) = {
  let n = data.len()
  let sumX = data.map(a => a.at(0)).sum()
  let sumY = data.map(a => a.at(1)).sum()
  let sumXX = data.map(a => a.at(0) * a.at(0)).sum()
  let sumXY = data.map(a => a.at(0) * a.at(1)).sum()
  let a = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
  let b = (sumY - a * sumX) / n
  (a, b)
}

#set page(numbering: "1", margin: (left: 6em, right: 6em))

#labreport(
  course-name: [数字信号处理实验],
  exper-name: [滤波器设计、设计性实验],
  exper-date: [2025-12-8],
  handin-date: [2025-12-30],
  exper-no: [4],
  room-no: [D3b-319],
  desk-no: [32],
  teacher: [宁更新],
)(
  objectives: [
    == FIR 滤波器设计
        - 掌握有限冲激响应(FIR)数字滤波器的常用性能指标及线性相位特性。
        - 熟悉凯泽窗(kaiser)窗函数法设计FIR滤波器的流程，包括指标映射、阶数估计与窗参数选择。
        - 通过带通、高通、带阻三类典型设计，理解指标到实现的对应关系，并验证幅频/相位响应。

    == Web 音频信号处理平台
    1. 理解采样率和量化级数对语音及音乐信号的影响，验证采样定理的实际应用。
    2. 掌握数字滤波器设计方法，能够针对实际噪声（如 50Hz 工频干扰）设计有效的滤波方案。
    3. 深入了解回声产生机理，对比梳状滤波器和全通滤波器在回声效果实现中的差异。
    4. 理解音频均衡器的工作原理，掌握参数化均衡器的设计与实现方法。
    5. 综合运用数字信号处理理论知识，开发完整的音频处理实验平台。
  ],
  principles: [
    == FIR 滤波器设计
        - FIR线性相位条件: 系数关于中点对称或反对称，幅频响应由原型幅度与窗函数共同决定。
        - 窗函数法核心步骤:
          1. 将指标(通带/阻带边缘、容差)归一化到0\~1 (对应0\~π)。
          2. 利用 `kaiserord` 根据容差(devp/devs)估计最小阶数 N 与窗参数 beta。
          3. 用 `fir1` 搭配凯泽窗 `kaiser(N+1, beta)` 生成系数 b，并选择滤波类型(ftype)。
          4. 用 `freqz` 评估幅频和相位响应，检验通/阻带指标与过渡带宽。
        - 通带/阻带容差换算:
          - 通带波纹 Rp(dB): $"devp" = (10^("Rp"/20) - 1) / (10^("Rp"/20) + 1)$
          - 阻带衰减 Rs(dB): $"devs" = 10^(-"Rs"/20)$
          - 线性容差越小 → 阶数越大；过渡带越窄 → 阶数越大。
        - 指标与长度: 凯泽窗法通常可近似满足“给定容差+过渡带最小阶数”的需求；若需奇数阶以保证对称相位，可对 N 做奇偶调整。

    == Web 音频信号处理平台
    ==== 采样与量化
    
    根据 Nyquist-Shannon 采样定理，为完整重建连续时间信号，采样频率 $f_s$ 必须满足：
    
    $ f_s >= 2 f_("max") $
    
    其中 $f_("max")$ 为信号的最高频率分量。对于人耳可听范围（20Hz-20kHz），标准 CD 采样率设定为 44.1kHz。
    
    量化过程将连续幅度的采样值映射到有限个离散电平，量化级数 $L$ 与比特深度 $b$ 的关系为：
    
    $ L = 2^b $
    
    量化噪声的信噪比（SNR）可近似表示为：
    
    $ "SNR" approx 6.02b + 1.76 "dB" $
    
    ==== 数字滤波器设计
    
    本实验采用双二阶（Biquad）IIR 滤波器，其传递函数为：
    
    $ H(z) = (b_0 + b_1 z^(-1) + b_2 z^(-2)) / (1 + a_1 z^(-1) + a_2 z^(-2)) $
    
    对于带阻滤波器（Notch Filter），用于去除特定频率 $f_0$ 的干扰：
    
    $ H(z) = (1 - 2 cos(omega_0) z^(-1) + z^(-2)) / (1 - 2r cos(omega_0) z^(-1) + r^2 z^(-2)) $
    
    其中 $omega_0 = 2 pi f_0 slash f_s$，$r$ 为极点半径，决定带宽。品质因数 $Q$ 与带宽的关系：
    
    $ Q = f_0 / "BW" $
    
    ==== 回声效果实现
    
    *梳状滤波器（Comb Filter）*：
    
    采用前馈结构（FIR 型），差分方程为：
    
    $ y(n) = x(n) + alpha dot x(n - R) $
    
    其中 $alpha$ 为回声衰减系数（$|alpha| < 1$），$R$ 为延迟采样点数。频率响应呈现周期性峰谷，形似"梳齿"：
    
    $ H(e^(j omega)) = 1 + alpha e^(-j omega R) $
    
    幅度响应：
    
    $ |H(e^(j omega))| = sqrt(1 + alpha^2 + 2 alpha cos(omega R)) $
    
    *全通滤波器（All-pass Filter）*：
    
    采用反馈结构（IIR 型），传递函数为：
    
    $ H(z) = (alpha + z^(-R)) / (1 + alpha z^(-R)) $
    
    时域差分方程：
    
    $ y(n) = alpha x(n) + x(n - R) - alpha y(n - R) $
    
    特点是所有频率的幅度增益恒为 1，仅改变相位响应，产生更自然的多次回声效果。
    
    ==== 参数化均衡器
    
    均衡器通过级联多个带通滤波器实现频率响应的精细调整。采用峰值滤波器（Peaking Filter）结构：
    
    $ H(z) = (b_0 + b_1 z^(-1) + b_2 z^(-2)) / (1 + a_1 z^(-1) + a_2 z^(-2)) $
    
    其中系数根据中心频率 $f_c$、增益 $G$（dB）和品质因数 $Q$ 计算：
    
    $ A = 10^(G slash 40) $
    
    $ omega_0 = 2 pi f_c slash f_s $
    
    $ alpha = sin(omega_0) / (2Q) $
    
    低频和高频分别使用低频架式（Lowshelf）和高频架式（Highshelf）滤波器，以更平滑地调整频谱边缘。
    
    ==== 频谱分析
    
    采用快速傅里叶变换（FFT）将时域信号转换到频域：
    
    $ X(k) = sum_(n=0)^(N-1) x(n) e^(-j 2 pi k n slash N) $
    
    为减少频谱泄漏，应用汉明窗（Hamming Window）：
    
    $ w(n) = 0.54 - 0.46 cos((2 pi n) / (N - 1)) $
    
    频率分辨率：
    
    $ Delta f = f_s / N $
    

    = 实验内容
    == FIR 滤波器设计
    === 带通FIR滤波器
        - 指标(归一化 0\~1 → 0\~π):
          - 阻带: [0, 0.3], [0.75, 1]
          - 通带: [0.45, 0.65]
          - 通带波纹 Rp = 1 dB → devp 按公式计算
          - 阻带衰减 Rs = 40 dB → $"devs" = 10^(-40/20)$
        - 设计步骤:
          1. 用 `kaiserord(f, a, dev)` 得到 N, Wn, beta, ftype。
          2. 若 N 偶数，为保持线性相位，将 N = N + 1。
          3. `b = fir1(N, Wn, ftype, kaiser(N+1, beta))`。
          4. `freqz` 观察幅频与相位响应。
    
    === 线性相位高通FIR滤波器
        - 指标(归一化):
          - 阻带截止 Ws = 0.5
          - 通带截止 Wp = 0.7
          - 容差: δp = δs = 0.001
        - 设计步骤:
          1. `kaiserord([0.5, 0.7], [0, 1], [0.001, 0.001])` 得 N, Wn, beta, ftype。
          2. 长度 L = N + 1；采用 `fir1(N, Wn, "high", kaiser(L, beta))`。
          3. `freqz` 检验高通幅频/相位。
    
    === 线性相位带阻FIR滤波器
        - 实际指标:
          - Fs = 20 kHz
          - 通带: Fp1 = 2 kHz, Fp2 = 8 kHz
          - 阻带: Fs1 = 3 kHz, Fs2 = 6 kHz
          - 通带容差: $0.99 <= |H| <= 1.01$ → $"devp" = 0.01$
          - 阻带容差: $|H| <= 0.005$ → $"devs" = 0.005$
        - 归一化频率 (相对 Fs/2):
          - f = [0.2, 0.3, 0.6, 0.8], a = [1, 0, 1], dev = [0.01, 0.005, 0.01]
        - 设计步骤:
          1. `kaiserord` 得到 N, Wn, beta, ftype，长度 L = N + 1。
          2. `fir1(N, Wn, "stop", kaiser(L, beta))`。
          3. `freqz(b,1,1024, Fs)` 以实际频率刻度绘制。
    
    = 实验代码
    === 带通FIR滤波器
        ```matlab
        clear; clc;
    
        %% 1. 定义指标（归一化频率：0~1对应0~π）
        % 频段划分：[0,0.3]阻带 → [0.45,0.65]通带 → [0.75,1]阻带
        f = [0.3, 0.45, 0.65, 0.75];  % 频率边界（升序，2×频段数）
        a = [0, 1, 0];                % 各频段幅度（阻带0，通带1）
    
        % 容差计算（线性值）
        Rp = 1;             % 通带波纹（dB）
        Rs = 40;            % 阻带衰减（dB）
        devp = (10^(Rp/20)-1)/(10^(Rp/20)+1);  % 通带容差（线性）
        devs = 10^(-Rs/20);                    % 阻带容差（线性）
        dev = [devs, devp, devs];              % 各频段容差（与a长度一致）
    
        %% 2. 计算凯泽窗阶数和beta
        [N, Wn, beta, ftype] = kaiserord(f, a, dev);
        % 确保阶数为奇数（线性相位要求）
        if mod(N,2)==0
            N = N + 1;
        end
    
        %% 3. 设计带通滤波器（窗函数法）
        b = fir1(N, Wn, ftype, kaiser(N+1, beta));
    
        %% 4. 绘制幅频&相位响应
        figure;
        freqz(b, 1);
        title('带通FIR滤波器（窗函数法-凯泽窗）幅频和相位响应');
        ```
    === 线性相位高通FIR滤波器
        ```matlab
        clear; clc;
    
        %% 1. 定义指标（归一化频率）
        % ωp=0.7π → Wp=0.7；ωs=0.5π → Ws=0.5；δp=δs=0.001
        f = [0.5, 0.7];       % 频率边界：[0,0.5]阻带 → [0.7,1]通带
        a = [0, 1];           % 各频段幅度（阻带0，通带1）
        dev = [0.001, 0.001]; % 各频段容差（δs=0.001，δp=0.001）
    
        %% 2. 计算凯泽窗参数（不强制奇数阶）
        [N, Wn, beta, ftype] = kaiserord(f, a, dev);
        % 手动确认滤波器长度：阶数N → 长度L=N+1
        L = N + 1;
    
        %% 3. 设计高通滤波器（适配阶数自动调整）
        % fir1的'high'选项自动适配线性相位（偶数阶）
        b = fir1(N, Wn, 'high', kaiser(L, beta));
    
        %% 4. 绘制幅频&相位响应
        figure;
        freqz(b, 1);
        title('线性相位高通FIR滤波器（窗函数法-凯泽窗）幅频和相位响应');
        ```
    === 线性相位带阻FIR滤波器
        ```matlab
        clear; clc;
    
        %% 1. 定义指标（转换为归一化频率）
        Fs = 20e3;  % 采样频率
        % 实际频率 → 归一化频率（f_norm = f/(Fs/2)）
        Fp1 = 2e3; Fp2 = 8e3; % 通带截止
        Fs1 = 3e3; Fs2 = 6e3; % 阻带截止
        f = [Fp1/(Fs/2), Fs1/(Fs/2), Fs2/(Fs/2), Fp2/(Fs/2)]; % [0.2,0.3,0.6,0.8]
        a = [1, 0, 1];                                        % 各频段幅度（通1，阻0）
    
        % 容差计算（线性值）
        devp = (1.01 - 0.99)/2; % 通带容差：±0.01 → 线性容差0.01
        devs = 0.005;           % 阻带容差：≤0.005
        dev = [devp, devs, devp]; % 各频段容差（与a长度一致）
    
        %% 2. 计算凯泽窗参数
        [N, Wn, beta, ftype] = kaiserord(f, a, dev);
        L = N + 1; % 滤波器长度=阶数+1
    
        %% 3. 设计带阻滤波器（适配线性相位）
        % 'stop'选项自动保证线性相位，窗长度严格匹配滤波器长度
        b = fir1(N, Wn, 'stop', kaiser(L, beta));
    
        %% 4. 绘制幅频（实际频率）&相位响应
        figure;
        [H, f_freq] = freqz(b, 1, 1024, Fs);
        subplot(2,1,1);
        plot(f_freq/1e3, 20*log10(abs(H)));
        grid on; xlabel('频率（kHz）'); ylabel('幅度（dB）');
        title('带阻FIR滤波器（窗函数法-凯泽窗）幅频响应');
        subplot(2,1,2);
        plot(f_freq/1e3, angle(H));
        grid on; xlabel('频率（kHz）'); ylabel('相位（弧度）');
        title('相位响应');
        ```
    

    == Web 音频信号处理平台
    
    ==== 系统架构设计
    
    开发基于 Web 技术栈的音频信号处理实验平台，主要技术选型：
    
    - *前端框架*：SvelteKit（Svelte 5）+ TypeScript
    - *样式方案*：TailwindCSS + DaisyUI
    - *音频处理*：Web Audio API
    - *信号算法*：自实现 DSP 算法（重采样、滤波、效果器）
    
    系统采用标签页式界面，分为五个功能模块：
    
    1. *录音与上传*：麦克风录音、文件上传
    2. *采样分析*：采样率/量化级数调整与对比
    3. *滤波器设计*：噪声注入与滤波去噪
    4. *回声处理*：双算法实现与对比
    5. *参数均衡器*：9 频段调节与预设效果
    
    ==== 音频输入/输出实现
    
    *录音功能*：
    
    使用 WebRTC MediaRecorder API 实现实时录音：
    
    ```typescript
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder = new MediaRecorder(stream);
    mediaRecorder.ondataavailable = (event) => {
      audioChunks.push(event.data);
    };
    ```
    
    录音数据转换为 AudioBuffer：
    
    ```typescript
    const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
    const arrayBuffer = await audioBlob.arrayBuffer();
    const buffer = await audioContext.decodeAudioData(arrayBuffer);
    ```
    
    *文件上传*：
    
    支持多种音频格式（MP3, WAV, OGG, FLAC）：
    
    ```typescript
    const file = input.files?.[0];
    const arrayBuffer = await file.arrayBuffer();
    const buffer = await audioContext.decodeAudioData(arrayBuffer);
    ```
    
    ==== 采样率与量化实现
    
    *重采样算法*：
    
    采用线性插值方法实现任意采样率转换：
    
    ```typescript
    function resampleAudio() {
      const originalData = audioBuffer.getChannelData(channel);
      const newLength = Math.ceil(duration * targetSampleRate);
      
      for (let i = 0; i < newLength; i++) {
        const originalIndex = (i / newLength) * originalData.length;
        const index0 = Math.floor(originalIndex);
        const index1 = Math.min(index0 + 1, originalData.length - 1);
        const fraction = originalIndex - index0;
        
        // 线性插值
        let sample = originalData[index0] * (1 - fraction) 
                   + originalData[index1] * fraction;
        
        // 量化处理
        const levels = Math.pow(2, bitDepth) - 1;
        sample = Math.round(sample * levels) / levels;
        
        newData[i] = sample;
      }
    }
    ```
    
    提供 6 种采样率预设（8kHz ~ 48kHz）和 5 种量化位数选项（4bit ~ 24bit），可实时对比原始音频与处理后音频的听觉差异。
    
    ==== 滤波器设计与噪声去除
    
    *噪声注入*：
    
    在原始信号中叠加可调频率的正弦波模拟工频干扰：
    
    ```typescript
    for (let i = 0; i < length; i++) {
      const t = i / sampleRate;
      const noise = noiseAmplitude * Math.sin(2 * Math.PI * noiseFrequency * t);
      noisyData[i] = originalData[i] + noise;
    }
    ```
    
    *带阻滤波器*：
    
    使用 Web Audio API 的 BiquadFilterNode 实现：
    
    ```typescript
    const filter = offlineContext.createBiquadFilter();
    filter.type = 'notch';
    filter.frequency.value = noiseFrequency;  // 中心频率
    filter.Q.value = filterQ;                 // 品质因数
    ```
    
    支持 7 种滤波器类型（notch, lowpass, highpass, bandpass, lowshelf, highshelf, peaking），Q 值可在 0.1 ~ 50 范围调节，实现精确的频率选择性。
    
    ==== 回声效果实现
    
    *梳状滤波器实现*：
    
    ```typescript
    function applyCombFilterEcho() {
      const delayInSamples = Math.floor(echoDelay * sampleRate);
      
      for (let i = 0; i < length; i++) {
        let sample = 0;
        
        // 原始信号
        if (i < input.length) {
          sample += input[i];
        }
        
        // 延迟信号
        if (i >= delayInSamples && i - delayInSamples < input.length) {
          sample += echoDecay * input[i - delayInSamples];
        }
        
        output[i] = sample;
      }
    }
    ```
    
    *全通滤波器实现*：
    
    ```typescript
    function applyAllpassFilterEcho() {
      const delayInSamples = Math.floor(echoDelay * sampleRate);
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
    ```
    
    参数可调范围：
    - 延迟时间：50ms ~ 1000ms
    - 衰减系数：0 ~ 0.99
    
    界面提供详细的算法对比表格，说明两种实现方式在幅度响应、相位响应、反馈特性、稳定性等方面的差异。
    
    ==== 参数化均衡器设计
    
    *9 频段配置*：
    
    选取覆盖完整音频频谱的 9 个中心频率：
    
    $ 60"Hz", 170"Hz", 310"Hz", 600"Hz", 1"kHz", 3"kHz", 6"kHz", 12"kHz", 14"kHz" $
    
    低频（60Hz）和高频（14kHz）使用架式滤波器，中频使用峰值滤波器。
    
    *级联滤波器实现*：
    
    ```typescript
    function applyEqualizer() {
      let currentNode: AudioNode = source;
      
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
    }
    ```
    
    每个频段独立可调：
    - 增益范围：±12dB
    - Q 值范围：0.1 ~ 10
    - 可单独启用/禁用
    
    *预设效果*：
    
    提供 9 种预设配置：
    - Flat（平直）
    - Bass Boost（低音增强）
    - Treble Boost（高音增强）
    - Vocal（人声优化）
    - Classical（古典音乐）
    - Rock（摇滚）
    - Jazz（爵士）
    - Pop（流行）
    - Electronic（电子音乐）
    
    *可视化*：
    
    频率响应曲线以柱状图实时显示各频段增益，采用色彩编码区分不同频段，中线为 0dB 基准。
    
    ==== 频谱分析器
    
    *FFT 实现*：
    
    使用优化的离散傅里叶变换（DFT）算法，支持 512 ~ 8192 点的 FFT 大小：
    
    ```typescript
    function analyzeSpectrum() {
      // 应用汉明窗
      for (let i = 0; i < fftSize; i++) {
        const windowValue = 0.54 - 0.46 * Math.cos(2 * Math.PI * i / (fftSize - 1));
        windowed[i] = samples[i] * windowValue;
      }
      
      // DFT 计算（采用采样优化）
      for (let k = 0; k < fftSize / 2; k++) {
        let realSum = 0;
        let imagSum = 0;
        const step = Math.max(1, Math.floor(fftSize / 256));
        
        for (let n = 0; n < fftSize; n += step) {
          const angle = (-2 * Math.PI * k * n) / fftSize;
          realSum += windowed[n] * Math.cos(angle);
          imagSum += windowed[n] * Math.sin(angle);
        }
        
        magnitude[k] = Math.sqrt(realSum * realSum + imagSum * imagSum) / fftSize;
      }
    }
    ```
    
    为避免大 FFT 尺寸导致的性能问题，采用自适应采样策略，在保证频谱分辨率的同时确保实时响应。
    
    频谱显示采用对数刻度和色彩映射：
    - X 轴：对数频率刻度（20Hz ~ 20kHz）
    - Y 轴：dB 幅度（归一化后 -60dB ~ 0dB）
    - 颜色：HSL 色彩映射，从低频（蓝）到高频（红）
    

    == 实验代码
    
    完整代码已托管在 GitHub 仓库，主要文件结构：
    
    ```
    src/routes/audio-experiment/
    ├── +page.svelte              # 主页面，标签页导航
    ├── AudioRecorder.svelte      # 录音与上传模块
    ├── SamplingAnalyzer.svelte   # 采样分析模块
    ├── FilterDesigner.svelte     # 滤波器设计模块
    ├── EchoProcessor.svelte      # 回声处理模块
    ├── Equalizer.svelte          # 均衡器模块
    └── SpectrumAnalyzer.svelte   # 频谱分析器模块
    ```
    
    关键代码片段已在"实验内容"部分给出，完整实现请参考源代码仓库。
    
  ],
  data: [
    == FIR 滤波器设计
    === 带通FIR滤波器
        #align(center, image("/assets/image17651786226920.png", width: 82%))
        通带平坦，阻带满足约40 dB 衰减，过渡带宽由 (0.3→0.45) 与 (0.65→0.75) 决定阶数。
    === 线性相位高通FIR滤波器
        #align(center, image("/assets/image17651786299990.png", width: 82%))
        阻带深度约 60 dB 以上，通带平坦，线性相位保持。
    === 线性相位带阻FIR滤波器
        #align(center, image("/assets/image17651785518680.png", width: 82%))
        3\~6 kHz 阻带抑制优于 46 dB；2 kHz 与 8 kHz 处通带波纹约 ±0.01。

    == Web 音频信号处理平台
  ],
  analysis: [
    == FIR 滤波器设计
        - 阶数与过渡带/容差关系: 过渡带越窄、容差越严，`kaiserord` 给出的 N 越大；带阻设计因双过渡带，阶数通常大于单过渡带高通/带通。
        - 窗参数 beta: 阻带衰减越高 → beta 越大，旁瓣电平下降但主瓣变宽，折中体现为阶数与过渡带宽共同作用。
        - 线性相位检查: `freqz` 相位呈近似线性斜率，偶有数值抖动来自有限精度与相位展开；奇数阶对称或偶数阶反对称保证群时延常数。
        - 归一化与实际频率: 高通与带通示例直接用归一化频率；带阻示例展示了实际 kHz 坐标，更贴合指标验证。

    == Web 音频信号处理平台
    
    ==== 采样定理验证
    
    实验结果验证了 Nyquist-Shannon 采样定理的实际应用：
    
    1. *语音信号*：8kHz 采样率足以重建可理解的语音，但音质较差。16kHz 采样率可提供较好的语音质量，满足宽带通信要求。
    
    2. *音乐信号*：低于 22.05kHz 的采样率会导致高频信息丢失，音色变暗淡、细节减少。44.1kHz 采样率（CD 标准）能够重建完整的音频频谱，满足高保真要求。
    
    3. *量化效果*：16bit 量化级数提供约 96dB 的动态范围，足以覆盖人耳听觉范围。低于 12bit 时，量化噪声可听且影响音质。
    
    ==== 滤波器性能分析
    
    带阻滤波器成功去除了 50Hz 工频噪声，实验验证了以下要点：
    
    1. *Q 值影响*：高 Q 值（>20）提供窄带阻，对通带影响最小。低 Q 值会扩大阻带范围，可能影响临近频率分量。
    
    2. *滤波器类型*：
       - Notch（带阻）：精确去除单频噪声
       - Lowpass（低通）：去除高频噪声
       - Highpass（高通）：去除低频噪声
       - Bandpass（带通）：提取特定频段
    
    3. *实际应用*：对于复杂噪声环境，单一滤波器可能不足，需要级联多个滤波器或采用自适应滤波技术。
    
    ==== 回声算法比较
    
    两种回声实现算法的对比实验揭示了深层次的信号处理原理：
    
    1. *梳状滤波器*：
       - 优点：计算简单、单次回声清晰、稳定性好
       - 缺点：频率响应周期性波动、音色失真
       - 适用场景：特效处理、延迟效果器
    
    2. *全通滤波器*：
       - 优点：幅度响应平坦、多次回声自然、混响效果好
       - 缺点：需要反馈控制、稳定性要求高（$|alpha| < 1$）
       - 适用场景：混响模拟、空间音效
    
    3. *数学本质*：
       - FIR（梳状）：线性相位、有限长冲激响应、绝对稳定
       - IIR（全通）：非线性相位、无限长冲激响应、条件稳定
    
    ==== 均衡器效能分析
    
    9 频段参数均衡器实现了对音频频谱的精细控制：
    
    1. *频段划分*：采用对数分布的频率点，符合人耳对频率的对数感知特性。
    
    2. *独立调节*：每个频段使用独立的带通滤波器，相互影响小。级联结构确保总体频率响应为各滤波器的乘积。
    
    3. *预设效果*：提供了多种音乐风格的预设，用户可以直接应用或在其基础上微调。
    
    4. *可视化反馈*：实时显示的频率响应曲线帮助用户直观理解均衡器效果。
    
    5. *应用价值*：
       - 音乐制作：修正录音缺陷、塑造音色
       - 现场扩声：补偿房间声学特性
       - 个人听音：根据偏好调整音质
    
    ==== Web 平台优势
    
    基于 Web 技术实现音频处理平台具有以下优势：
    
    1. *跨平台性*：浏览器统一环境，无需安装专用软件。
    
    2. *实时交互*：图形界面直观，参数调整即时响应。
    
    3. *教学价值*：结合理论解释和实际操作，增强学习效果。
    
    4. *可扩展性*：易于添加新功能、更新算法。
    
    5. *Web Audio API*：提供硬件加速的音频处理能力，性能接近原生应用。
    
    ==== 性能优化
    
    实验中采用的优化策略：
    
    1. *离线处理*：使用 OfflineAudioContext 进行批量处理，避免实时音频流的延迟。
    
    2. *自适应采样*：FFT 计算中根据尺寸动态调整采样步长，平衡精度与速度。
    
    3. *Web Workers*：对于耗时计算（如大规模 FFT），可迁移到后台线程。
    
    4. *缓存策略*：重复使用相同参数的处理结果，减少冗余计算。
    

    = 实验总结
    == FIR 滤波器设计
        - 凯泽窗法提供了可控旁瓣衰减与主瓣宽度的折衷，`kaiserord` 可直接从容差与过渡带估计最小阶数，适合工程快速设计。
        - 对线性相位FIR，需关注阶数奇偶与 `fir1` 选项匹配，必要时手动调整 N 确保对称性。
        - 三类滤波器均满足给定指标：带通与高通在归一化域抑制达标，带阻在实际频率域实现 3~6 kHz 有效抑制且通带波纹受控。
        - 若需进一步减小阶数，可放宽容差或适当加宽过渡带；若需更陡峭过渡，可考虑等波纹窗或频率抽样/最小二乘/ Parks–McClellan(Equiripple) 等方法。

    == Web 音频信号处理平台
    
    本课程设计性实验综合运用了数字信号处理的核心理论和技术，完成了一个功能完整的 Web 音频处理平台。主要成果和收获如下：
    
    ==== 理论与实践结合
    
    1. *采样定理*：通过实验直观验证了采样率对信号重建的影响，深化了对 Nyquist 频率的理解。
    
    2. *数字滤波器*：掌握了 IIR 滤波器的设计方法，理解了频率响应、Q 值等参数的物理意义。
    
    3. *时域与频域*：通过回声效果和频谱分析，建立了时域操作与频域特性的对应关系。
    
    4. *信号处理链*：实现了完整的音频处理流程：输入→分析→处理→输出，理解了各环节的作用。
    
    ==== 工程实现能力
    
    1. *算法编程*：自主实现了重采样、滤波、回声、均衡器等核心算法，提升了编程能力。
    
    2. *性能优化*：针对浏览器环境的特点，采用了多种优化策略，确保实时响应。
    
    3. *用户界面*：设计了友好的交互界面，实现了参数可视化和实时反馈。
    
    4. *代码质量*：遵循 TypeScript 类型规范，通过 ESLint 和 Prettier 保证代码质量。
    
    ==== 创新与扩展
    
    1. *双算法对比*：梳状滤波器和全通滤波器的并行实现，提供了算法原理的深入比较。
    
    2. *详细文档*：每个模块都配有理论解释和使用说明，具有教学价值。
    
    3. *完整性*：涵盖了从录音到效果处理的全流程，形成闭环实验。
    
    4. *可扩展性*：模块化设计便于后续添加新功能（如更多滤波器类型、高级效果器）。
    
    ==== 不足与改进
    
    1. *算法精度*：部分算法（如 DFT）采用了简化实现，可进一步优化为标准 FFT。
    
    2. *滤波器设计*：当前使用 Web Audio API 内置滤波器，可尝试自实现双二阶级联结构。
    
    3. *效果多样性*：可增加更多音频效果（如压缩、失真、合唱等）。
    
    4. *性能监控*：增加实时性能指标显示（CPU 使用率、处理延迟）。
    
    5. *批量处理*：支持多文件批量处理和批量导出。
    
    ==== 应用价值
    
    本实验平台不仅完成了课程要求的所有任务，还具有实际应用价值：
    
    1. *教学工具*：可用于数字信号处理课程的实验教学，帮助学生理解抽象概念。
    
    2. *自学资源*：详细的理论说明和代码实现，适合自学者研究。
    
    3. *快速原型*：为音频处理算法提供快速验证平台，加速开发迭代。
    
    4. *开源贡献*：代码可开源共享，为社区提供学习和参考资源。
    
    ==== 结语
    
    通过本次课程设计性实验，我深刻体会到数字信号处理理论的实际应用价值。从数学公式到可运行的代码，从抽象概念到直观的音频效果，这一过程不仅锻炼了技术能力，更培养了系统思维和工程素养。
    
    Web 技术为信号处理提供了新的实现途径，Web Audio API 的强大功能使得浏览器可以完成过去只能在专业软件中实现的复杂处理。这也启示我们，技术的发展正在打破传统界限，跨学科融合将带来更多创新可能。
    
    未来，我计划在以下方向继续改进：
    1. 添加更多高级音频效果（动态处理、立体声处理）
    2. 实现实时音频流处理（低延迟模式）
    3. 集成机器学习算法（音频分类、降噪）
    4. 开发移动端适配版本
    
    数字信号处理的学习永无止境，本次实验只是一个起点。期待将所学知识应用到更广阔的领域，为音频技术的发展贡献一份力量。
  ],
)
