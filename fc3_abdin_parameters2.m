%% fc3_abdin_parameters.m
% Initialization script for merged PEMFC model (fc3_abdin.slx)
% Combines Abdin et al. (2016) PEMFC electrochemical parameters with
% Simscape Moist Air hydrogen transport system (Tank -> PRV -> Anode).

clearvars -except do_not_clear; clc;

%% 1. Fundamental Constants & Abdin PEMFC Parameters (Abdin et al. 2016)
% Calibrated for Horizon H-500XP (30-cell PEMFC stack, User Manual specs)
FC_param.R    = 8.3144;      % Universal gas constant [J/(mol*K)]
FC_param.F    = 96485;       % Faraday constant [C/mol]
FC_param.Tref = 298.15;      % Reference temperature [K] (25 degC)
FC_param.Pref = 1.0;         % Reference pressure [atm]
FC_param.E0rev= 1.116;       % Calibrated standard reversible potential yielding 28.80 V OCV across 30 cells
FC_param.dEdT = -0.9e-3;     % Temperature coefficient of reversible voltage [V/K]

% Molar Masses [g/mol]
FC_param.MH2  = 2.016;
FC_param.MO2  = 32.00;
FC_param.MH2O = 18.015;

% Fixed Model Parameters
FC_param.A         = 55.00;        %Active area of MEA [cm^2]
FC_param.del_mem   = 0.0050;       % Membrane thickness (40 um, modern reinforced MEA of H-500XP) [cm]
FC_param.del_el    = 0.008;        % Electrode thickness [cm]
FC_param.dG_an     = 29e3;         % Activation energy anode [J/mol]
FC_param.dG_cat    = 66e3;         % Activation energy cathode [J/mol]
FC_param.SH2       = 1.05;         % Hydrogen stoichiometry ratio for dead-ended anode with periodic purge [-]
FC_param.SO2       = 2.0;          % Oxygen stoichiometry ratio [-]
FC_param.rhoH2O    = 1.0;          % Density of liquid water [g/cm^3]
FC_param.Dw        = 1.28e-6;      % Water diffusion coefficient in membrane [cm^2/s]
FC_param.eps_por   = 0.3;          % Electrode porosity [-]
FC_param.xi_tort   = 4.0;          % Electrode tortuosity [-]

% Fitted Model Parameters
p1 = 1.0e-3;                       % Reference exchange current density anode i0_an_ref [A/cm^2]
p2 = 1.0e-7;                       % Reference exchange current density cathode i0_cat_ref [A/cm^2]
p3 = 0.7;                          % Anode charge transfer coefficient alpha_an [-]
p4 = 1.7;                          % Cathode charge transfer coefficient alpha_cat [-]
FC_param.gamma_M   = 47.0;         % Surface roughness factor [-]

% Stack Sizing
FC_param.Ncell     = 30;           % Number of cells in stack (from H-500XP manual)

% Default Operating Conditions
FC_param.T         = 328.15;       % Operating temperature [K] (55 degC nominal, max 65 degC in manual)
FC_param.Pan_nom   = 1.493;        % Nominal anode pressure [atm] (0.5 bar gauge / 1.513 bar abs, H-500XP manual)
FC_param.Pcat      = 1.493;        % Cathode pressure [atm]
FC_param.phi_an    = 0.30;         % Anode relative humidity (0 to 1)
FC_param.phi_cat   = 0.30;         % Cathode relative humidity (0 to 1)

% Effective Diffusion Coefficients
s_H2  = 2.827; s_O2 = 3.467; s_H2O = 2.641;
s_H2_H2O = (s_H2 + s_H2O)/2;
s_O2_H2O = (s_O2 + s_H2O)/2;
eps_k_H2 = 59.7; eps_k_O2 = 106.7; eps_k_H2O = 809.1;
eps_H2_H2O = sqrt(eps_k_H2 * eps_k_H2O);
eps_O2_H2O = sqrt(eps_k_O2 * eps_k_H2O);
T_star_H2 = FC_param.T / eps_H2_H2O;
T_star_O2 = FC_param.T / eps_O2_H2O;

omega_D = @(t) 1.06./(t.^0.156) + 0.193./exp(0.476*t) + 1.036./exp(1.53*t) + 1.765./(3.894*t);
UD_H2 = omega_D(T_star_H2);
UD_O2 = omega_D(T_star_O2);

D_H2_H2O = 0.00133 * ((1/FC_param.MH2 + 1/FC_param.MH2O)^0.5) * (FC_param.T^1.5) / (1.0 * s_H2_H2O^2 * UD_H2);
D_O2_H2O = 0.00133 * ((1/FC_param.MO2 + 1/FC_param.MH2O)^0.5) * (FC_param.T^1.5) / (FC_param.Pcat * s_O2_H2O^2 * UD_O2);

r_pore = 1.0e-4; % [cm] pore radius
D_Knudsen = (4/3) * r_pore * sqrt(8 * FC_param.R * 1e7 * FC_param.T / (pi * FC_param.MH2O));

por_tort = FC_param.eps_por / FC_param.xi_tort;
FC_param.Deff_an  = por_tort / (1/D_H2_H2O + 1/D_Knudsen);
FC_param.Deff_cat = por_tort / (1/D_O2_H2O + 1/D_Knudsen);

