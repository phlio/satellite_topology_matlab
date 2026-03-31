function [sunUnitVector, alignedSunVectorTime] = calculate_sun_to_earth_unit_vector(sunVectorData, sunVectorTime, satelliteData)
% 计算太阳到地心的单位矢量
% 输入:
%   sunVectorData - 太阳到卫星sat101的矢量 
%   sunVectorTime - 对应的时间向量 
%   satelliteData - 卫星数据结构体
% 输出:
%   sunUnitVector - 太阳到地心的单位矢量 
%   alignedSunVectorTime - 对齐后的时间向量 

% 获取sat101的坐标数据
if isfield(satelliteData, 'Sat101')
    sat101_x = satelliteData.Sat101.x;
    sat101_y = satelliteData.Sat101.y;
    sat101_z = satelliteData.Sat101.z;
    
    % 确保时间点数量匹配
    num_sun_points = size(sunVectorData, 1);
    num_sat_points = length(sat101_x);
    
    if num_sun_points ~= num_sat_points
        fprintf('警告: 太阳矢量数据点数(%d)与卫星位置数据点数(%d)不匹配\n', num_sun_points, num_sat_points);
        % 使用较小的数据点数
        min_points = min(num_sun_points, num_sat_points);
        sunVectorData = sunVectorData(1:min_points, :);
        sat101_x = sat101_x(1:min_points);
        sat101_y = sat101_y(1:min_points);
        sat101_z = sat101_z(1:min_points);
        alignedSunVectorTime = sunVectorTime(1:min_points);
    else
        alignedSunVectorTime = sunVectorTime;
    end
    
    % 卫星位置矢量 (地心到卫星)
    satellitePosition = [sat101_x, sat101_y, sat101_z];
    
    % 太阳到地心矢量 = 太阳到卫星矢量 + 卫星到地心矢量
    sunToEarthCenterVector = sunVectorData + satellitePosition;
    
    % 转换为单位向量
    vectorMagnitudes = sqrt(sum(sunToEarthCenterVector.^2, 2));
    % 避免除零错误
    vectorMagnitudes(vectorMagnitudes == 0) = 1;
    sunUnitVector = sunToEarthCenterVector ./ vectorMagnitudes;
else
    error('未找到Sat101卫星数据');
end
end