function configureButton(btn, userdata)

jhComponent = utilities.findjobj('property', {'Text', btn.String}, 'persist', 'nomenu');
% jhComponent = findjobj(btn);

btn.UserData = userdata;
btn.UserData.State = 'MouseNotOver'; 

imwidth = size(userdata.Selected, 2);

btn.Units = 'pixel';
btnWidth = floor(btn.Position(3));
btn.Units = 'normalized';

nPx = abs(btnWidth-imwidth);

fields = fieldnames(userdata);

for i = 1:numel(fields)-1 % Last field is not button image data...
    if imwidth < btnWidth
        btn.UserData.(fields{i}) = cat(2, ...
            btn.UserData.(fields{i})(:, 1:floor(imwidth/2), :), ...
            repmat(btn.UserData.(fields{i})(:,floor(imwidth/2), :), [1, nPx, 1]), ...
            btn.UserData.(fields{i})(:, (floor(imwidth/2)+1):end, :) );
        
    elseif imwidth > btnWidth
        a = round(btnWidth/2);
        btn.UserData.(fields{i}) = cat(2, ...
            btn.UserData.(fields{i})(:, 1:a, : ), ...
            btn.UserData.(fields{i})(:, end-a+1:end, : ) );
        
    end
end

btn.CData = btn.UserData.Unselected;

set(jhComponent, 'BorderPainted', 0);
set(jhComponent, 'border', []);
set(jhComponent, 'Border', []);
javax.swing.UIManager.put('Button.border', []);
javax.swing.UIManager.put('Button.defaultButtonFollowsFocus', 0);

set(jhComponent, 'MouseEnteredCallback', {@customization.mouseEnterButton, btn})
set(jhComponent, 'MouseExitedCallback', {@customization.mouseLeaveButton, btn})
set(jhComponent, 'MouseClickedCallback', {@customization.mouseClickButton, btn})
set(jhComponent, 'MouseReleasedCallback', {@customization.mouseReleaseButton, btn})
set(jhComponent, 'StateChangedCallback', {@customization.buttonValuechange, btn})

end