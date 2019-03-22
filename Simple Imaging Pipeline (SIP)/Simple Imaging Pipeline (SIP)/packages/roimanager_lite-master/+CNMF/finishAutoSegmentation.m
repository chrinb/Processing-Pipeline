function [roiArray, cnmfResults] = finishAutoSegmentation(cnmfData)

    % % "Unzip variables"

    Y = cnmfData.Y;
    P = cnmfData.P;
    options = cnmfData.options;
    T = cnmfData.options.nFrames;
    d = cnmfData.options.d;
    d1 = cnmfData.options.d1;
    d2 = cnmfData.options.d2;
    Ain = cnmfData.Ain;
    Cin = cnmfData.Cin;
    bin = cnmfData.bin;
    fin = cnmfData.fin;
    p = 2;
    
    clearvars cnmfData

    % % update spatial components

    Yr = reshape(Y,d,T);
    [A,b,Cin] = update_spatial_components(Yr,Cin,fin,[Ain,bin],P,options);

    % % update temporal components
    P.p = 0;    % set AR temporarily to zero for speed
    [C,f,P,S,YrA] = update_temporal_components(Yr,A,b,Cin,fin,P,options);

    % % merge found components
    [Am,Cm,K_m,merged_ROIs,Pm,Sm] = merge_components(Yr,A,b,C,f,P,S,options);

    % % evaluate components
    options.space_thresh = 0.3;
    options.time_thresh = 0.3;
    [rval_space,rval_time,ind_space,ind_time] = classify_comp_corr(Y,Am,Cm,b,f,options);

    keep = ind_time & ind_space; 
    throw = ~keep;

    % % refine estimates excluding rejected components
    Pm.p = p;    % restore AR value
    [A2,b2,C2] = update_spatial_components(Yr,Cm(keep,:),f,[Am(:,keep),b],Pm,options);
    [C2,f2,P2,S2,YrA2] = update_temporal_components(Yr,A2,b2,C2,f,Pm,options);

    % % do some plotting

     [A_or, C_or, S_or, P_or] = order_ROIs(A2,C2,S2,P2); % order components

     [C_df,~] = extract_DF_F(Yr,A_or,C_or,P_or,options); % extract DF/F values (optional)

    % % convert to array of RoI objects
    roiArray = RoI.empty;

    for i = 1:size(A_or, 2)
        Atemp = reshape(A_or(:,i), d1, d2);
        Atemp = full(Atemp);
        mask = Atemp>0;

        %loop through all rois pass roi mask to RoI
        newRoI = RoI('Mask', mask, [d1, d2]);
        newRoI.structure = 'ad';
        roiArray(i) = newRoI;
    end
    
    cnmfResults = struct;
    cnmfResults.A = A_or;
    cnmfResults.C = C_or;
    cnmfResults.S = S_or;
    cnmfResults.Cdff = C_df;
     

end
