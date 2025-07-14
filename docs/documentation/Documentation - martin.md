## Funktionen zur Bildsequenzverarbeitung

### Funktion: `loadImageSequence(folderPath)`

**Beschreibung:**
Lädt alle Bilder eines Verzeichnisses mit den Endungen `.jpg`, `.jpeg`, `.png` oder `.bmp` und extrahiert aus den Dateinamen Metadaten wie Jahr und Monat. Die Bilder werden anhand eines Zeitstempels sortiert, der aus diesen Angaben berechnet wird.

**Input:**
- `folderPath` – Pfad zum Ordner mit den Bildern.

**Output:**
- `imgs` – Zell-Array mit geladenen Bildern (`double`-Format).
- `metas` – Strukturarray mit den Feldern:
  - `name` (Dateiname)
  - `year` (aus Dateiname extrahiert)
  - `month` (aus Dateiname extrahiert)
  - `timestamp` (numerischer Zeitwert zur Sortierung)

---

### Funktion: `preprocessImageSequence(imgs)`

**Beschreibung:**
Registriert die Bilder sequenziell, indem jedes Bild mit dem vorhergehenden abgeglichen wird. Zur Merkmalserkennung werden SURF-Features verwendet (Speeded-Up Robust Features (SURF) Algorithmus). Die Merkmalspunkte werden mittels Nearest-Neighbor-Prinzip gematcht, wobei die SAD (Sum of Absolute Differences) als Ähnlichkeitsmaß herangezogen wird. Die Bilder werden anschließend mittels affiner oder similarity-Transformationen geometrisch ausgerichtet. Die Transformationen werden kumulativ angewendet, sodass sich alle Bilder letztlich auf das erste Bild beziehen.

Zur robusten Schätzung der geometrischen Transformationen werden Ausreißer mit dem MSAC-Algorithmus (M-estimator Sample Consensus) ausgeschlossen (Variante von RANSAC).

**Input:**
- `imgs` – Zell-Array mit RGB-Bildern.

**Output:**
- `alignedImgs` – Zell-Array mit geometrisch ausgerichteten Bildern.
- `tforms` – Zell-Array mit `affine2d`-Transformationsobjekten für jedes Bild.

**Verwendete Toolboxes:**
- **Computer Vision Toolbox**:
  - `detectSURFFeatures`
  - `extractFeatures`
  - `matchFeatures`
  - `estimateGeometricTransform2D`
  - `fitgeotrans`
  - `imwarp`
  - `imref2d`
  - `affine2d`



---

### Funktion: `cropToCommonRegion(imgs)`

**Beschreibung:**
Bestimmt das größte Rechteck ohne NaN-Werte, das in **allen** Bildern vorkommt, und schneidet die Bilder entsprechend zu. Dies ist besonders nach geometrischer Transformation wichtig, um gültige, überlappende Bildbereiche für weitere Analysen zu erhalten.

**Input:**
- `imgs` – Zell-Array mit bereits registrierten RGB-Bildern.

**Output:**
- `croppedImgs` – Zell-Array mit gleichmäßig beschnittenen Bildern (nur gültiger Bereich).


---

### Gesamtüberblick

Die drei Funktionen bilden gemeinsam eine robuste Pipeline zur Vorbereitung von Bildsequenzen für Analysen, beispielsweise zur Bildmittelung, Differenzanalyse oder maschinellem Lernen:

1. `loadImageSequence`: Bilder laden und chronologisch sortieren.
2. `preprocessImageSequence`: Bilder sequenziell geometrisch registrieren.
3. `cropToCommonRegion`: Gemeinsamen gültigen Bildbereich berechnen und zuschneiden.
