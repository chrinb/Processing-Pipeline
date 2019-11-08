function mouseEnterButton(~, ~, btnHandle)

    btnHandle.UserData.State = 'MouseOver';
    
    switch btnHandle.Style
        case 'pushbutton'
            btnHandle.CData = btnHandle.UserData.InFocus;
        case 'togglebutton'
            if btnHandle.Value
                btnHandle.CData = btnHandle.UserData.InFocus2;
            else
                btnHandle.CData = btnHandle.UserData.InFocus;
            end
    end
    
    
    
end