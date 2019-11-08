function buttonValuechange(~, ~, btnHandle)
    
    % Change button cdata if the value change is not initiated by a button
    % press....
    
    if btnHandle.Value
        if isequal(btnHandle.UserData.State, 'MouseNotOver')
            btnHandle.CData = btnHandle.UserData.Selected;
        end            

    else
        if isequal(btnHandle.UserData.State, 'MouseNotOver')
            btnHandle.CData = btnHandle.UserData.Unselected;
        end
    end

        
end