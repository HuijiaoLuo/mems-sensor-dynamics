# Legacy Manual Simulink Learning

This folder is the manual-learning trail for the project. It records how the
system was built from Gain, Sum, Integrator, signal-source, analogue
non-ideality, and ADC blocks before the main repository moved to compact
State-Space blocks, automated model generation, scripted validation, and
reproducible result generation.

The legacy models are educational artifacts. They show what each block means
physically and mathematically; they are not a second production implementation
of the main automated workflow.

## How to run the manual models

From the repository root, load the shared Base Workspace parameters first:

```matlab
run('legacy/matlab/init_manual_demo_params.m')
```

Then open the desired model and run it in Simulink. The parameter script is a
MATLAB script, not a function, because the hand-built blocks directly resolve
variables such as `k`, `r`, `alpha_x`, `G_C`, `tau_amp`, and `q_adc` from the
Base Workspace.

Useful manual switches are:

```matlab
alpha_x = alpha_x_small_signal;
alpha_x = alpha_x_nonlinear;

tau_amp = tau_amp_default;
tau_amp = tau_amp_strong_filter;
```

The sine-response models use the workspace variable `omega`, which can be
changed before each run. The parameter values are illustrative and are not
calibrated parameters of a commercial MEMS device.

## How to run the legacy MATLAB code

The `.slx` models require MATLAB with Simulink. The ordinary `.m` functions
and scripts require MATLAB; they do not require the main automated workflow.
From the repository root, prepare the MATLAB path and Base Workspace with:

```matlab
repo_root = pwd;
addpath(fullfile(repo_root, 'legacy'));
addpath(fullfile(repo_root, 'legacy', 'matlab'));
run(fullfile(repo_root, 'legacy', 'matlab', ...
    'init_manual_demo_params.m'));
```

### Run a hand-built Simulink model

Open one of the manual models and run it from the Simulink editor:

```matlab
open_system(fullfile(repo_root, 'legacy', 'sensor_step_response.slx'));
open_system(fullfile(repo_root, 'legacy', 'sensor_sine_response.slx'));
open_system(fullfile(repo_root, 'legacy', ...
    'sensor_capacitive_transduction_manual.slx'));
```

For the hand-built sine model, change the excitation frequency in the Base
Workspace before pressing Run:

```matlab
omega = 0.3;   % below resonance
omega = 1.1;   % near resonance
omega = 3.0;   % above resonance
```

The Scope and XY Graph are the primary outputs of these manual models. The
capacitive model additionally exposes the exact/linearized capacitance and the
readout stages for visual inspection.

### Run the manual differential-capacitive experiment

The manual capacitive model is run directly from the Base Workspace. Use the
following sequence from the repository root:

```matlab
run(fullfile(repo_root, 'legacy', 'matlab', ...
    'init_manual_demo_params.m'));

alpha_x = alpha_x_small_signal;

model_file = fullfile(repo_root, 'legacy', ...
    'sensor_capacitive_transduction_manual.slx');
open_system(model_file);
set_param('sensor_capacitive_transduction_manual', ...
    'StopTime', num2str(Tsim));
sim('sensor_capacitive_transduction_manual');
```

The model contains the following manually connected stages:

```text
u(t) -> mechanical dynamics -> x
     -> xi = alpha_x*x
     -> g1 = d-xi, g2 = d+xi
     -> C1, C2 -> DeltaC_exact and DeltaC_linear
     -> ideal C-to-V readout
     -> offset -> noise -> bandwidth -> saturation
     -> ADC code -> reconstructed voltage -> x_hat
```

Use the scopes and XY Graph in the model to inspect the mechanical response,
the exact and linearized differential capacitance, the analogue front-end,
the ADC reconstruction, and the final comparison between $x(t)$ and
$\widehat{x}(t)$. The model uses Scope blocks rather than exporting a
pre-generated result file, so the plots appear only after you run the model
locally.

To compare the two capacitance regimes, rerun the model with:

```matlab
alpha_x = alpha_x_small_signal;
sim('sensor_capacitive_transduction_manual');

alpha_x = alpha_x_nonlinear;
sim('sensor_capacitive_transduction_manual');
```

The small-signal setting should make $\Delta C_{\mathrm{exact}}$ and
$\Delta C_{\mathrm{linear}}$ nearly overlap. The nonlinear setting makes
their deviation easier to see. To isolate front-end effects, compare:

