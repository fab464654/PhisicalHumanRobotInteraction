
% clear; 
clc; close all;

%Add needed functions
addpath("../myFunctions/")

% fileID = fopen('../master_slave_500Hz.txt');
fileID = fopen('../master_slave_1kHz.txt');
% fileID = fopen('../master_slave_2kHz.txt');

dataFromFile = textscan(fileID,'%f %f %f %f %f %f %f %f','HeaderLines',1);
fclose(fileID);

Ts = 0.001; %1kHz measurements
time  = dataFromFile{1}; 
M_pos = dataFromFile{2}; M_vel = dataFromFile{3}; M_volt = dataFromFile{4}; 

time(1:292) = []; %cut samples until something happens (0.3s)
M_pos(1:292) = []; M_vel(1:292) = []; M_volt(1:292) = [];


Euler_acc = (M_vel(2:end)-M_vel(1:end-1))./Ts;
Euler_acc = lowpass(Euler_acc, 3, 1/Ts);
Euler_acc(end+1) = Euler_acc(end);


%% Acceleration estimation
%Set the initial conditions
P_0 = diag([1e-5 1e-5 1e-5]);
x_0 = [0 0 0].';

%Set the A, B and C matrices of the dynamic system
A = [1   Ts Ts^2/2;
     0   1   Ts   ;
     0   0   1   ];
B = [Ts^3/6; Ts^2/2; Ts]; %from the theory (integrating)
C = [1 0 0];


%% Kalman Filter
%Set the R and Q parameters
R = var(M_pos); %according to the theory, we keep it constant
q = 100000;
Q = q * B * B';
[filter3_pos, filter3_vel, filter3_acc, P_inf] = kalmanFilter(A, B, C, M_pos,R, Q, x_0, P_0);

%% Steady-state Kalman Filter
% Using the solution of the Algebric Riccati Equation            
% P_inf = A*P_inf*A.' - A*P_inf*C.'*inv(C*P_inf*C.' + R)*C*P_inf*A.' + Q;

%Compute the steady-state Kalman gain
K_inf = P_inf*C.'*inv(C*P_inf*C.' + R);

[filter3SS_pos, filter3SS_vel, filter3SS_acc, ~] = kalmanFilter(A, B, C, M_pos,R, Q, x_0, P_0, K_inf);


%% Kalman Predictor
[predictor3_pos, predictor3_vel, predictor3_acc, P_inf] = kalmanPredictor(A, B, C, M_pos,R, Q, x_0, P_0);

%Compute the steady-state Kalman gain
Kbar_inf = A*P_inf*C.'*inv(C*P_inf*C.' + R);
[predictor3SS_pos, predictor3SS_vel, predictor3SS_acc, ~] = kalmanPredictor(A, B, C, M_pos,R, Q, x_0, P_0, Kbar_inf);

%% Show the measured velocities against the estimated ones
%Measured velocity - Kalman Filter velocity
figure; plot(time, M_vel); hold on; plot(time, filter3_vel); 
xlabel('Time [s]'); ylabel('Velocities [rad/s]'); title("Kalman Filter velocity estimation");
legend('Measured velocity', 'Estimated velocity');

%Measured velocity - Kalman Predictor velocity
figure; plot(time, M_vel); hold on; plot(time, predictor3_vel); 
xlabel('Time [s]'); ylabel('Velocities [rad/s]'); title("Kalman Predictor velocity estimation");
legend('Measured velocity', 'Estimated velocity');

%Measured velocity - Kalman Filter velocity - Kalman Predictor velocity
figure; plot(time, M_vel); hold on; plot(time, filter3_vel); hold on; plot(time, predictor3_vel); 
xlabel('Time [s]'); ylabel('Velocities [rad/s]'); title("Kalman Filter velocity estimation");
legend('Measured velocity', 'Estimated velocity (filter)', 'Estimated velocity (predictor)');

%Measured velocity - Kalman Filter velocity - Kalman Filter s.s. velocity
figure; plot(time, M_vel); hold on; plot(time, filter3_vel); hold on; plot(time, filter3SS_vel);
xlabel('Time [s]'); ylabel('Velocities [rad/s]'); title("Kalman Filter acceleration estimation at Steady-State");
legend('Measured velocity','Estimated velocity (filter)', 'Estimated velocity (filter at s.s.)');

%Euler acceleration - Kalman Predictor acceleration - Kalman Predictor s.s. acceleration
figure; plot(time, M_vel); hold on; plot(time, predictor3_vel); hold on; plot(time, predictor3SS_vel);
xlabel('Time [s]'); ylabel('Velocities [rad/s]'); title("Kalman Predictor acceleration estimation at Steady-State");
legend('Euler acceleration','Estimated acceleration (predictor)', 'Estimated acceleration (predictor at s.s.)');



%% Show the Euler acceleration against the estimated ones
%Euler acceleration - Kalman Filter acceleration
figure; plot(time, Euler_acc); hold on; plot(time, filter3_acc); 
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Kalman Filter acceleration estimation");
legend('Euler acceleration', 'Estimated acceleration');

%Euler acceleration - Kalman Predictor acceleration
figure; plot(time, Euler_acc); hold on; plot(time, predictor3_acc); 
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Kalman Predictor acceleration estimation");
legend('Euler acceleration', 'Estimated acceleration');

%Euler acceleration - Kalman Filter acceleration - Kalman Filter acceleration
figure; plot(time, Euler_acc); hold on; plot(time, filter3_acc); hold on; plot(time, predictor3_acc); 
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Kalman Filter acceleration estimation");
legend('Euler acceleration', 'Estimated acceleration (filter)', 'Estimated acceleration (predictor)');

%Euler acceleration - Kalman Filter acceleration - Kalman Filter s.s. acceleration
figure; plot(time, Euler_acc); hold on; plot(time, filter3_acc); hold on; plot(time, filter3SS_acc);
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Kalman Filter acceleration estimation at Steady-State");
legend('Euler acceleration','Estimated acceleration (filter)', 'Estimated acceleration (filter at s.s.)');

%Euler acceleration - Kalman Predictor acceleration - Kalman Predictor s.s. acceleration
figure; plot(time, Euler_acc); hold on; plot(time, predictor3_acc); hold on; plot(time, predictor3SS_acc);
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Kalman Predictor acceleration estimation at Steady-State");
legend('Euler acceleration','Estimated acceleration (predictor)', 'Estimated acceleration (predictor at s.s.)');



%Euler acceleration - Kalman Filter acceleration - Kalman Filter s.s. acceleration
%Kalman Predictor acceleration - Kalman Predictor s.s. acceleration
figure; plot(time, Euler_acc); hold on; plot(time, filter3_acc); hold on; plot(time, filter3SS_acc); 
hold on; plot(time, predictor3_acc); hold on; plot(time, predictor3SS_acc);
xlabel('Time [s]'); ylabel('Accelerations [rad/s^2]'); title("Comparison between all acceleration estimations");
legend('Euler acceleration','Estimated acceleration (filter)', 'Estimated acceleration (filter at s.s.)','Estimated acceleration (predictor)', 'Estimated acceleration (predictor at s.s.)');


