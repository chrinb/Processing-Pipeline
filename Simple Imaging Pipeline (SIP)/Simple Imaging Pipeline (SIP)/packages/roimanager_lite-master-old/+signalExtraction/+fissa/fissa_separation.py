import glob
from scipy.io import loadmat, savemat
import numpy as np

import fissa


def fissa_separate(input_file, output_file):

    # Load signals which are extracted in MATLAB
    signaldata = loadmat(input_file)
    signalArray = signaldata['extractedSignals']  # signalArray is nSamples x nSubregions x nRois
    

    arraySize = np.shape(signalArray)

    if len(arraySize) == 2:
        nRois = 1
    else:
        nRois = arraySize[2];

    # Create arrays for output
    S_sep = np.zeros(arraySize)
    S_matched = np.zeros(arraySize)

    # Loop through rois
    for i in range(nRois):

        if nRois == 1:
            roiSignal = signalArray.T
        else:
            roiSignal = signalArray[:, :, i].T

        S_sep_i, S_matched_i, A_sep, convergence = fissa.neuropil.separate(roiSignal)
        
        # Transpose back to get nSamples x nSubregions x nRois
        if nRois == 1:
            S_sep = S_sep_i.T
            S_matched = S_matched_i.T
        else:
            S_sep[:, :, i] = S_sep_i.T
            S_matched[:, :, i] = S_matched_i.T


    # Save results from fissa to a matfile
    S = {'separatedSignals' : S_sep, 'matchedSignals' : S_matched}
    savemat(output_file, S)


if __name__ == '__main__':

    import sys

    input_file = str(sys.argv[1])
    output_file = str(sys.argv[2])
    
    fissa_separate(input_file, output_file)

    try: 
        outputStr = str('Separated signals saved to {}'.format(output_file))
        sys.stdout.write(outputStr)
    except: #Catch all errors
        err = sys.exc_info()[0]
        sys.stdout.write('Error: %s' % err)