%% 2. Hydrogen Transport & Storage System (Simscape Moist Air Domain)
% Gas Species Property Tables: Hydrogen (H2)
H2_R = 4124.48151675695; % [J/(kg*K)] Specific gas constant
H2_T = [-56.55, -50:10:-10, -5:1:5, 10:10:350]; % [degC]
H2_h = [2783.66, 2873.94, 3012.63, 3152.23, 3292.62, 3433.72, 3504.50, 3518.68, 3532.85, 3547.04, 3561.23, 3575.42, 3589.62, 3603.83, 3618.04, 3632.25, 3646.47, 3717.65, 3860.32, 4003.38, 4146.77, 4290.44, 4434.35, 4578.46, 4722.74, 4867.16, 5011.69, 5156.32, 5301.04, 5445.82, 5590.66, 5735.55, 5880.47, 6025.44, 6170.43, 6315.45, 6460.50, 6605.57, 6750.67, 6895.80, 7040.95, 7186.13, 7331.34, 7476.58, 7621.86, 7767.17, 7912.52, 8057.91, 8203.35, 8348.83, 8494.37, 8639.96]; % [kJ/kg]
H2_mu = [7.13, 7.28, 7.51, 7.73, 7.95, 8.16, 8.27, 8.29, 8.31, 8.33, 8.36, 8.38, 8.40, 8.42, 8.44, 8.46, 8.48, 8.59, 8.80, 9.00, 9.21, 9.41, 9.61, 9.81, 10.01, 10.20, 10.40, 10.59, 10.78, 10.97, 11.16, 11.34, 11.53, 11.71, 11.90, 12.08, 12.26, 12.44, 12.62, 12.79, 12.97, 13.15, 13.32, 13.50, 13.67, 13.84, 14.01, 14.18, 14.35, 14.52, 14.69, 14.86]; % [uPa*s]
H2_k = [142.83, 146.60, 152.24, 157.73, 163.10, 168.34, 170.91, 171.43, 171.94, 172.45, 172.96, 173.46, 173.97, 174.47, 174.98, 175.48, 175.98, 178.48, 183.39, 188.21, 192.93, 197.58, 202.15, 206.65, 211.08, 215.45, 219.76, 224.02, 228.24, 232.40, 236.53, 240.62, 244.67, 248.69, 252.68, 256.64, 260.58, 264.49, 268.38, 272.25, 276.11, 279.95, 283.77, 287.58, 291.37, 295.16, 298.94, 302.71, 306.47, 310.22, 313.97, 317.72]; % [mW/(m*K)]
H2_D = 74; % [mm^2/s] Diffusivity

% Gas Species Property Tables: Nitrogen (Carrier Gas / Atmospheric Model)
N2_R = 296.804913752699;
N2_T = [-56.55, -50:10:-10, -5:1:5, 10:10:350];
N2_h = [224.31, 231.14, 241.56, 251.98, 262.40, 272.82, 278.03, 279.07, 280.11, 281.15, 282.19, 283.23, 284.27, 285.32, 286.36, 287.40, 288.44, 293.65, 304.06, 314.47, 324.89, 335.30, 345.72, 356.14, 366.56, 376.99, 387.42, 397.85, 408.30, 418.74, 429.20, 439.66, 450.14, 460.62, 471.12, 481.62, 492.14, 502.67, 513.22, 523.78, 534.36, 544.95, 555.56, 566.19, 576.84, 587.50, 598.19, 608.90, 619.62, 630.37, 641.14, 651.93];
N2_mu = [13.79, 14.14, 14.65, 15.16, 15.66, 16.15, 16.39, 16.44, 16.48, 16.53, 16.58, 16.63, 16.68, 16.72, 16.77, 16.82, 16.87, 17.10, 17.57, 18.03, 18.49, 18.94, 19.38, 19.82, 20.25, 20.68, 21.10, 21.52, 21.93, 22.34, 22.74, 23.14, 23.53, 23.92, 24.31, 24.69, 25.07, 25.44, 25.81, 26.18, 26.54, 26.90, 27.26, 27.62, 27.97, 28.32, 28.66, 29.00, 29.35, 29.68, 30.02, 30.35];
N2_k = [19.63, 20.15, 20.94, 21.72, 22.49, 23.25, 23.63, 23.70, 23.78, 23.85, 23.93, 24.00, 24.08, 24.15, 24.22, 24.30, 24.37, 24.74, 25.47, 26.20, 26.91, 27.62, 28.32, 29.01, 29.69, 30.37, 31.04, 31.70, 32.36, 33.01, 33.66, 34.30, 34.93, 35.56, 36.18, 36.80, 37.42, 38.03, 38.63, 39.23, 39.83, 40.42, 41.01, 41.59, 42.17, 42.75, 43.32, 43.89, 44.46, 45.02, 45.58, 46.13];

% Tank & Pipeline Sizing
tank_p       = 103.5;   % [bar] High-pressure fuel tank storage pressure
tank_yH2     = 0.9999;  % [-] High purity H2
tank_V       = 8.5;    % [l] Tank volume
anode_tube_D = 0.01;    % [m] Diameter of connection pipe (10 mm)

% Atmospheric & Ambient Conditions
env_p        = 0.101325;% [MPa] Ambient atmospheric pressure (1 atm)
env_T        = 20;      % [degC] Ambient temperature
env_RH       = 0.50;    % [-] Relative humidity
env_yO2      = 0.21;    % [-] Oxygen fraction in air

% Pressure-Reducing Valve (PRV) Target
% Setpoint: 0.5 bar gauge (0.05 MPa gauge) -> absolute setpoint = env_p + 0.05 MPa = 0.151325 MPa (1.513 bar abs)
Stack_Pressure = 0.05;  % [MPa] 0.5 bar relative gauge setpoint

%% 3. Simulation & Experimental Reference Data
    data = readmatrix('test.xlsx');
    i_exp = data(:, 1);
    v_stack_exp = data(:, 2);
    p_stack_exp = data(:, 3);
    Tsim = size(data, 1);            % [s] Total simulation duration
    vector_time = linspace(0, Tsim, length(i_exp));
    i = i_exp';

fprintf('All parameters for merged model fc3_abdin initialized successfully.\n');