```matlab
tau_amp = tau_amp_default;
sim('sensor_capacitive_transduction_manual');

tau_amp = tau_amp_strong_filter;
sim('sensor_capacitive_transduction_manual');
```

The narrow default rail `V_max = 0.03` makes clipping visible. The final
reconstructed displacement can therefore underestimate a large peak: digital
calibration cannot recover information removed by analogue saturation.

### Run one frequency-response measurement

After adding the `legacy` folder to the MATLAB path and loading the shared
parameters, measure one frequency point from the hand-built
`sensor_frequency_sweep.slx` model:

```matlab
result = measure_frequency_point( ...
    'sensor_frequency_sweep', omega, k, r, Ain);
```

The returned structure contains the measured and theoretical magnitudes and
phases, simulation time, poles, and measurement errors. The helper waits for
transients to decay and fits the final five sinusoidal periods.

### Run the complete manual frequency sweep

Run the sweep script from the repository root:

```matlab
run(fullfile(repo_root, 'legacy', 'run_frequency_sweep.m'));
```

This calls `measure_frequency_point.m` for each value in
`omega_values = logspace(-1, 1, 20)`, then opens the analytical-versus-
Simulink magnitude and phase plots. The script does not fabricate or save
result images; the plots are generated only when you execute it locally.

## Manual-learning progression

### A. Hand-built second-order dynamics

Model: `sensor_step_response.slx`

This retained model is the original autonomous hand-built oscillator. Despite
its historical filename, it contains no external Step block; it documents the
unforced case $u(t)=0$.

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

### B. Step-response experiment

The next learning step is to add an external Step input to the acceleration
sum. The driven equations are

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

The original autonomous model is recovered by setting $u(t)=0$. For a
constant input $u$ at equilibrium,

```math
x_{\mathrm{ss}}=\frac{u}{k},
\qquad y_{\mathrm{ss}}=0.
```

This experiment introduces forced response, transient response, settling, and
steady-state verification. The retained `sensor_step_response.slx` file is
kept unchanged as the autonomous learning artifact; the externally driven
step-response implementation is represented by the main generated model
`../models/sensor_dynamics.slx` and the automated reference workflow.

### C. Sinusoidal excitation and resonance

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

### D. Manual frequency-sweep / Bode-style experiment

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

### Supporting analysis: damping ratio and quality factor

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

### E. Manual differential-capacitive MEMS transduction

Model: `sensor_capacitive_transduction_manual.slx`

This experiment extends normalized mechanical displacement into a simple
physical MEMS geometry. The normalized displacement is mapped to physical
proof-mass displacement with

```math
\xi=\alpha_x x.
```

The two electrode gaps are

```math
g_1=d-\xi,
\qquad
g_2=d+\xi.
```

The corresponding parallel-plate capacitances are

```math
C_1=\frac{\varepsilon A}{g_1},
\qquad
C_2=\frac{\varepsilon A}{g_2}.
```

The exact differential signal is

```math
\Delta C_{\mathrm{exact}}=C_1-C_2.
```

The geometry is valid only while

```math
|\xi|\lt d.
```

Near the centred position, the small-signal sensitivity is

```math
S_C=\frac{2\varepsilon A}{d^2},
\qquad
\Delta C_{\mathrm{linear}}=S_C\xi.
```

The manual model compares $\Delta C_{\mathrm{exact}}$ and
$\Delta C_{\mathrm{linear}}$. The shared parameter script provides two
illustrative displacement scales:

```matlab
alpha_x = alpha_x_small_signal;   % 0.2e-6 m/unit
alpha_x = alpha_x_nonlinear;      % 0.6e-6 m/unit
```

The first keeps the experiment in a relatively small-signal region. The
second intentionally makes the nonlinear deviation visible. These values are
educational choices, not parameters of a commercial MEMS device.

### F. Ideal C-to-V front end

The differential capacitance is converted into an ideal voltage using

```math
v_{\mathrm{sensor}}=G_C\Delta C.
```

The manual parameter script uses the illustrative gain

```matlab
G_C = 1e12;   % V/F
```

This is a behavioral C-to-V or charge-amplifier abstraction. It is a
system-level interface model, not a transistor-level charge-amplifier design.

### G. Analogue non-idealities

The manual front-end then adds the main analogue effects one block at a time.

