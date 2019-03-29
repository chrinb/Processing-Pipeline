 refImPath = fullfile(sessionFolder, ['session_reference_img-plane' num2str(plane_num) '.tif'])

                % Align all stacks to the first stack of the session
                if chunk == 1
                    imwrite(uint8(mean(tmp_imArray(:,:,plane_num:4:end), 3)), refImPath, 'TIFF')

                else
                    ref = double(imread(refImPath));
                    src = mean(tmp_imArray(:,:,plane_num:4:end), 3);

                    % Get displacements using imreg_fft
                    [~, dx, dy, ~] = imreg_fft(src, ref);

                    tmp_imArray(:,:,plane_num:4:end) = shiftStack(tmp_imArray(:,:,plane_num:4:end), dx, dy);         
                end

                saveData(tmp_imArray, 'RegisteredImages', sessionID, block, ch, chunk,plane_num);