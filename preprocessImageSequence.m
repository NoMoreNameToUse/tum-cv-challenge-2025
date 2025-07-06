function [alignedImgs, tforms] = preprocessImageSequence(imgs)
    refImg = imgs{1};
    refGray = rgb2gray(refImg);

    n = numel(imgs);
    alignedImgs = cell(1, n);
    alignedImgs{1} = refImg;
    tforms = cell(1, n);
    tforms{1} = affine2d(eye(3)); % identity

    prevImg = refImg;
    prevGray = refGray;
    cumulativeTform = affine2d(eye(3));

    for i = 2:n
        currImg = imgs{i};
        currGray = rgb2gray(currImg);

        pts1 = detectSURFFeatures(prevGray);
        pts2 = detectSURFFeatures(currGray);
        [features1, validPts1] = extractFeatures(prevGray, pts1);
        [features2, validPts2] = extractFeatures(currGray, pts2);

        indexPairs = matchFeatures(features1, features2, ...
    'Method', 'Exhaustive', ...        
    'MaxRatio', 0.85, ...
    'MatchThreshold', 10, ...
    'Metric','SAD', ...
    'Unique', true);

        if size(indexPairs,1) < 3
            warning("Zu wenige Matches (%d), überspringe Bild %d.", size(indexPairs,1), i);
            tforms{i} = tforms{i-1}; % gleiche wie vorher
            alignedImgs{i} = imwarp(currImg, tforms{i}, 'OutputView', imref2d(size(refImg)), 'FillValues', NaN);
            continue
        end

        matched1 = validPts1(indexPairs(:,1));
        matched2 = validPts2(indexPairs(:,2));

        tformRel = estimateGeometricTransform2D(matched2, matched1, 'affine', ...
            'MaxNumTrials', 10000, 'Confidence', 99, 'MaxDistance', 10);

        % Akkumuliere Transformation
        cumulativeTform.T = tformRel.T * cumulativeTform.T;
        tforms{i} = cumulativeTform;

        alignedImgs{i} = imwarp(currImg, cumulativeTform, 'OutputView', imref2d(size(refImg)), 'FillValues', NaN);

        % Setze dieses Bild als neues "prev"
        prevGray = currGray;
    end
end
