function pos = computeSatellitePosition(sats, t)
% 计算卫星 ECI 坐标（圆轨道）

N = length(sats);
pos = zeros(N,3);

for i = 1:N
    M = sats(i).M0 + sats(i).n * t;

    x_orb = sats(i).a * cos(M);
    y_orb = sats(i).a * sin(M);

    R3 = [ cos(sats(i).RAAN) -sin(sats(i).RAAN) 0;
           sin(sats(i).RAAN)  cos(sats(i).RAAN) 0;
           0                 0                1 ];

    R1 = [ 1 0 0;
           0 cos(sats(i).inc) -sin(sats(i).inc);
           0 sin(sats(i).inc)  cos(sats(i).inc) ];

    r = R3 * R1 * [x_orb; y_orb; 0];
    pos(i,:) = r';
end
end
