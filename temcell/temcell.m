close all
clear
clc

% Resolution 1mm
res = 1
unit = 1e-6
mul = 1e3
physical_constants;



FDTD = InitFDTD( 'NrTs', 500000,'EndCriteria', 1e-9, 'TimeStepFactor',0.95);
CSX = InitCSX();

f0 = 200e6; % center frequency
fc = 50e6;
FDTD = SetGaussExcite( FDTD, f0, fc );
%FDTD = SetSinusExcite( FDTD, f0);
BC   = {'MUR' 'MUR' 'MUR' 'MUR' 'MUR' 'MUR'};
FDTD = SetBoundaryCond( FDTD, BC );



lambda_min = c0/f0/20/unit

%mesh.x = SmoothMeshLines2(mul *[250 500 510 520 800], c0/500e6/20/unit/15);
%mesh.x = [ -mesh.x mesh.x ]; 
%mesh.x = AutoSmoothMeshLines( mesh.x, lambda_min);

%mesh.y = [0.75 14 15.2 148.9 400];
%mesh.y =  mul * [ -mesh.y mesh.y ]; 
%mesh.y = AutoSmoothMeshLines( mesh.y, lambda_min/10);

%mesh.z = [26 180 250 500];
%mesh.z = mul * [-mesh.z 0 mesh.z]; 
%mesh.z = AutoSmoothMeshLines( mesh.z, lambda_min/5);

mesh.x = SmoothMeshLines2(mul *[250.185716 258.501231 266.816746 275.132261 283.447777 291.763292 300.078807 308.394322 316.709837 325.025352 333.340867 341.656383 349.971898 358.287413 366.602928 374.918443 383.233958 391.549473 399.864988 408.180504 416.496019 424.811534 433.127049 441.442564 449.758079 458.073594 466.389110 474.704625 483.020140 491.335655 499.651170 510 520 800], c0/500e6/20/unit);
mesh.x = [ -mesh.x mesh.x ]; 
mesh.x = AutoSmoothMeshLines( mesh.x, lambda_min);

mesh.y = [0.75 17.1 17.957235 22.429723 26.902211 31.374700 35.847188 40.319676 44.792164 49.264653 53.737141 58.209629 62.682117 67.154605 71.627094 76.099582 80.572070 85.044558 89.517047 93.989535 98.462023 102.934511 107.407000 111.879488 116.351976 120.824464 125.296953 129.769441 134.241929 138.714417 143.186906 147.659394 151 151.9 152.9 500];
mesh.y =  mul * [ -mesh.y mesh.y ]; 
mesh.y = AutoSmoothMeshLines( mesh.y, lambda_min);

mesh.z = [26.420457 33.915061 41.409665 48.904269 56.398873 63.893477 71.388081 78.882685 86.377289 93.871893 101.366497 108.861101 116.355705 123.850309 131.344913 138.839517 146.334121 153.828725 161.323329 168.817933 176.312537 180 183.807141 191.301745 198.796350 206.290954 213.785558 221.280162 228.774766 236.269370 243.763974 250 251.258578 500];
mesh.z = mul * [-mesh.z 0 mesh.z]; 
mesh.z = AutoSmoothMeshLines( mesh.z, lambda_min);











CSX = DefineRectGrid(CSX, unit, mesh);
start = mul*[510 14 26];
stop  = mul*[520 -0.75 -26];


%% Add air
start = mul*[-800 -500 -500]
stop  = mul*[800 500 500]
CSX = AddMaterial(CSX,'air');
CSX = SetMaterialProperty(CSX,'air','Epsilon',1.0,'Mue',1.0);
CSX = AddBox( CSX, 'air', 0, start, stop );


%% add a nf2ff calc box
start = mul*[-527 -30 -190]
stop  = mul*[527 30 190]
[CSX nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start, stop);




CSX = AddMetal( CSX, 'gnd' ); % create a perfect electric conductor (PEC)
CSX = ImportSTL(CSX, 'gnd', 10, '/home/florian/cad/TEMCell/TemHull2.stl' , 'Transform',{'Scale',mul});

CSX = AddMetal( CSX, 'PEC' );
CSX = ImportSTL(CSX, 'PEC', 10, '/home/florian/cad/TEMCell/Septum.stl' , 'Transform',{'Scale',mul});


