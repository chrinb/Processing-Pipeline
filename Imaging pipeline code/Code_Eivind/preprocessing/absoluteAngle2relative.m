function [ angle_vec_rel ] = absoluteAngle2relative( angle_vec_abs )
%absoluteAngle2relative creates a new vector where angles only go between 0
%and 360 in 1 degree steps


angle_vec_rel = zeros(size(angle_vec_abs));

for a = 1:length(angle_vec_abs)
    
    % round angle to integer value
    angle = round(angle_vec_abs(a));      

    % Shift negative angles up
    while angle < 0
        angle = angle + 360;
    end
    
    % Shift angles > 360 down 
    while angle > 360
        angle = angle - 360;
    end
    
    angle_vec_rel(a) = angle;

end
    
end

