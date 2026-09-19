# Open-source implementation roadmap

The first open-source layer is the Python/SciPy reference implementation in the python/ directory. It expresses the same normalized equations as MATLAB and Simulink and is tested automatically by GitHub Actions. The canonical environment is the Conda environment described by environment.yml.

The next optional layer is OpenModelica:

1. Add a Modelica class for the mass-spring-damper equations.
2. Add a step-response experiment with the same parameters, initial conditions, and time interval.
3. Export displacement and velocity to a machine-readable file.
4. Compare those signals against the Python reference in CI.

OpenModelica is deliberately not included as an unverified model yet. Once added, it should become an additional implementation of the same physical model rather than a separate project.

The intended long-term comparison is:

~~~text
MATLAB / Simulink
        \
         \      same parameters and input
          > Python reference and physics tests
         /
OpenModelica
~~~

Python is the license-free CI backbone. MATLAB/Simulink remains the industrial model-based implementation, while OpenModelica can later demonstrate open-source equation-based physical modelling.
