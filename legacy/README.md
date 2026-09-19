# Legacy Manual Simulink Experiments

This folder records the manual Simulink experiments used to understand the
second-order dynamics before the project was reorganized into the automated
MATLAB/Simulink, Python/SciPy, and CI workflow in the repository root.

These models are intentionally kept as a learning trail. They show how the
differential equations map directly to Gain, Sum, and Integrator blocks before
the same dynamics are represented more compactly with a State-Space block.

## Manual Simulink Experiments

### 1. Hand-built autonomous oscillator

Model: `sensor_step_response.slx`

The model was constructed manually from the following blocks:

- two Integrator blocks for position $x$ and velocity $y$;
- one Gain block with gain `-k`;
- one Gain block with gain `-r`;
- one Sum block;
- one Scope for time-domain signals;
- one XY Graph for the phase portrait.

The block connections implement

```math
\dot{x}=y,
```

```math
\dot{y}=-kx-ry.
```

Equivalently,

```math
\ddot{x}+r\dot{x}+kx=0.
```

The position integrator receives the velocity $y$. The velocity integrator
receives the output of the Sum block. The two feedback paths pass through the
gains `-k` and `-r`, producing the restoring and damping terms $-kx$ and
$-ry$.

The Scope is used to inspect $x(t)$ and $y(t)$ in the time domain. The XY
Graph receives the pair $(x,y)$ and shows the phase portrait.

The model uses the workspace parameters `k`, `r`, `x0`, and `y0`. Its saved
simulation interval is 0 to 20 s, using a variable-step solver configuration.

The following parameter changes were used to explore different phase-plane
behaviors:

| $k$ | $r$ | Observed behavior |
|---:|---:|---|
| 1.2 | 0.2 | Stable focus |
| 1.2 | 0 | Center / undamped oscillator |
| 1.2 | -0.2 | Unstable focus |
| 1.2 | 2.5 | Stable node |
| 1.2 | -2.5 | Unstable node |
| -0.5 | 0.2 | Saddle |

These cases are the manually built counterparts of the automated eigenvalue
classification in `../matlab/get_test_cases.m`.

### 2. Adding an external input

The autonomous oscillator becomes a driven mechanical system when an external
input is added to the acceleration equation:

```math
\dot{x}=y,
```

```math
\dot{y}=u(t)-kx-ry.
```

Equivalently,

```math
\ddot{x}+r\dot{x}+kx=u(t).
```

The original autonomous model is recovered by setting $u(t)=0$. This is the
point at which the hand-built oscillator becomes a simplified normalized
mass-spring-damper model that can be interpreted as a MEMS-inspired sensing
element.

### 3. Sinusoidal excitation and resonance

Model: `sensor_sine_response.slx`

This model is a copy of the hand-built oscillator with a `Sine Wave` block
connected to the external-input port of the Sum block. The sine-wave frequency
is controlled by the workspace variable `omega`. The model retains the two
Integrators, the `-k` and `-r` feedback gains, Scope, and XY Graph.

The input is

```math
u(t)=A\sin(\omega t).
```

The manual experiment used:

```matlab
k = 1.2;
r = 0.2;
x0 = 0;
y0 = 0;
A = 1;
```

The following frequencies were tested one at a time:

```matlab
omega = 0.3;   % below resonance
omega = 1.1;   % near resonance
omega = 3.0;   % above resonance
```

The model uses a simulation interval of 0 to 80 s so that several cycles are
visible even for the low-frequency case.

The natural angular frequency is

```math
\omega_n=\sqrt{k}\approx1.095\ \mathrm{rad/s}.
```

For zero initial conditions, the Laplace-domain transfer function from input
to displacement is

```math
H_x(s)=\frac{X(s)}{U(s)}=\frac{1}{s^2+rs+k}.
```

At $s=j\omega$, the steady-state displacement magnitude is

```math
\lvert H_x(j\omega)\rvert
=\frac{1}{\sqrt{(k-\omega^2)^2+(r\omega)^2}}.
```

For the selected parameters, the approximate steady-state amplitudes are:

| Excitation frequency $\omega$ (rad/s) | Displacement magnitude $\lvert X/U\rvert$ | Velocity magnitude $\lvert Y/U\rvert$ |
|---:|---:|---:|
| 0.3 | 0.90 | 0.27 |
| 1.1 | 4.54 | 5.00 |
| 3.0 | 0.128 | 0.383 |

The physical interpretation is:

- At `omega = 0.3 rad/s`, the excitation is slow compared with the natural
  frequency. The displacement follows the input with a moderate amplitude.
- At `omega = 1.1 rad/s`, the excitation is close to resonance, so the
  displacement amplitude is strongly amplified.
- At `omega = 3.0 rad/s`, the excitation is much faster than the mechanical
  mode, so the displacement is attenuated.

Because $y=\dot{x}$, sinusoidal steady state gives

```math
\lvert Y\rvert=\omega\lvert X\rvert.
```

