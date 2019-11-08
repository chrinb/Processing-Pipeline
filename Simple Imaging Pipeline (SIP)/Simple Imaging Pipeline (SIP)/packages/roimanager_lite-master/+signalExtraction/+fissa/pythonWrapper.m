function unMixedSignal = pythonWrapper(extractedSignals)
%pythonWrapper Call python script to run fissa separation

    path = mfilename('fullpath');
    [path, ~, ~] = fileparts(path);

    pyscript = fullfile(path, 'fissa_separation.py');

    filepath_extracted = fullfile(path, 'tmp', 'extracted_signal.mat');
    save(filepath_extracted, 'extractedSignals')
    filepath_separated = strrep(filepath_extracted, 'extracted_signal', 'separated_signal');

    % Call python script to run fissa separation
    [~, ~] = system(sprintf('python %s %s %s', ...
                        pyscript, filepath_extracted, filepath_separated));

    S = load(filepath_separated, 'matchedSignals');
    unMixedSignal = S.matchedSignals(:, 1);
    
end