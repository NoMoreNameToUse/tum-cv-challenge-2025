function [alignedImgs, tforms] = preprocessImageSequence(imgs)
    rng(10);
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

        % Stempelfilterung: entferne Features im unteren Rand (z. B. 10 %)
        h1 = size(prevGray,1);
        h2 = size(currGray,1);
        margin = round(0.05 * h1);  % z. B. 5 % des Bildes

        pts1 = pts1(pts1.Location(:,2) < (h1 - margin));
        pts2 = pts2(pts2.Location(:,2) < (h2 - margin));
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

        tformRel = [];
        success = false;

        % Versuche affine Transformation
        if size(indexPairs,1) >= 3
            try
                [tformRel, inlierIdx] = estimateGeometricTransform2D(matched2, matched1, ...
                    'affine', 'MaxNumTrials', 10000, 'Confidence', 99, 'MaxDistance', 2);
                
                                % LO-RANSAC: Rechne Least Squares auf den Inliers
                if numel(inlierIdx) >= 3
                    matched1_inliers = matched1(inlierIdx);
                    matched2_inliers = matched2(inlierIdx);
                    tformRel = fitgeotrans(matched2_inliers.Location, matched1_inliers.Location, 'affine');
                else
                    tformRel = tformRansac;
                end
                if rcond(tformRel.T(1:2,1:2)) >= 1e-6 && numel(inlierIdx) >= 10
                    success = true;
                end
            catch
                % affine failed
            end
        end

        % Fallback: similarity transform
        if ~success && size(indexPairs,1) >= 2
            try
                [tformRel, inlierIdx] = estimateGeometricTransform2D(matched2, matched1, ...
                    'similarity', 'MaxNumTrials', 10000, 'Confidence', 99.9, 'MaxDistance', 2);
                if rcond(tformRel.T(1:2,1:2)) >= 1e-6
                    success = true;
                    fprintf("Bild %d: fallback auf similarity\n", i);
                end
            catch
                % similarity failed
            end
        end

        % Fallback: keine Transformation
        if ~success
            warning("Bild %d: Verwende Identity-Transform als Fallback.", i);
            tformRel = affine2d(eye(3));
        end

        % Akkumuliere Transformation
        cumulativeTform.T = tformRel.T * cumulativeTform.T;
        tforms{i} = cumulativeTform;

        alignedImgs{i} = imwarp(currImg, cumulativeTform, 'OutputView', imref2d(size(refImg)), 'FillValues', NaN);

        % Setze dieses Bild als neues "prev"
        prevGray = currGray;
    end
end
