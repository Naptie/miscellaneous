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
    - 掌握有限冲激响应(FIR)数字滤波器的常用性能指标及线性相位特性。
    - 熟悉凯泽窗(kaiser)窗函数法设计FIR滤波器的流程，包括指标映射、阶数估计与窗参数选择。
    - 通过带通、高通、带阻三类典型设计，理解指标到实现的对应关系，并验证幅频/相位响应。
  ],
  principles: [
    - FIR线性相位条件: 系数关于中点对称或反对称，幅频响应由原型幅度与窗函数共同决定。
    - 窗函数法核心步骤:
      1. 将指标(通带/阻带边缘、容差)归一化到0\~1 (对应0\~π)。
      2. 利用 `kaiserord` 根据容差(devp/devs)估计最小阶数 N 与窗参数 beta。
      3. 用 `fir1` 搭配凯泽窗 `kaiser(N+1, beta)` 生成系数 b，并选择滤波类型(ftype)。
      4. 用 `freqz` 评估幅频和相位响应，检验通/阻带指标与过渡带宽。
    - 通带/阻带容差换算:
      - 通带波纹 Rp(dB): devp = (10^(Rp/20) - 1) / (10^(Rp/20) + 1)
      - 阻带衰减 Rs(dB): devs = 10^(-Rs/20)
      - 线性容差越小 → 阶数越大；过渡带越窄 → 阶数越大。
    - 指标与长度: 凯泽窗法通常可近似满足“给定容差+过渡带最小阶数”的需求；若需奇数阶以保证对称相位，可对 N 做奇偶调整。

    = 实验内容
    == 带通FIR滤波器
    - 指标(归一化 0\~1 → 0\~π):
      - 阻带: [0, 0.3], [0.75, 1]
      - 通带: [0.45, 0.65]
      - 通带波纹 Rp = 1 dB → devp 按公式计算
      - 阻带衰减 Rs = 40 dB → devs = 10^(-40/20)
    - 设计步骤:
      1. 用 `kaiserord(f, a, dev)` 得到 N, Wn, beta, ftype。
      2. 若 N 偶数，为保持线性相位，将 N = N + 1。
      3. `b = fir1(N, Wn, ftype, kaiser(N+1, beta))`。
      4. `freqz` 观察幅频与相位响应。

    == 线性相位高通FIR滤波器
    - 指标(归一化):
      - 阻带截止 Ws = 0.5
      - 通带截止 Wp = 0.7
      - 容差: δp = δs = 0.001
    - 设计步骤:
      1. `kaiserord([0.5, 0.7], [0, 1], [0.001, 0.001])` 得 N, Wn, beta, ftype。
      2. 长度 L = N + 1；采用 `fir1(N, Wn, "high", kaiser(L, beta))`。
      3. `freqz` 检验高通幅频/相位。

    == 线性相位带阻FIR滤波器
    - 实际指标:
      - Fs = 20 kHz
      - 通带: Fp1 = 2 kHz, Fp2 = 8 kHz
      - 阻带: Fs1 = 3 kHz, Fs2 = 6 kHz
      - 通带容差: 0.99 ≤ |H| ≤ 1.01 → devp = 0.01
      - 阻带容差: |H| ≤ 0.005 → devs = 0.005
    - 归一化频率 (相对 Fs/2):
      - f = [0.2, 0.3, 0.6, 0.8], a = [1, 0, 1], dev = [0.01, 0.005, 0.01]
    - 设计步骤:
      1. `kaiserord` 得到 N, Wn, beta, ftype，长度 L = N + 1。
      2. `fir1(N, Wn, "stop", kaiser(L, beta))`。
      3. `freqz(b,1,1024, Fs)` 以实际频率刻度绘制。

    = 实验代码
    == 带通FIR滤波器
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
    == 线性相位高通FIR滤波器
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
    == 线性相位带阻FIR滤波器
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

  ],
  data: [
    == 带通FIR滤波器
    #align(center, image("/assets/image17651786226920.png", width: 82%))
    通带平坦，阻带满足约40 dB 衰减，过渡带宽由 (0.3→0.45) 与 (0.65→0.75) 决定阶数。
    == 线性相位高通FIR滤波器
    #align(center, image("/assets/image17651786299990.png", width: 82%))
    阻带深度约 60 dB 以上，通带平坦，线性相位保持。
    == 线性相位带阻FIR滤波器
    #align(center, image("/assets/image17651785518680.png", width: 82%))
    3\~6 kHz 阻带抑制优于 46 dB；2 kHz 与 8 kHz 处通带波纹约 ±0.01。
  ],
  analysis: [
    - 阶数与过渡带/容差关系: 过渡带越窄、容差越严，`kaiserord` 给出的 N 越大；带阻设计因双过渡带，阶数通常大于单过渡带高通/带通。
    - 窗参数 beta: 阻带衰减越高 → beta 越大，旁瓣电平下降但主瓣变宽，折中体现为阶数与过渡带宽共同作用。
    - 线性相位检查: `freqz` 相位呈近似线性斜率，偶有数值抖动来自有限精度与相位展开；奇数阶对称或偶数阶反对称保证群时延常数。
    - 归一化与实际频率: 高通与带通示例直接用归一化频率；带阻示例展示了实际 kHz 坐标，更贴合指标验证。

    = 实验总结
    - 凯泽窗法提供了可控旁瓣衰减与主瓣宽度的折衷，`kaiserord` 可直接从容差与过渡带估计最小阶数，适合工程快速设计。
    - 对线性相位FIR，需关注阶数奇偶与 `fir1` 选项匹配，必要时手动调整 N 确保对称性。
    - 三类滤波器均满足给定指标：带通与高通在归一化域抑制达标，带阻在实际频率域实现 3~6 kHz 有效抑制且通带波纹受控。
    - 若需进一步减小阶数，可放宽容差或适当加宽过渡带；若需更陡峭过渡，可考虑等波纹窗或频率抽样/最小二乘/ Parks–McClellan(Equiripple) 等方法。

  ],
)
