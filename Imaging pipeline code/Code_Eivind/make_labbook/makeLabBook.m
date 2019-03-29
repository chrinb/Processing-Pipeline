function [ ] = makeLabBook(  )
%makeLabBook Format info about mouse and experiments into tex files.
%   Detailed explanation goes here

% Paths to files for making labbook
labBookPath = getPathToDir('labbook');
labBookMatPath = getPathToDir('labbook_mat');
labBookTexPath = getPathToDir('labbook_tex');

mouseInv = loadMouseInv();
expInv = loadExpInv( );

% make main (labbook) tex file
labbook_tex = fullfile(labBookTexPath, 'labbook.tex');
        
fileId = fopen(labbook_tex, 'w');
writeTex(fileId, '\documentclass[11pt, english, twoside, a4paper]{book}')
writeTex(fileId, '\usepackage[numbers]{natbib}')
writeTex(fileId, ' ')
writeTex(fileId, '\include{settings}')
writeTex(fileId, ' ')
writeTex(fileId, '\begin{document}')
writeTex(fileId, ' ')
writeTex(fileId, '\frontmatter') %turns off chapter numbering and uses roman numerals for page numbers
writeTex(fileId, '	\includepdf{cover}')
writeTex(fileId, '	\include{preface}')
writeTex(fileId, '	\include{guidelines_labbook}')
writeTex(fileId, '	\tableofcontents')

writeTex(fileId, ' ')
writeTex(fileId, '\mainmatter %turns on chapter numbering, resets page numbering and uses arabic numerals for page numbers')
writeTex(fileId, '\chapter{Mouse Inventory}');
for m = 2:3%length(mouseInv)
    mouseId = mouseInv{m, 1};
    addMouseToLabbook(mouseId)
    writeTex(fileId, ['\include{' mouseId '}'])
    
    % Add sessions which are present for current mouse
    mId = strrep(mouseId, 'ouse', ''); % shorten mouse001 to m001
    mouseSessions = find(strncmp( expInv(:, 1), mId, 4 ));
    if isempty(mouseSessions); mouseSessions = []; end
    
    for s = mouseSessions'
        session = expInv{s, 2};
        if session.isAnalyzed
            addSessionToLabbook(session.sessionID)
            writeTex(fileId, ['\include{' session.sessionID '}'])
        end
    end
    
end
writeTex(fileId, ' ')
writeTex(fileId, '\appendix') %resets chapter numbering, uses letters for chapter numbers and doesn't fiddle with page numbering
writeTex(fileId, '\chapter{Standard Operating Procedures}')
writeTex(fileId, '  \include{appendix_sop_imaging}')
writeTex(fileId, '  \include{appendix_sop_window_implant}')
writeTex(fileId, '\chapter{Experimental Protocols}')
writeTex(fileId, '  \include{appendix_protocol_mouse_habituation}')


%\backmatter %turns off chapter numbering and doesn't fiddle with page numbering
writeTex(fileId, ' ')
writeTex(fileId, '\end{document}')

fclose(fileId);

% make labbook
pdflatex = '/usr/local/texlive/2016/bin/x86_64-darwin/pdflatex';
cd(fullfile(labBookTexPath))
system([pdflatex, ' ', 'labbook.tex']);
cd(labBookMatPath)

copyfile(fullfile(labBookTexPath, 'labbook.pdf'), ...
         fullfile(labBookPath, 'labbook.pdf') ) 
end

