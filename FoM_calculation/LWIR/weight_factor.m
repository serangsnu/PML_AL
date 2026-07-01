function output=weight_factor(input_wave)
load("spectral_response.mat");
load("black_body.mat");
output_b = interp1(blackbody_wave, blackbody_weight, input_wave);
output_s = interp1(response_wave,response_weight, input_wave);

output = output_s .* output_b;