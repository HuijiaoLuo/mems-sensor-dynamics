#include <fstream>
#include <iomanip>
#include <iostream>

#include "sensor_codegen_discrete.h"

int main()
{
    sensor_codegen_discrete model;
    model.initialize();

    const double Ts = 0.005;
    const double Tsim = 12.0;

    const int num_steps =
        static_cast<int>(Tsim / Ts);

    std::ofstream file("cpp/cpp_runtime.csv");

    if (!file.is_open())
    {
        std::cerr << "Could not open output CSV.\n";
        return 1;
    }

    file << "time,x,y\n";
    file << std::setprecision(17);

    for (int k = 0; k <= num_steps; ++k)
    {
        model.step();

        const auto& output =
            model.getExternalOutputs();

        const double t = k * Ts;

        file
            << t << ','
            << output.x << ','
            << output.y << '\n';
    }

    file.close();

    sensor_codegen_discrete::terminate();

    std::cout
        << "Wrote C++ trajectory to cpp/cpp_runtime.csv\n";

    return 0;
}