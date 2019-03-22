%Matlab implementation does not work so well.


% I think in their function, they mixed up the size of the traces. S is
% nRois x nSamples, but in the docu of this function they say it is
% nSamples x nSignals...

function [S_sep, S_matched, A_sep] = separate(S, options)
        
% For the signals in S, finds the independent signals underlying it,
%     using ica or nmf.
% 
%     Parameters
%     ----------
%     S : array_like
%         2d array with signals. S[i,j], j = each signal, i = signal content.
%         j = 0 is considered the primary signal. (i.e. the somatic signal)
%     options : struct with following fields:
%
%     sep_method : {'ica','nmf'}
%         Which source separation method to use, ica or nmf.
%             * ica: independent component analysis
%             * nmf: Non-negative matrix factorization
%     n : int, optional
%         How many components to estimate. If None, use PCA to estimate
%         how many components would explain at least 99% of the variance.
%     maxiter : int, optional
%         Number of maximally allowed iterations. Default is 500.
%     tol : float, optional
%         Error tolerance for termination. Default is 1e-5.
%     random_state : int, optional
%         Initial random state for seeding. Default is 892.
%     maxtries : int, optional
%         Maximum number of tries before algorithm should terminate.
%         Default is 10.
%     W0, H0 : arrays, optional
%         Optional starting conditions for nmf
%     alpha : float
%         [expand explanation] Roughly the sparsity constraint
% 
%     Returns
%     -------
%     S_sep : numpy.ndarray
%         The raw separated traces
%     S_matched :
%         The separated traces matched to the primary signal, in order
%         of matching quality (see Implementation below).
%     A_sep :
%     convergence : dict
%         Metadata for the convergence result, with keys:
%             * random_state: seed for ica initiation
%             * iterations: number of iterations needed for convergence
%             * max_iterations: maximun number of iterations allowed
%             * converged: whether the algorithm converged or not (bool)
% 
%     Implementation
%     --------------
%     Concept by Scott Lowe and Sander Keemink.
%     Normalize the columns in estimated mixing matrix A so that sum(column)=1
%     This results in a relative score of how strongly each separated signal
%     is represented in each ROI signal.


% This is definitely nicer in python.
defoptions = struct();
defoptions.sep_method = 'nmf';
defoptions.n = 'None'; 
defoptions.maxiter = 10000;
defoptions.tol = 1e-4;
defoptions.random_state = 892; 
defoptions.maxtries = 10;
defoptions.W0 = 'None';
defoptions.H0 = 'None';
defoptions.alpha = 0.1;

if nargin < 2 || isempty(options); options = defoptions; end

optFields = fieldnames(options);
defoptFields = fieldnames(defoptions);

unsetFields = setdiff(defoptFields, optFields);
for i = 1:numel(unsetFields)
    options.(unsetFields{i}) = defoptions.(unsetFields{i});
end

