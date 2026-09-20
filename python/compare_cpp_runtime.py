from pathlib import Path

import numpy as np

from discrete_sensor_model import simulate_discrete


def step_input(t: float) -> float:
    return 0.0 if t < 1.0 else 1.0


repo_root = Path(__file__).resolve().parents[1]
csv_file = repo_root / "cpp" / "cpp_runtime.csv"

cpp = np.genfromtxt(
    csv_file,
    delimiter=",",
    names=True,
)

time_py, state_py, _, _ = simulate_discrete(
    k=1.2,
    r=0.2,
    u_fun=step_input,
    sample_time=0.005,
    t_span=(0.0, 12.0),
    x0=0.0,
    y0=0.0,
)

if len(cpp["time"]) != len(time_py):
    raise RuntimeError(
        f"Length mismatch: C++={len(cpp['time'])}, Python={len(time_py)}"
    )

error_t = cpp["time"] - time_py
error_x = cpp["x"] - state_py[0, :]
error_y = cpp["y"] - state_py[1, :]

print("Generated C++ vs Python discrete reference")
print("------------------------------------------")
print(f"Samples          : {len(time_py)}")
print(f"Max time error   : {np.max(np.abs(error_t)):.17g}")
print(f"x max abs error  : {np.max(np.abs(error_x)):.17g}")
print(f"x RMS error      : {np.sqrt(np.mean(error_x**2)):.17g}")
print(f"y max abs error  : {np.max(np.abs(error_y)):.17g}")
print(f"y RMS error      : {np.sqrt(np.mean(error_y**2)):.17g}")