CSX = AddDump(CSX,'Et');
CSX = AddBox(CSX,'Et',0,[-10 100 -10],[10 50 10]);


start = mul*[510 17.1 26];
stop  = mul*[520 0.75 -26];
[CSX port] = AddLumpedPort(CSX, 5 ,1 , 50, start, stop, [0 100 0], true, 'ExcitePort', 'excite', 'Caps', 1);




start = mul*[500 14 26];
stop  = mul*[526.25 -14 -26];
%CSX = AddLorentzMaterial(CSX,'FR4');


e0=8.85418e-12;
tan_d=0.5;
freq= 2e9;
kappa= e0*4.1*tan_d*freq;
%CSX = SetMaterialProperty( CSX, 'FR4', 'Epsilon', 4.1, 'Mue', 1, 'kappa',kappa );
%CSX = AddBox( CSX, 'FR4', 2, start, stop );

start = mul*[-500 14 26];
stop  = mul*[-526.25 -14 -26];
%CSX = AddBox( CSX, 'FR4', 2, start, stop );

%termination
%start = mul*[510 -0.75 26];
%stop  = mul*[520 -14 -26];
%CSX = AddLumpedElement( CSX, 'ResistorExp', 1, 'Caps', 1, 'R', 100);
%CSX = AddBox( CSX, 'ResistorExp', 1, start, stop );


%termination
start = mul*[-510 17.1 26];
stop  = mul*[-520 0.75 -26];
CSX = AddLumpedElement( CSX, 'Resistor1', 1, 'Caps', 1, 'R', 50);
CSX = AddBox( CSX, 'Resistor1', 1, start, stop );

%termination
start = mul*[-510 -0.75 26];
stop  = mul*[-520 -14 -26];
%CSX = AddLumpedElement( CSX, 'Resistor2', 1, 'Caps', 1, 'R', 100);
%CSX = AddBox( CSX, 'Resistor2', 1, start, stop );








[status, message, messageid] = rmdir( 'tmp', 's' ); % clear previous directory
[status, message, messageid] = mkdir( 'tmp' ); % create empty simulation folder


WriteOpenEMS('tmp/tmp.xml',FDTD,CSX);

CSXGeomPlot( 'tmp/tmp.xml' );

RunOpenEMS( 'tmp', 'tmp.xml','--debug-PEC');





%% postprocessing & make the plots
freq = linspace(f0-fc, f0+fc, 501 );
port = calcPort(port, 'tmp', freq);

s11 = port.uf.ref./port.uf.inc;
Zin = port.uf.tot./port.if.tot;

Pin_f0 = interp1(freq, port.P_acc, f0);

%%
% plot feed point impedance
figure
plot( freq/1e6, real(Zin), 'k-', 'Linewidth', 2 );
hold on
grid on
plot( freq/1e6, imag(Zin), 'r--', 'Linewidth', 2 );
title( 'feed point impedance' );
xlabel( 'frequency f / MHz' );
ylabel( 'impedance Z_{in} / Ohm' );
legend( 'real', 'imag' );


% plot reflection coefficient S11
figure
plot( freq/1e6, 20*log10(abs(s11)), 'k-', 'Linewidth', 2 );
grid on
title( 'reflection coefficient' );
xlabel( 'frequency f / MHz' );
ylabel( 'S_{11} (dB)' );


% calculate the far field at theta=90 degrees
% calculate 3D pattern
phiRange = 0:15:360;
thetaRange = 0:10:180;
r = 1; % evaluate fields at radius r
disp( 'calculating 3D far field...' );
nf2ff = CalcNF2FF(nf2ff, 'tmp', f0, thetaRange*pi/180, phiRange*pi/180, 'Outfile', '3D_Sweep.h5');

E_far_normalized = nf2ff.E_norm{1};% / max(nf2ff.E_norm{1}(:));
[theta,phi] = ndgrid(thetaRange/180*pi,phiRange/180*pi);
x = E_far_normalized .* sin(theta) .* cos(phi);
y = E_far_normalized .* sin(theta) .* sin(phi);
z = E_far_normalized .* cos(theta);
plot(y);


figure
surf( x,y,z, E_far_normalized );
axis equal
xlabel( 'x' );
ylabel( 'y' );
zlabel( 'z' );

