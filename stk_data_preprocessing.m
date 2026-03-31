%% STK Walker 星座数据预处理
clear; clc; close all;

%% 添加 src 函数路径
addpath(fullfile(pwd, 'src'));

%% 参数设置
data_dir = fullfile(pwd, 'data');
filename = fullfile(data_dir, '60location_latitude_longitude.csv');
sun_vector_filename = fullfile(data_dir, '60Satellite101_Sun_Vector_J2000.csv');
T = 60; P = 6; S = 10; U = 5;
h = 1000; Re = 6378.14; 
fov_degrees = 0.7; % 太阳辐射视场角，默认0.7度
seu_probability = 0.005; % 单粒子翻转概率，默认0.005
debris_probability = 0.002; % 空间碎片导致节点失效概率，默认0.002

fprintf('=== STK Walker星座数据预处理 ===\n');
fprintf('星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);

%% 1. 读取STK位置数据
fprintf('1. 读取STK位置数据...\n');
[satelliteData, satelliteNames] = read_stk_data_new_format(filename);
fprintf('   成功读取 %d 颗卫星的数据\n', length(satelliteNames));

%% 2. 读取太阳矢量数据
fprintf('2. 读取太阳矢量数据...\n');
[sunVectorData, sunVectorTime] = read_sun_vector_data(sun_vector_filename);
fprintf('   成功读取太阳矢量数据: %d个时间点\n', length(sunVectorTime));

%% 2.1 计算太阳到地心的单位矢量
fprintf('2.1 计算太阳到地心的单位矢量...\n');
[sunUnitVector, sunVectorTime] = calculate_sun_to_earth_unit_vector(sunVectorData, sunVectorTime, satelliteData);
fprintf('   成功计算太阳到地心单位矢量: %d个时间点\n', size(sunUnitVector, 1));

%% 3. 数据重组
fprintf('3. 数据重组与时间对齐...\n');
[time_data, sat_positions, sat_lat_lon, sat_names] = reorganize_satellite_data(satelliteData, satelliteNames, T);
num_time_points = length(time_data);
fprintf('   重组完成: %d个时间点\n', num_time_points);

%% 4. 卫星映射
fprintf('4. 建立卫星名称映射...\n');
sat_mapping = create_satellite_mapping(sat_names, P, S);

%% 5. 保存所有变量到.mat文件
fprintf('5. 保存所有预处理数据到processed_data.mat...\n');

% 直接保存所有需要的变量，不使用结构体
save('processed_data.mat', 'T', 'P', 'S', 'U', 'h', 'Re', 'fov_degrees', 'seu_probability', ...
     'debris_probability', 'time_data', 'sat_positions', ...
     'sat_lat_lon', 'sat_names', 'sat_mapping', 'sunUnitVector', 'num_time_points');

fprintf('   数据已成功保存到 processed_data.mat\n');

fprintf('\n数据预处理完成！\n');