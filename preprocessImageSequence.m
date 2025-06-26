function [alignedImgs, tforms] = preprocessImageSequence(imgs)
    refImg = imgs{1};
    refGray = rgb2gray(refImg);

    alignedImgs = cell(1, numel(imgs));
    alignedImgs{1} = refImg;
    tforms = cell(1, numel(imgs));
    tforms{1} = affine2d(eye(3)); % Identity transform for ref

    for i = 2:numel(imgs)
        currImg = imgs{i};
        currGray = rgb2gray(currImg);

        pts1 = detectSURFFeatures(refGray);
        pts2 = detectSURFFeatures(currGray);

        [features1, validPts1] = extractFeatures(refGray, pts1);
        [features2, validPts2] = extractFeatures(currGray, pts2);

        indexPairs = matchFeatures(features1, features2);
        matched1 = validPts1(indexPairs(:,1));
        matched2 = validPts2(indexPairs(:,2));

        tform = estimateGeometricTransform2D(matched2, matched1, 'affine', ...
    'MaxNumTrials', 5000, ...
    'Confidence', 99.9, ...
    'MaxDistance', 4);
        outputView = imref2d(size(refImg));
        aligned = imwarp(currImg, tform, 'OutputView', outputView, 'FillValues', NaN);


        alignedImgs{i} = aligned;
        tforms{i} = tform;
    end


end
