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
