clear; clc; close all;

% ⇨ Bildordner wählen und Bilder laden
folderPath = uigetdir(pwd, 'Bildordner wählen');
if folderPath == 0, return; end

% ⇨ Bilder und Metadaten laden
[imgs, metas] = loadImageSequence(folderPath);

% ⇨ Bilder alignen
[alignedImgs, tforms] = preprocessImageSequence(imgs);

% ⇨ Gemeinsamer Ausschnitt (automatisch zugeschnitten)
croppedImgs = cropToCommonRegion(alignedImgs);

% ⇨ Anzeige vorbereiten
N = numel(imgs);
figure('Name', 'Preprocessing Pipeline', 'Position', [100, 100, 400 * N, 1000]);

for i = 1:N
    % Datums-Label
    if isnan(metas(i).month)
        dateStr = sprintf('%04d', metas(i).year);
    else
        dateStr = sprintf('%04d-%02d', metas(i).year, metas(i).month);
    end

    % Original
    subplot(3, N, i);
    imshow(imgs{i});
    title(['Original: ', dateStr], 'Interpreter', 'none');

    % Registriert
    subplot(3, N, N + i);
    imshow(alignedImgs{i});
    title(['Aligned: ', dateStr], 'Interpreter', 'none');

    % Zugeschnitten
    subplot(3, N, 2*N + i);
    imshow(croppedImgs{i});
    title(['Zugeschnitten: ', dateStr], 'Interpreter', 'none');
end

sgtitle('Original → Registriert → Zugeschnitten', 'FontWeight', 'bold');
