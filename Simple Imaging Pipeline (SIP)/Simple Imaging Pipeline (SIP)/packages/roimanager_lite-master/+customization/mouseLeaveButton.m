function mouseLeaveButton(~, ~, btnHandle)

    btnHandle.UserData.State = 'MouseNotOver';
    
    switch btnHandle.Style
        case 'pushbutton'
            btnHandle.CData = btnHandle.UserData.Unselected;
        case 'togglebutton'
            if ~btnHandle.Value
                btnHandle.CData = btnHandle.UserData.Unselected;
            else
                btnHandle.CData = btnHandle.UserData.Selected;
            end
    end
    
    
end