function Colors = MapRainbow(x, y, z, ShowPlot)
% function for converting electrode locations to colors

minElevation = 0.6;
maxElevation = 0.9;

if ~exist('z', 'var') % if no z provided
    
    % Convert x and y into radius and angle
    [theta, rho] = cart2pol(x, y);
    
    % no variation for z
    elevation = (maxElevation)*ones(length(theta), 1);

else % if z provided
    
    % get spherical coordinates
    [theta,elevation,~] = cart2sph(x,y,z);
    
    % get radius relative to just xy plane, otherwise it gives gray ears
    [~, rho] = cart2pol(x, y);

    % normalize z axis and shifted so it's always a bit colored
    elevation = ((elevation - min(elevation))/(max(elevation) - min(elevation)))*(maxElevation-minElevation) + minElevation;
end

% normaize radii to be from 0 to 1, with a little offset
rho = ((rho - min(rho))/(max(rho)-min(rho)))*(1-0.1) + 0.1;

% normalize angles to be from 0 to 1
theta = wrapTo2Pi(theta);
theta = theta / (2*pi);

% convert to RGB
hsv = [theta(:), rho(:), elevation(:)];
Colors = hsv2rgb(hsv);

if exist('ShowPlot', 'var') && ShowPlot
    figure
    
    if ~exist('z', 'var')
        scatter(x, y, 100, Colors, 'filled')
    else
        hold on
        scatter3(x, y, z, 100, Colors, 'filled')
        
    end
end
end
