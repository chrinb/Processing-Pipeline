function anglePatchLegend(ax)
 
N = 360; % Number Of Colours In Colour Wheel
center_offset = 126;
th = linspace(0, 2*pi, N);              % Angles
xy = @(a,r) [r.*cos(a)+center_offset; r.*sin(a)+center_offset];     % Function: Calculate (x,y) Vectors
r_ext = 124;                            % Outer Radius
r_int = 105;                             % Inner Radius
C(1,:,:) = xy(th,r_ext);                % Outer Circle
C(2,:,:) = xy(th,r_int);                % Inner Circle
c = colormap(ax, hsv(N));                   % Set ?colormap?
hold(ax, 'on')
C1 = squeeze(C(1,:,:));                 % Reduce ?C1? Dimensions
plot(ax, C1(1,:), C1(2,:))
C2 = squeeze(C(2,:,:));                 % Reduce ?C2? Dimensions
plot(ax, C2(1,:), C2(2,:))
for k1 = 1:size(C2,2)
    %plot([C1(1,k1), C2(1,k1)], [C1(2,k1), C2(2,k1)], 'Color',c(k1,:), 'LineWidth',0.25, 'facealpha', 0.2)
    k2 = max([mod(k1+1,size(C2,2)), 1]);
    % Transform k1.
    k3 = mod( (- (k1+90) + 360), 360) + 1 ;
    patch([C1(1,k1), C1(1,k2), C2(1,k2), C2(1,k1)], [C1(2,k1), C1(2,k2), C2(2,k2), C2(2,k1)], c(k3,:), 'Parent', ax, 'facealpha', 0.2, 'EdgeColor','none')    
end
axis(ax, 'off')

end