1. DC offset:

   ```math
   v_{\mathrm{in}}=v_{\mathrm{sensor}}+V_{\mathrm{offset}}.
   ```

2. Additive noise:

   ```math
   v_{\mathrm{noisy}}=v_{\mathrm{in}}+n(t).
   ```

3. Finite amplifier bandwidth:

   ```math
   H_{\mathrm{amp}}(s)=\frac{1}{\tau_{\mathrm{amp}}s+1}.
   ```

4. Output-rail saturation:

   ```math
   v_{\mathrm{amp}}
   =\min\left(\max\left(v_{\mathrm{bandlimited}},V_{\mathrm{min}}\right),
   V_{\mathrm{max}}\right).
   ```

The default manual demo intentionally uses the narrow upper rail

```matlab
V_max = 0.030;   % V
```

so clipping is visually obvious. The experiments are designed to build
intuition for offset error, noise, bandwidth/noise trade-offs, phase lag,
clipping, and dynamic range.

The bandwidth switch is:

```matlab
tau_amp = tau_amp_default;
tau_amp = tau_amp_strong_filter;
```

### H. ADC quantization

The manual model uses an ideal $N$-bit ADC. Its default configuration is

```matlab
N_adc = 8;
V_adc_min = 0;
V_adc_max = 0.03;
```

The quantization step is

```math
q_{\mathrm{ADC}}
=\frac{V_{\mathrm{ADC,max}}-V_{\mathrm{ADC,min}}}{2^{N_{\mathrm{ADC}}}-1}.
```

The code and reconstructed voltage are

```math
\mathrm{code}
=\mathrm{round}\left(
\frac{v_{\mathrm{ADC}}-V_{\mathrm{ADC,min}}}{q_{\mathrm{ADC}}}
\right),
```

```math
v_{\mathrm{ADC,reconstructed}}
=\mathrm{code}\,q_{\mathrm{ADC}}+V_{\mathrm{ADC,min}}.
```

The quantization error is

```math
e_q=v_{\mathrm{ADC,clipped}}-v_{\mathrm{ADC,reconstructed}}.
```

Without analogue clipping, ideal round-to-nearest quantization keeps this
error approximately within $\pm 0.5$ LSB. Analogue clipping error and ADC
quantization error are different: once the amplifier has saturated, the ADC
cannot recover the information already lost at the analogue output.

### I. Digital calibration and end-to-end reconstruction

The manual inverse chain removes the estimated offset and maps the ADC result
back through the ideal C-to-V and capacitive sensitivities:

```math
v_{\mathrm{corrected}}
=v_{\mathrm{ADC,reconstructed}}-V_{\mathrm{offset,est}},
```

```math
\widehat{\Delta C}
=\frac{v_{\mathrm{corrected}}}{G_C},
\qquad
\widehat{\xi}=\frac{\widehat{\Delta C}}{S_C},
\qquad
\widehat{x}=\frac{\widehat{\xi}}{\alpha_x}.
```

Therefore,

```math
\widehat{x}
=\frac{v_{\mathrm{ADC,reconstructed}}-V_{\mathrm{offset,est}}}
{G_C S_C\alpha_x}.
```

The final Scope compares the true mechanical displacement $x(t)$ with the
reconstructed estimate $\widehat{x}(t)$. The difference accumulates the
effects of analogue bandwidth, startup transient, noise, saturation,
quantization, and the small-signal calibration assumption. In particular, the
first large peak can be underestimated because analogue rail saturation has
destroyed information before digital calibration begins.

### J. Learning progression summary

```text
differential equations
    -> Gain/Sum/Integrator implementation
    -> phase-space dynamics
    -> forced step response
    -> sinusoidal resonance
    -> frequency-response measurement
    -> physical MEMS displacement
    -> differential capacitance
    -> small-signal linearization
    -> capacitance-to-voltage readout
    -> analogue non-idealities
    -> ADC quantization
    -> digital calibration
    -> true-x versus reconstructed-x verification
```

## How these models relate to the main project

The legacy models and the main models serve different purposes:

| Legacy manual models | Main portfolio workflow |
|---|---|
| Gain + Sum + Integrator blocks | State-Space block and reusable functions |
| Scope and XY Graph inspection | Automated result generation |
| Manually changed parameters | Shared `init_params.m` configuration |
| Explicit capacitance, analogue, and ADC blocks | MATLAB/Python reference implementations |
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
