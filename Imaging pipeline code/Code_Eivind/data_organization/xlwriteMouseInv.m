function [ ] = xlwriteMouseInv( )
%xlwriteMouseInv Write mouse inventory to xls file
%   Requires xlWrite from matlab central

mouseInv = loadMouseInv;
nMiceEntries = size(mouseInv, 1) - 1; % First line is column titles.


% The xlWrite package downloaded from Matlab central requires the following lines:
xlWritePath = getPathToDir('xlwrite');

poiLibPath = fullfile(xlWritePath, 'poi_library');
addpath(xlWritePath)

javaaddpath(fullfile(poiLibPath, 'poi-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(poiLibPath, 'xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(poiLibPath, 'dom4j-1.6.1.jar'));

mouseInventoryXL = fullfile(getPathToDir('labbook'), 'mouseInventory_autogen.xlsx' );
excelFileExists = exist(mouseInventoryXL, 'file');

xlCols = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',...
        'P','Q','R','S','T','U','V','W','X','Y','Z', 'AA', 'AB'};
    
excludeFields = {'mouseNo', 'mousePortrait', 'headbarNo', 'brainSurface', ...
                 'headbarStyle', 'refCoordsIM', 'refCoordsRW', 'pxPermm', ...
                 'injectionCoordsIM', 'injectionCoordsRW', 'imagingLocations', ...
                 'imagingLocRWmm'};
             
lineCount = 3;

for m = 1:nMiceEntries
    mInf = mouseInv{m+1, 2};
    %remove fields which does not fit in excel file
    allProps = properties(mInf);
    excludeIdx = cell2mat(cellfun(@(x) sum(strcmp(x, excludeFields)), allProps, 'un', 0));
    excelProps = allProps(~excludeIdx);
    %fields = fieldnames(fieldsExcel);
    
    if m == 1 && ~excelFileExists
        xlwrite(mouseInventoryXL, excelProps.', 'MouseInventory', ...
               'A2') ;
    end
    
    %loop through fields
    for f = 1:length(excelProps)
        disp(f)
        excelProps{f}
        xlwrite(mouseInventoryXL, {mInf.(excelProps{f})}, 'MouseInventory', ...
               [xlCols{f}, num2str(lineCount) ':' xlCols{f}, num2str(lineCount)]);
    end
    
    lineCount = lineCount + 1


end

