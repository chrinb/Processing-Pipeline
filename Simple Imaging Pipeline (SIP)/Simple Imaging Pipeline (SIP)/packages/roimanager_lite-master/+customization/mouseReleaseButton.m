function mouseReleaseButton(~, ~, btnHandle)

    btnHandle.UserData.State = 'MouseUp';

    switch btnHandle.Style
        case 'pushbutton'
            btnHandle.CData = btnHandle.UserData.Unselected;
        case 'togglebutton'
            pause(0.005)

            if ~btnHandle.Value
                btnHandle.CData = btnHandle.UserData.InFocus;
            else
                btnHandle.CData = btnHandle.UserData.InFocus2;
            end
    end
end