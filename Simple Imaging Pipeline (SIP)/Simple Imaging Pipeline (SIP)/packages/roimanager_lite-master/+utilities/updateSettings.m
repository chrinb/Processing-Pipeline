function updatedSettings = updateSettings(defaultSettings, loadedSettings)
% Check if there are settings which are not loaded from file, e.g
% if program was updated.

    defaultFields = fieldnames(defaultSettings);
    loadedFields = fieldnames(loadedSettings);

    missingFields = setdiff(defaultFields, loadedFields);
    if ~isempty(missingFields)
        for i = 1:numel(missingFields)
            loadedSettings.(missingFields{i}) = defaultSettings.(missingFields{i});
        end
    end

    extraFields = setdiff(loadedFields, defaultFields);
    if ~isempty(extraFields)
        for i = 1:numel(extraFields)
            loadedSettings = rmfield(loadedSettings, extraFields{i});
        end
    end
    
    if isfield(loadedSettings, 'dffMethod')
        currentfilepath = mfilename('fullpath');
        currentpath = fileparts(currentfilepath);
        dffpath = strrep(currentpath, '+utilities', '+signalExtraction/+dff');
        methodListing = dir(fullfile(dffpath, '*.m'));
        methodNames = {methodListing(:).name};
        methodNames = cellfun(@(name) strrep(name, '.m', ''), methodNames, 'uni', 0);
        loadedSettings.dffMethod.Alternatives = methodNames;
    end

    
    
    updatedSettings = loadedSettings;

end