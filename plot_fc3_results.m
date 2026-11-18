%% plot_fc3_results.m
% Plotting script for PEMFC model (fc3_abdin.slx)
% Generates:
%   1. Figure 1: Stack Voltage & Electrical Power vs. Current (I-V & P-I Characteristics)
%                - Solid Blue  : Simulated Stack Voltage [V]
%                - Dashed Blue : Experimental Stack Voltage [V]
%                - Solid Red   : Simulated Stack Power [W]
%                - Dashed Red  : Experimental Stack Power [W]
%   2. Figure 2: Stack Voltage & Electrical Power vs. Time
%   3. Figure 3: Hydrogen Supply & Tank Dynamics:
%                - Fuel tank pressure drop [mbar] & tank pressure [bar]
%                - Cumulative hydrogen mass consumed from tank [g]
%                - Volumetric hydrogen flow rate at fuel cell inlet [LPM]

%% 3. Extract Simulation Data
% 3.1 Time, Current, Voltage, and Power
t_sim   = out.tout;
I_sim   = out.sim_I;
V_sim   = out.sim_Vstack; % [V]
P_sim   = out.sim_Pstack; % [W]

% Time vector mapping for experimental data (aligned with profile duration)
t_exp   = linspace(0, t_sim(end), length(i_exp_raw))';

% 3.2 Fuel Tank Pressure and Pressure Drop
t_tank           = out.simlog.Fuel_Tank.p_I.series.time;
p_tank_bar       = out.simlog.Fuel_Tank.p_I.series.values('bar');      % [bar]
p_tank_drop_bar  = p_tank_bar(1) - p_tank_bar;                         % [bar]
p_tank_drop_mbar = p_tank_drop_bar * 1000;                             % [mbar]

% 3.3 Cumulative Hydrogen Mass Consumed from Tank
V_tank_m3        = 120 * 1e-3; % [m^3] (120 L tank)
rho_tank         = out.simlog.Fuel_Tank.rho_I.series.values('kg/m^3');
m_tank_g         = V_tank_m3 * rho_tank * 1000;                        % [g]
H2_consumed_g    = m_tank_g(1) - m_tank_g;                             % [g]

% 3.4 Hydrogen Flow Rate into Fuel Cell Inlet (LPM)
if isprop(out.simlog, 'Flow_Rate_Sensor_MA1')
    t_flow   = out.simlog.Flow_Rate_Sensor_MA1.V.series.time;
    flow_lpm = out.simlog.Flow_Rate_Sensor_MA1.V.series.values('lpm');
else
    t_flow   = out.simlog.Pipe_MA.mdot_B.series.time;
    mdot_B   = out.simlog.Pipe_MA.mdot_B.series.values('kg/s');
    rho_pipe = out.simlog.Pipe_MA.rho_I.series.values('kg/m^3');
    flow_lpm = (-mdot_B ./ rho_pipe) * 1000 * 60;
end

%% 4. Display Key Numerical Summary in Command Window
fprintf('\n================== SIMULATION SUMMARY ==================\n');
fprintf('Simulation Time         : %.1f s\n', t_sim(end));
fprintf('Current Range           : %.2f A to %.2f A\n', min(I_sim), max(I_sim));
fprintf('Final Stack Voltage     : %.2f V\n', V_sim(end));
fprintf('Final Stack Power       : %.2f W\n', P_sim(end));
fprintf('Initial Tank Pressure   : %.2f bar\n', p_tank_bar(1));
fprintf('Final Tank Pressure     : %.4f bar\n', p_tank_bar(end));
fprintf('Total Tank Pressure Drop: %.4f bar (%.2f mbar)\n', p_tank_drop_bar(end), p_tank_drop_mbar(end));
fprintf('Total H2 Consumed       : %.4f g (%.6f kg)\n', H2_consumed_g(end), H2_consumed_g(end)/1000);
fprintf('Peak H2 Flow at Inlet   : %.4f LPM\n', max(flow_lpm));
fprintf('========================================================\n\n');

%% Color Definitions
c_blue = [0.000, 0.447, 0.741]; % Voltage (Blue)
c_red  = [0.850, 0.325, 0.098]; % Power   (Red)

%% 5. Figure 1: I-V and P-I Characteristics vs. Current [A]
f1 = figure('Name', 'Fuel Cell Stack I-V and P-I Characteristics', ...
            'Color', 'w', 'Position', [100, 150, 780, 500]);