Therefore velocity is relatively small at low frequency but can become larger
than displacement near resonance or at higher frequency.

### 4. Manual frequency-sweep experiment

Model: `sensor_frequency_sweep.slx`

The single-frequency sine experiment can be extended into a time-domain
frequency sweep. This model is not a black-box Bode-plot block: it treats the
hand-built Gain--Sum--Integrator diagram as the plant, excites it with one
sinusoid at a time, and measures the steady-state input and displacement.

The same normalized mechanical equations are used:

```math
\dot{x}=y,
```

```math
\dot{y}=u-kx-ry.
```

Equivalently,

```math
\ddot{x}+r\dot{x}+kx=u(t).
```

The sinusoidal input is

```math
u(t)=A_{\mathrm{in}}\sin(\omega t).
```

The model logs the input and displacement to the MATLAB workspace as
`u_log` and `x_log`. This turns the experiment into a data path that can be
processed by MATLAB:

```text
Simulink plant -> u_log, x_log -> MATLAB frequency-response analysis
```

For one frequency, `measure_frequency_point.m` performs the following steps:

1. computes a simulation time from the system poles and excitation period;
2. runs the Simulink model with the selected `omega` and `Ain`;
3. discards the transient and keeps the final five complete periods;
4. fits sinusoids to `u_log` and `x_log`;
5. calculates the measured amplitude ratio and phase shift;
6. compares the measurement with the analytical transfer function.

For zero initial conditions, the transfer function from input to displacement
is

```math
H(s)=\frac{X(s)}{U(s)}
=\frac{1}{s^2+rs+k}.
```

Evaluating it on the imaginary axis gives

```math
H(j\omega)=\frac{1}{k-\omega^2+jr\omega}.
```

The measured magnitude is compared using

```math
20\log_{10}\left|\frac{X}{U}\right|,
```

and the measured phase is compared with $\arg H(j\omega)$. The script
`run_frequency_sweep.m` repeats this process over

```matlab
omega_values = logspace(-1, 1, 20);
```

and plots analytical curves together with the Simulink measurement points.
For `k = 1.2` and `r = 0.2`, the response shows:

- low-frequency behavior close to the static gain $1/k$;
- a resonance peak near

  ```math
  \omega_n=\sqrt{k}\approx1.095\ \mathrm{rad/s};
  ```

- a high-frequency roll-off approaching $-40\ \mathrm{dB/decade}$;
- a phase transition from approximately $0^{\circ}$ to $-180^{\circ}$.

The close overlap between the analytical curve and the measured Simulink
points is a cross-validation result: the Bode-style response is reconstructed
from time-domain simulations rather than drawn only from the analytical
formula.

The learning progression in this folder is therefore:

```text
manual oscillator
    -> sinusoidal excitation
    -> single-frequency resonance
    -> automated frequency sweep
    -> Bode-style characterization
    -> analytical validation
```

### 5. Damping ratio and quality factor

The normalized equation can be written in standard second-order form:

```math
\ddot{x}+2\zeta\omega_n\dot{x}+\omega_n^2x=u(t).
```

Comparing coefficients gives

```math
\omega_n=\sqrt{k},
\qquad
\zeta=\frac{r}{2\sqrt{k}}.
```

For a lightly damped resonator,

```math
Q\approx\frac{1}{2\zeta}=\frac{\sqrt{k}}{r}.
```

With `k = 1.2` and `r = 0.2`,

```math
\zeta\approx0.091,
\qquad
Q\approx5.5.
```

A higher $Q$ means that the resonator stores energy for more cycles, produces
a taller and narrower resonance peak, and is more frequency-selective. Higher
damping reduces the peak and broadens the useful response range.

A useful follow-up experiment is to keep the excitation near resonance:

```matlab
omega = 1.1;
k = 1.2;
```

and compare

```matlab
r = 0.2;
r = 0.5;
r = 1.0;
r = 2.0;
```

The Scope should show a progressively smaller resonant amplitude as $r$
increases.

## How these models relate to the main project

The legacy models and the main models serve different purposes:

| Legacy manual models | Main portfolio workflow |
|---|---|
| Gain + Sum + Integrator blocks | State-Space block and reusable functions |
| Scope and XY Graph inspection | Automated result generation |
| Manually changed parameters | Shared `init_params.m` configuration |
| Visual learning experiments | MATLAB/Simulink cross-validation |
| Step-by-step resonance intuition | Python/SciPy reference and CI tests |

The progression is:

1. map differential equations to individual Simulink blocks;
2. observe time-domain and phase-space behavior;
3. add external excitation;
4. test sinusoidal response and resonance;
5. automate the frequency sweep and compare measured and analytical response;
6. connect resonance to damping ratio, bandwidth, and $Q$;
7. reorganize the validated model into an automated, multi-tool workflow.

For the current analytical derivation and generated frequency-response figure,
see [the main methods document](../METHODS.md). The legacy models are learning
artifacts, not a second production implementation of the main sensor model.
