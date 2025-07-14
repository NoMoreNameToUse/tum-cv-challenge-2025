clear; clc; close all;

% ⇨ Bildordner wählen und Bilder laden
folderPath = uigetdir(pwd, 'Bildordner wählen');
if folderPath == 0, return; end

% ⇨ Bilder und Metadaten laden
[imgs, metas] = loadImageSequence(folderPath);

% ⇨ Bilder alignen (Rotation und Translation)
fprintf('Schritt 1: Alignment (Rotation & Translation)...\n');
[alignedImgs, tforms] = preprocessImageSequence(imgs);

% ⇨ Gemeinsamer Ausschnitt (automatisch zugeschnitten)
fprintf('Schritt 2: Zuschneiden auf gemeinsamen Bereich...\n');
croppedImgs = cropToCommonRegion(alignedImgs);

% % ⇨ Helligkeits-Normierung NACH dem Alignment
% fprintf('Schritt 3: Helligkeits-Normierung...\n');
% normalizedImgs = percentileNormalization(croppedImgs);

% ⇨ Helligkeits-Normierung NACH dem Alignment
fprintf('Schritt 3: Helligkeits-Normierung...\n');
normalizedImgs = histogramMatchingV(croppedImgs);


% ⇨ Anzeige vorbereiten (jetzt mit 4 Zeilen)
N = numel(imgs);
figure('Name', 'Vollständige Preprocessing Pipeline', 'Position', [50, 50, 350 * N, 1200]);

for i = 1:N
    % Datums-Label
    if isnan(metas(i).month)
        dateStr = sprintf('%04d', metas(i).year);
    else
        dateStr = sprintf('%04d-%02d', metas(i).year, metas(i).month);
    end
    
    % Original
    subplot(4, N, i);
    imshow(imgs{i});
    title(['1. Original: ', dateStr], 'Interpreter', 'none', 'FontSize', 10);
    
    % Registriert
    subplot(4, N, N + i);
    imshow(alignedImgs{i});
    title(['2. Aligned: ', dateStr], 'Interpreter', 'none', 'FontSize', 10);
    
    % Zugeschnitten
    subplot(4, N, 2*N + i);
    imshow(croppedImgs{i});
    title(['3. Cropped: ', dateStr], 'Interpreter', 'none', 'FontSize', 10);
    
    % Helligkeitsnormiert
    subplot(4, N, 3*N + i);
    imshow(normalizedImgs{i});
    title(['4. Normalized: ', dateStr], 'Interpreter', 'none', 'FontSize', 10);
end

sgtitle('Preprocessing Pipeline: Original → Aligned → Cropped → Brightness Normalized', ...
    'FontWeight', 'bold', 'FontSize', 14);

% ⇨ Zusätzliche Analyse: Vergleich vor/nach Normierung
fprintf('\nErstelle Helligkeits-Analyse...\n');
analyzeNormalizationResults(croppedImgs, normalizedImgs, metas);

fprintf('Preprocessing Pipeline abgeschlossen!\n');

function analyzeNormalizationResults(originalImgs, normalizedImgs, metas)
    % Detaillierte Analyse der Normierungsergebnisse
    N = numel(originalImgs);

    figure('Name', 'Helligkeits-Normierung Analyse', 'Position', [200, 200, 400*N, 700]);

    for k = 1:N
      % Datums-Label
     if isnan(metas(k).month)
        dateStr = sprintf('%04d', metas(k).year);
        else
        dateStr = sprintf('%04d-%02d', metas(k).year, metas(k).month);
     end
    
    % Vor Normierung
        subplot(3, N, k);
        imshow(originalImgs{k});
        title(['Vor: ', dateStr], 'FontSize', 10);
    
    % Nach Normierung
        subplot(3, N, N + k);
        imshow(normalizedImgs{k});
        title(['Nach: ', dateStr], 'FontSize', 10);
    
    % Histogramm-Vergleich
        subplot(3, N, 2*N + k);
        hsv_orig = rgb2hsv(originalImgs{k});
        hsv_norm = rgb2hsv(normalizedImgs{k});
    
        hold on;
        histogram(hsv_orig(:,:,3), 30, 'Normalization', 'probability', 'FaceAlpha', 0.5, 'FaceColor', 'red', 'DisplayName', 'Vor');
        histogram(hsv_norm(:,:,3), 30, 'Normalization', 'probability', 'FaceAlpha', 0.5, 'FaceColor', 'blue', 'DisplayName', 'Nach');
        hold off;
    
        xlim([0 1]); ylim([0 0.15]);
        title('V-Kanal Histogramm', 'FontSize', 9);
        xlabel('Helligkeit'); ylabel('Häufigkeit');
        if k == 1, legend('show', 'Location', 'best');
        end
    end

    sgtitle('Helligkeits-Normierung: Vorher vs. Nachher Analyse', 'FontWeight', 'bold');
end

