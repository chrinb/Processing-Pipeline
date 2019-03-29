function roiArray_new = CaSourceExtractWrapper(imArrayPath, numRois, firstID)
% Run calcium source extraction (Paninski) and return autodetected rois.

    % load file

    Y = stack2mat(imArrayPath);
    Y = circularCrop(Y);
    Y = Y(:,:,1:5:end);
    %Y = Y - min(Y(:)); 
    if ~isa(Y,'double');    Y = double(Y);  end     % convert to single

    [d1,d2,T] = size(Y);                            % dimensions of dataset
    d = d1*d2;                                      % total number of pixels

    
    % Set parameters

    K = numRois;                            % number of components to be found
    tau = 15;                          % std of gaussian kernel (size of neuron) 
    p = 2;                             % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    merge_thr = 0.8;                   % merging threshold

    options = CNMFSetParms(...                      
        'd1',d1,'d2',d2,...                         % dimensions of datasets
        'search_method','dilate','dist',3,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'temporal_iter',2,...                       % number of block-coordinate descent steps 
        'fudge_factor',0.98,...                     % bias correction for AR coefficients
        'merge_thr',merge_thr,...                   % merging threshold
        'gSig',tau...
        );

    % Data pre-processing

    [P,Y] = preprocess_data(Y,p);

    %% fast initialization of spatial components using greedyROI and HALS

    [Ain,Cin,bin,fin,center] = initialize_components(Y,K,tau,options,P);  % initialize

%     % display centers of found components
%     Cn =  correlation_image(Y); %reshape(P.sn,d1,d2);  %max(Y,[],3); %std(Y,[],3); % image statistic (only for display purposes)
%     figure;imagesc(Cn);
%         axis equal; axis tight; hold all;
%         scatter(center(:,2),center(:,1),'mo');
%         title('Center of ROIs found from initialization algorithm');
%         drawnow;

    %% manually refine components (optional)
    refine_components = false;  % flag for manual refinement
    if refine_components
        [Ain,Cin,center] = manually_refine_components(Y,Ain,Cin,center,Cn,tau,options);
    end

    %% update spatial components
    Yr = reshape(Y,d,T);
    [A,b,Cin] = update_spatial_components(Yr,Cin,fin,[Ain,bin],P,options);

    %% update temporal components
    P.p = 0;    % set AR temporarily to zero for speed
    [C,f,P,S,YrA] = update_temporal_components(Yr,A,b,Cin,fin,P,options);

    %% merge found components
    [Am,Cm,K_m,merged_ROIs,Pm,Sm] = merge_components(Yr,A,b,C,f,P,S,options);

    %%
    display_merging = 0; % flag for displaying merging example
    if and(display_merging, ~isempty(merged_ROIs))
        i = 1; %randi(length(merged_ROIs));
        ln = length(merged_ROIs{i});
        figure;
            set(gcf,'Position',[300,300,(ln+2)*300,300]);
            for j = 1:ln
                subplot(1,ln+2,j); imagesc(reshape(A(:,merged_ROIs{i}(j)),d1,d2)); 
                    title(sprintf('Component %i',j),'fontsize',16,'fontweight','bold'); axis equal; axis tight;
            end
            subplot(1,ln+2,ln+1); imagesc(reshape(Am(:,K_m-length(merged_ROIs)+i),d1,d2));
                    title('Merged Component','fontsize',16,'fontweight','bold');axis equal; axis tight; 
            subplot(1,ln+2,ln+2);
                plot(1:T,(diag(max(C(merged_ROIs{i},:),[],2))\C(merged_ROIs{i},:))'); 
                hold all; plot(1:T,Cm(K_m-length(merged_ROIs)+i,:)/max(Cm(K_m-length(merged_ROIs)+i,:)),'--k')
                title('Temporal Components','fontsize',16,'fontweight','bold')
            drawnow;
    end

    %% evaluate components

    options.space_thresh = 0.3;
    options.time_thresh = 0.3;
    [rval_space,rval_time,ind_space,ind_time] = classify_comp_corr(Y,Am,Cm,b,f,options);

    keep = ind_time & ind_space; 
    throw = ~keep;
%     figure;
%         subplot(121); plot_contours(Am(:,keep),Cn,options,1); title('Selected components','fontweight','bold','fontsize',14);
%         subplot(122); plot_contours(Am(:,throw),Cn,options,1);title('Rejected components','fontweight','bold','fontsize',14);

    %% refine estimates excluding rejected components

    Pm.p = p;    % restore AR value
    [A2,b2,C2] = update_spatial_components(Yr,Cm(keep,:),f,[Am(:,keep),b],Pm,options);
    [C2,f2,P2,S2,YrA2] = update_temporal_components(Yr,A2,b2,C2,f,Pm,options);


    %% do some plotting

     [A_or, C_or, S_or, P_or] = order_ROIs(A2,C2,S2,P2); % order components
%     K_m = size(C_or,1);
%     [C_df,~] = extract_DF_F(Yr,A_or,C_or,P_or,options); % extract DF/F values (optional)

%     figure;
%     [Coor,json_file] = plot_contours(A_or,Cn,options,1); % contour plot of spatial footprints
%     %savejson('jmesh',json_file,'filename');        % optional save json file with component coordinates (requires matlab json library)

    %% display components

    %plot_components_GUI(Yr,A_or,C_or,b2,f2,Cn,options)
    
    %% convert to array of RoI objects
    roiArray_new = RoI.empty;

    for i = 1:size(A_or, 2)
        Atemp = reshape(A_or(:,i), d1, d2);
        Atemp = full(Atemp);
        mask = Atemp>0;

        %loop through all rois pass roi mask to RoI
        newRoI = RoI(Atemp);    
        newRoI.Group = 'Auto';
        newRoI.Shape = 'Outline';
        newRoI.ID = i + firstID;
        newRoI.Tag = [newRoI.Group(1:4), num2str(i,'%03d')];
        roiArray_new(end+1) = newRoI;
    end
    
    
    
end