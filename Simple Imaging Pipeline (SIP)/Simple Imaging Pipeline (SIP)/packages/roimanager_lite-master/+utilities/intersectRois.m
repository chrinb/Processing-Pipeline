function roiArrayDiff = intersectRois(roiArray1, roiArray2)

    roiUid1 = {roiArray1(:).uid};
    roiUid2 = {roiArray2(:).uid};
    
    [~, roiInd] = intersect(roiUid1, roiUid2);

    roiArrayDiff = roiArray1(roiInd);
    
end
