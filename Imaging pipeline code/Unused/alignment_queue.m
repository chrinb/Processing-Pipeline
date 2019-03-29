%%Alignment queue

%% mouse042

for i = 4:5
    
    sessionID = 'm042-20170831_1734';
    sessionID = [sessionID, '-', num2str(i, '%03d')];

    printInfo(sessionID)
    imregSessionTmp(sessionID);
    
end


% for i = 1:2
%     
%     
%         sessionID = 'm042-20170907_1755';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         
%         printInfo(sessionID)
%         imregSessionTmp(sessionID);
% %     catch 
% %         s=lasterror;
% %         disp(s.message)
% %         
% %     end
%     
% end


% for i = 3 %1:3
%     
%     try
%         sessionID = 'm042-20170904_1509';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         
%         printInfo(sessionID)
%         imregSessionTmp(sessionID);
%     end
%     
% end
% 
% 
% for i = 1:4
%     
%     try
%         sessionID = 'm042-20170902_2059';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         
%         printInfo(sessionID)
%         imregSessionTmp(sessionID);
%     end
%     
% end
% 
% for i = [2,5,7]
%     
%     try
%         sessionID = 'm042-20170903_1958';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         
%         printInfo(sessionID)
%         imregSessionTmp(sessionID);
%     end
%     
% end
% 
% 
% 
% % %% mouse 43
% % 
% % % 2nd sept
% for i = [2, 4, 5, 6]
%     
%     try
%         sessionID = 'm043-20170902_1825';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         
%         printInfo(sessionID)
%         imregSession(sessionID);
%     end
%     
% end
% % 
% % 3rd sept
% for i = 3
%     
%     try
%         sessionID = 'm043-20170903_2126';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         printInfo(sessionID)
%         imregSession(sessionID);
%     end
%     
% end
% % 
% % % 4th sept
% % for i = 2:3
% %     try
% %         sessionID = 'm043-20170904_1149';
% %         sessionID = [sessionID, '-', num2str(i, '%03d')];
% %         printInfo(sessionID)
% %         imregSession(sessionID);
% %     end
% %     
% % end
% % 
% % % 5th sept
% % for i = 1:2
% %     try
% %         sessionID = 'm043-20170905_2154';
% %         sessionID = [sessionID, '-', num2str(i, '%03d')];
% %         printInfo(sessionID)
% %         imregSession(sessionID);
% %     end
% %     
% % end
% % 
% % 6th sept
% for i = [5, 6]
%     try
%         sessionID = 'm043-20170906_1140';
%         sessionID = [sessionID, '-', num2str(i, '%03d')];
%         printInfo(sessionID)
%         imregSession(sessionID);
%     end
%     
% end
% 
% 
% % 
% % try
% %     imregSession('m042-20170904_1509-001');    
% % end
% % 
% % try
% %     imregSession('m042-20170904_1509-002');
% % end
% 
% try
%     imregSession('m042-20170904_1509-003');
% end
% 
% 
% %%% 3rd of sept
% % 
% % for i = 1:7
% %     
% %     try
% %         sessionID = 'm042-20170903_1958';
% %         sessionID = [sessionID, '-', num2str(i, '%03d')];
% %         imregSession(sessionID);
% %     end
% %     
% % end
% 
% 
% 
% % %%% 2nd of sept
% % try
% %     imregSession('m042-20170902_2059-001');
% % end
% % try
% %     imregSession('m042-20170902_2059-002');
% % end
% try
%     imregSession('m042-20170902_2059-003');
% end
% try
%     imregSession('m042-20170902_2059-004');
% end
% 
% 
% 
% % try
% %     imregSession('m042-20170902_2059-004');
% % end
% 
% % try
% %     imregSession('m043-20170831_2046-005');
% % end
% 
% % 
% % for i = 1
% %     tmp_imArray = stack2mat(['/Users/eivinhen/Desktop/rigid_chunk', num2str(i), '.tif']);
% %     Y1 = double(tmp_imArray);
% %     options_nonrigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),...
% %                            'grid_size',[128, 128],'mot_uf',4,'bin_width',43,...
% %                            'max_shift',15,'max_dev',30,'us_fac',50);
% % 
% %     [tmp_imArray, ~, ~] = normcorre_batch(Y1, options_nonrigid);
% %     mat2stack(uint8(tmp_imArray), ['/Users/eivinhen/Desktop/imreg_nr_chunk', num2str(i), '.tif'])
% % 
% % end
% 
% 