% Left Y-Axis: Voltage (Solid Blue for Sim, Dashed Blue for Exp)
yyaxis left
hV_sim = plot(I_sim, V_sim, 'Color', c_blue, 'LineStyle', '-', 'LineWidth', 2.0); hold on;
hV_exp = plot(i_exp_raw, v_stack_exp, 'Color', c_blue, 'LineStyle', '--', 'LineWidth', 2.0);
ylabel('Stack Voltage [V]', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.YColor = c_blue;
grid on;

% Right Y-Axis: Power (Solid Red for Sim, Dashed Red for Exp)
yyaxis right
hP_sim = plot(I_sim, P_sim, 'Color', c_red, 'LineStyle', '-', 'LineWidth', 2.0); hold on;
hP_exp = plot(i_exp_raw, p_stack_exp, 'Color', c_red, 'LineStyle', '--', 'LineWidth', 2.0);
ylabel('Stack Electrical Power [W]', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.YColor = c_red;

xlabel('Current [A]', 'FontSize', 12, 'FontWeight', 'bold');
title('Fuel Cell Stack Polarization & Power Characteristics (I-V & P-I)', ...
      'FontSize', 13, 'FontWeight', 'bold');
legend([hV_sim, hV_exp, hP_sim, hP_exp], ...
       {'Simulated Voltage', 'Experimental Voltage', ...
        'Simulated Power',   'Experimental Power'}, ...
       'Location', 'best', 'FontSize', 10);

%% 6. Figure 2: Stack Voltage and Power vs. Time [s]
f2 = figure('Name', 'Fuel Cell Stack Voltage and Power vs Time', ...
            'Color', 'w', 'Position', [150, 100, 780, 500]);

yyaxis left
hVt_sim = plot(t_sim, V_sim, 'Color', c_blue, 'LineStyle', '-', 'LineWidth', 2.0); hold on;
hVt_exp = plot(t_exp, v_stack_exp, 'Color', c_blue, 'LineStyle', '--', 'LineWidth', 2.0);
ylabel('Stack Voltage [V]', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.YColor = c_blue;
grid on;

yyaxis right
hPt_sim = plot(t_sim, P_sim, 'Color', c_red, 'LineStyle', '-', 'LineWidth', 2.0); hold on;
hPt_exp = plot(t_exp, p_stack_exp, 'Color', c_red, 'LineStyle', '--', 'LineWidth', 2.0);
ylabel('Stack Electrical Power [W]', 'FontSize', 12, 'FontWeight', 'bold');
ax = gca;
ax.YColor = c_red;

xlabel('Time [s]', 'FontSize', 12, 'FontWeight', 'bold');
title('Fuel Cell Stack Voltage and Electrical Power vs. Time', ...
      'FontSize', 13, 'FontWeight', 'bold');
legend([hVt_sim, hVt_exp, hPt_sim, hPt_exp], ...
       {'Simulated Voltage', 'Experimental Voltage', ...
        'Simulated Power',   'Experimental Power'}, ...
       'Location', 'best', 'FontSize', 10);

%% 7. Figure 3: Hydrogen Supply & Tank Dynamics (3 Subplots)
f3 = figure('Name', 'Hydrogen Supply & Storage Dynamics', ...
            'Color', 'w', 'Position', [700, 100, 750, 650]);

% Subplot 1: Fuel Tank Pressure Drop
subplot(3, 1, 1);
plot(t_tank, p_tank_drop_mbar, 'LineWidth', 2, 'Color', '#7E2F8E');
grid on;
title('Fuel Tank Pressure Drop (\DeltaP_{tank})', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time [s]', 'FontSize', 10);
ylabel('\DeltaP [mbar]', 'FontSize', 10, 'FontWeight', 'bold');

% Subplot 2: Cumulative Hydrogen Consumed
subplot(3, 1, 2);
plot(t_tank, H2_consumed_g, 'LineWidth', 2, 'Color', '#77AC30');
grid on;
title('Cumulative Hydrogen Consumed from Tank', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time [s]', 'FontSize', 10);
ylabel('H_2 Consumed [g]', 'FontSize', 10, 'FontWeight', 'bold');

% Subplot 3: Hydrogen Flow Rate at Fuel Cell Inlet
subplot(3, 1, 3);
plot(t_flow, flow_lpm, 'LineWidth', 2, 'Color', '#A2142F');
grid on;
title('Hydrogen Flow Rate into Fuel Cell Inlet', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time [s]', 'FontSize', 10);
ylabel('Flow Rate [LPM]', 'FontSize', 10, 'FontWeight', 'bold');
