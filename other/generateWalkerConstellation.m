function sats = generateWalkerConstellation(T, P, F, h, inc)
% Walker Delta 星座生成

mu = 398600;
Re = 6378;
a = Re + h;
n = sqrt(mu / a^3);

idx = 1;
for p = 1:P
    for s = 1:(T / P)
        sats(idx).a    = a;
        sats(idx).inc  = deg2rad(inc);
        sats(idx).RAAN = 2*pi*(p-1)/P;
        sats(idx).M0   = 2*pi*(s-1)/(T/P) + 2*pi*F*(p-1)/T;
        sats(idx).n    = n;
        idx = idx + 1;
    end
end
end
