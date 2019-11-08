% Get a Matlab figure's underlying Java Frame (RootPane) reference handle
function JavaFrame = getJavaFrame( hFig )
    try
        %  contentSize = [0,0];  % initialize
        JavaFrame = hFig;
        figName = get(hFig,'name');
        if strcmpi(get(hFig,'number'),'on')
            figName = regexprep(['Figure ' num2str(hFig) ': ' figName],': $','');
        end
        mde = com.mathworks.mde.desk.MLDesktop.getInstance;
        jFigPanel = mde.getClient(figName);
        JavaFrame = jFigPanel;
        JavaFrame = jFigPanel.getRootPane;
    catch
        try
            jFrame = get(handle(hFig),'JavaFrame');
            jFigPanel = get(jFrame,'FigurePanelContainer');
            JavaFrame = jFigPanel;
            JavaFrame = jFigPanel.getComponent(0).getRootPane;
        catch
            % Never mind
        end

    end
    try
        % If invalid RootPane, retry up to N times
        tries = 10;
        while isempty(JavaFrame) && tries>0  % might happen if figure is still undergoing rendering...
            drawnow; pause(0.001);
            tries = tries - 1;
            JavaFrame = jFigPanel.getComponent(0).getRootPane;
        end

        % If still invalid, use FigurePanelContainer which is good enough in 99% of cases... (menu/tool bars won't be accessible, though)
        if isempty(JavaFrame)
            JavaFrame = jFigPanel;
        end
        % contentSize = [JavaFrame.getWidth, JavaFrame.getHeight];

        % Try to get the ancestor FigureFrame
        JavaFrame = JavaFrame.getTopLevelAncestor;
    catch
        % Never mind - FigurePanelContainer is good enough in 99% of cases... (menu/tool bars won't be accessible, though)
    end
end  % getJavaFrame
