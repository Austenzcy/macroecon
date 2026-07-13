# IS-LM Solver v1

## 方程

当前 v1 只用于封闭经济、短期、价格刚性的 IS-LM 教学结算。

IS:

```text
Y = A - b i
```

LM:

```text
i = cY - d
```

联立求解：

```text
Y = (A + b d) / (1 + b c)
i = cY - d
```

## 参数含义

- `Y`：产出指数。
- `i`：利率，单位为百分比点，例如 `4` 表示 `4%`。
- `A`：自主支出强度。
- `b`：利率对支出的影响系数。
- `c`：收入对货币需求和利率的影响系数。
- `d`：货币供给或流动性条件参数。
- `Y_potential`：潜在产出，用于后续扩展。
- `u_base`、`pi_base`、`debt_base`：结算前的简化基准变量。
- `okun_beta`：产出变化对失业率的简化影响。
- `pi_sensitivity`：正向产出变化对通胀压力的简化影响。

## 政策映射

政策卡不直接写最终结果，而是写对模型参数的影响：

- `delta_A`：影响 IS 曲线。政府购买增加、减税等会提高 `A`，推动 IS 右移。
- `delta_d`：影响 LM 曲线。扩张性货币政策提高 `d`，推动 LM 右移或下移。
- `debt_delta`：当前 v1 中对债务率的简化影响。
- `mechanism`：用于 UI 和会议记录显示的机制解释。

## 多政策组合

多张政策卡不会把每张卡的 `Y`、`i`、`u`、`π`、`Debt` 结果简单相加。

v1 先合并政策对参数的影响：

```text
A_after = A + total_delta_A
d_after = d + total_delta_d
```

然后重新求解 IS-LM 均衡。这样可以保留“政策组合改变模型条件，然后产生新的均衡”的教学逻辑。

## 当前限制

- 只支持 IS-LM。
- 不处理 AD-AS、Mundell-Fleming、Solow。
- 不处理价格充分调整、预期、开放经济、固定汇率等机制。
- `u`、`π`、`Debt` 是 v1 的简化派生变量，不是完整宏观动态系统。
- `Y_potential` 暂时保留给后续评分、产出缺口和模型回放使用。

## 后续扩展

- 加入冲击对初始 `A`、`d` 或参数弹性的影响。
- 增加产出缺口和潜在产出约束。
- 将 `model_before`、`model_after`、`curve_shifts` 接入 ModelReplay。
- 为 AD-AS、Mundell-Fleming、Solow 增加独立 solver。