optFields = fieldnames(options);
for i = 1:numel(optFields)
    eval([optFields{i} '= options.(''' optFields{i} ''');'])
end

% End of options...

% normalize
medianS = median(S(:));
S = S ./ medianS;


% estimate number of signals to find, if not given
if isequal(n, 'None')
    switch sep_method
        case 'ica' % TODO
% %             % Perform PCA
% %             pca = PCA(whiten=False)
% %             pca.fit(S.T)
% % 
% %             % find number of components with at least x percent explained var
% %             n = sum(pca.explained_variance_ratio_ > 0.01)
        otherwise
            n = size(S, 2)-1; % S.shape[0] - Why 0th dim???
    end
end

switch sep_method

% %    case 'ica'
% %         % Use sklearn's implementation of ICA.
% % 
% %         for ith_try in range(maxtries):
% %             % Make an instance of the FastICA class. We can do whitening of
% %             % the data now.
% %             ica = FastICA(n_components=n, whiten=True, max_iter=maxiter,
% %                           tol=tol, random_state=random_state)
% % 
% %             % Perform ICA and find separated signals
% %             S_sep = ica.fit_transform(S.T)
% % 
% %             % check if max number of iterations was reached
% %             if ica.n_iter_ < maxiter:
% %                 print((
% %                     'ICA converged after {} iterations.'
% %                 ).format(ica.n_iter_))
% %                 break
% %             print((
% %                 'Attempt {} failed to converge at {} iterations.'
% %             ).format(ith_try + 1, ica.n_iter_))
% %             if ith_try + 1 < maxtries:
% %                 print('Trying a new random state.')
% %                 % Change to a new random_state
% %                 random_state = rand.randint(8000)
% % 
% %         if ica.n_iter_ == maxiter:
% %             print((
% %                 'Warning: maximum number of allowed tries reached at {} '
% %                 'iterations for {} tries of different random seed states.'
% %             ).format(ica.n_iter_, ith_try + 1))
% % 
% %         A_sep = ica.mixing_

    case 'nmf'
        
        maxtries=1;        
        S_sep = cell(maxtries,1);
        S_matched = zeros([size(S,1),n, maxtries]);
        A_sep = cell(maxtries,1);
        C = cell(maxtries,1);        
        
        for i = 1:maxtries
            
            nnmfoptions = statset('nnmf');
            nnmfoptions.MaxIter = options.maxiter;
            nnmfoptions.TolFun = options.tol;
            
            if isequal(W0, 'None')
%                 [S_sep, A_sep] = nnmf(S, n, 'replicates', 100, 'options', nnmfoptions);
                
                config = struct('W_sparsity', 0, 'H_sparsity', 0, 'maxiter', 10000, 'tolerance', 1e-4);
%                 [W, H, Cost] = nmfsc(S, n, config);
%                 C{i} = min(Cost);
                
%                 [W, H, numIter,tElapsed,finalResidual]=sparseNMFNNQP(S, n);
                [W, H,numIter,tElapsed,finalResidual]=sparsenmfnnls(S, n);
                
                % make empty matched structure
                S_matched(:, :, i) = zeros(size(W));

                % Normalize the columns in A so that sum(column)=1 (can be done in one line
                % too).
                % This results in a relative score of how strongly each separated signal
                % is represented in each ROI signal.

                A = abs(H);
                A = A ./ sum(A, 1);

                % get the scores for the somatic signal
                scores = A(:, 1);

                % get the order of scores
                [~, order] = sort(scores, 'descend'); % order = np.argsort(scores)[::-1] %TODO Er dette riktig oversatt

                % order the signals according to their scores
                for j = 1:n
                    s_ = H(order(j), 1) * W(:, order(j));
                    S_matched(:, j, i) = s_;
                end

                % scale back to raw magnitudes
                S_matched(:, :, i) = S_matched(:, :, i) .* medianS;

      
%                 config = struct('W_sparsity', 0, 'H_sparsity', 0, 'maxiter', 10000, 'tolerance', 1e-4);
%                 [S_sep, A_sep, ~] = nmf(S, n, config);

%                 config = struct('divergence', 'ab', 'alpha', 0.1, 'beta', 1, 'maxiter', 10000, 'tolerance', 1e-4);
%                 [S_sep, A_sep, ~] = nmf(S, n, config);
                
%                 [S_sep, A_sep] = nnmf(S, 4, 'algorithm', 'mult', 'options', nnmfoptions, 'replicates', 10);
                
% %             nmf = NMF(
% %                     init='nndsvdar', n_components=n,
% %                     alpha=alpha, l1_ratio=0.5,
% %                     tol=tol, max_iter=maxiter, random_state=random_state)




            else
                % Perform NMF and find separated signals
                [S_sep, A_sep] = nnmf(S, n,'w0', W0, 'h0', H0);
                
            end
            
        end
                
% %                 nmf = NMF(
% %                     init='custom', n_components=n,
% %                     alpha=alpha, l1_ratio=0.5,
% %                     tol=tol, max_iter=maxiter, random_state=random_state)


% Not sure if the following is necessary in matlab:

% %             % check if max number of iterations was reached
% %             if nmf.n_iter_ < maxiter - 1:
% %                 print((
% %                     'NMF converged after {} iterations.'
% %                 ).format(nmf.n_iter_ + 1))
% %                 break
% %             print((
% %                 'Attempt {} failed to converge at {} iterations.'
% %             ).format(ith_try, nmf.n_iter_ + 1))
% %             if ith_try + 1 < maxtries:
% %                 print('Trying a new random state.')
% %                 % Change to a new random_state
% %                 random_state = rand.randint(8000)
% % 
% %         if nmf.n_iter_ == maxiter - 1:
% %             print((
% %                 'Warning: maximum number of allowed tries reached at {} '
% %                 'iterations for {} tries of different random seed states.'
% %             ).format(nmf.n_iter_ + 1, ith_try + 1))

% I am going to assume that A_Sep is the same as H
% %         A_sep = nmf.components_.T 
        

    otherwise
        error('Unknown separation method %s.', sep_method)
end

showPlot = true;

if showPlot
    figure;
    plot(squeeze(S_matched(:, 1, :)))
end
    
    
S_matched = mean(smoothdata(S_matched, 1, 'movmean', 5), 3);

if showPlot
    figure;
    plot(squeeze(S_matched(:, 1)))
end

%S_matched = mean(cat(3, S_matched{:}), 3);

S = S .* medianS;

  
end