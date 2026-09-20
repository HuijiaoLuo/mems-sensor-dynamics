#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>

namespace
{
struct State
{
    double x;
    double y;
};

struct DiscreteModel
{
    double ad00;
    double ad01;
    double ad10;
    double ad11;
    double bd0;
    double bd1;
};

DiscreteModel make_exact_zoh_model(double k, double r, double sample_time)
{
    const double alpha = 0.5 * r;
    const double omega_d = std::sqrt(k - alpha * alpha);
    const double theta = omega_d * sample_time;
    const double decay = std::exp(-alpha * sample_time);
    const double sine = std::sin(theta);
    const double cosine = std::cos(theta);

    const double ad00 = decay * (cosine + alpha * sine / omega_d);
    const double ad01 = decay * sine / omega_d;
    const double ad10 = decay * (-k * sine / omega_d);
    const double ad11 = decay * (cosine - alpha * sine / omega_d);

    // B_d = A^{-1}(A_d - I)B for A = [0, 1; -k, -r] and B = [0; 1].
    const double bd0 = (-r * ad01 - (ad11 - 1.0)) / k;
    const double bd1 = ad01;

    return {ad00, ad01, ad10, ad11, bd0, bd1};
}

State update(const State& state, double input, const DiscreteModel& model)
{
    return {
        model.ad00 * state.x + model.ad01 * state.y + model.bd0 * input,
        model.ad10 * state.x + model.ad11 * state.y + model.bd1 * input,
    };
}
}

int main()
{
    constexpr double k = 1.2;
    constexpr double r = 0.2;
    constexpr double sample_time = 0.005;
    constexpr double final_time = 12.0;
    constexpr int sample_count =
        static_cast<int>(final_time / sample_time);

    const DiscreteModel model = make_exact_zoh_model(k, r, sample_time);
    State state{0.0, 0.0};

    std::ofstream file("cpp/cpp_runtime.csv");
    if (!file.is_open())
    {
        std::cerr << "Could not open cpp/cpp_runtime.csv.\n";
        return 1;
    }

    file << "time,x,y\n";
    file << std::setprecision(17);

    for (int index = 0; index <= sample_count; ++index)
    {
        const double time = index * sample_time;
        file << time << ',' << state.x << ',' << state.y << '\n';

        if (index < sample_count)
        {
            const double input = (time < 1.0) ? 0.0 : 1.0;
            state = update(state, input, model);
        }
    }

    if (!file.good())
    {
        std::cerr << "Failed while writing cpp/cpp_runtime.csv.\n";
        return 1;
    }

    std::cout << "Wrote " << (sample_count + 1)
              << " samples to cpp/cpp_runtime.csv\n";
    return 0;
}
