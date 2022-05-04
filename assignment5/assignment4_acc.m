
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
M_pos = dataFromFile{2}; M_vel = dataFromFile{3}; M_acc = dataFromFile{4}; 

time(1:292) = []; %cut samples until something happens (0.3s)
M_pos(1:292) = []; M_vel(1:292) = []; M_acc(1:292) = [];


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

%% Kalman Smoother
%Set the R and Q parameters
R = var(M_pos); %according to the theory, we keep it constant
Q = 10;
[smoother_pos, smoother_vel, smoother_acc] = kalmanSmoother(A,B,C,M_pos,R,Q,x_0,P_0);

%% Show the measured acceleration against the estimated one
%Measured velocity - Kalman Filter velocity
figure; plot(time, M_acc); hold on; plot(time, smoother_acc); 
xlabel('Time [s]'); ylabel('Acceleration [rad/s^2]'); title("Kalman Smoother acceleration estimation");
legend('Input voltage', 'Estimated acceleration');






