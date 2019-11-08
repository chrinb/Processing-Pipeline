function mouseClickButton(~, ~, btnHandle)

    btnHandle.UserData.State = 'MouseDown';

    switch btnHandle.Style
        case 'pushbutton'
%             btnHandle.CData = btnHandle.UserData.InFocus;
        case 'togglebutton'
            if btnHandle.Value
%                 pause(0.005)
                btnHandle.CData = btnHandle.UserData.Selected;
            end
    end
end