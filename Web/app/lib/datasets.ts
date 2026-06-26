export type SoilTypeProperties = {
  fc: number; // Field Capacity (m3/m3)
  pwp: number; // Permanent Wilting Point (m3/m3)
  efficiency: number; // Typical irrigation efficiency (drip is high, flood is low)
};

export type CropProperties = {
  name: string;
  kcIni: number;
  kcMid: number;
  kcEnd: number;
  rootDepth: number; // Root depth in meters (Zr)
  depletionFraction: number; // Critical depletion fraction (p)
};

// Soils typical in agricultural regions of Morocco (Souss-Massa, Doukkala, Gharb)
export const SOIL_DATASET: Record<string, SoilTypeProperties> = {
  sableux: { fc: 0.12, pwp: 0.05, efficiency: 0.90 }, // Sandy (high drip efficiency)
  limoneux: { fc: 0.27, pwp: 0.12, efficiency: 0.85 }, // Loamy
  argileux: { fc: 0.38, pwp: 0.22, efficiency: 0.85 }, // Clayey
  "sablo-limoneux": { fc: 0.18, pwp: 0.08, efficiency: 0.88 }, // Sandy Loam
  "argilo-limoneux": { fc: 0.32, pwp: 0.18, efficiency: 0.85 }, // Clay Loam
  // French translations fallback
  sandy: { fc: 0.12, pwp: 0.05, efficiency: 0.90 },
  loamy: { fc: 0.27, pwp: 0.12, efficiency: 0.85 },
  clayey: { fc: 0.38, pwp: 0.22, efficiency: 0.85 },
};

// Crops typical in Morocco
export const CROP_DATASET: Record<string, CropProperties> = {
  tomate: { name: "Tomate", kcIni: 0.6, kcMid: 1.15, kcEnd: 0.8, rootDepth: 0.6, depletionFraction: 0.4 },
  tomato: { name: "Tomato", kcIni: 0.6, kcMid: 1.15, kcEnd: 0.8, rootDepth: 0.6, depletionFraction: 0.4 },
  
  olivier: { name: "Olivier", kcIni: 0.65, kcMid: 0.7, kcEnd: 0.65, rootDepth: 1.0, depletionFraction: 0.5 },
  olive: { name: "Olive", kcIni: 0.65, kcMid: 0.7, kcEnd: 0.65, rootDepth: 1.0, depletionFraction: 0.5 },
  
  agrumes: { name: "Agrumes", kcIni: 0.7, kcMid: 0.65, kcEnd: 0.7, rootDepth: 0.8, depletionFraction: 0.5 },
  citrus: { name: "Citrus", kcIni: 0.7, kcMid: 0.65, kcEnd: 0.7, rootDepth: 0.8, depletionFraction: 0.5 },
  
  menthe: { name: "Menthe", kcIni: 0.9, kcMid: 1.05, kcEnd: 1.0, rootDepth: 0.3, depletionFraction: 0.35 },
  mint: { name: "Mint", kcIni: 0.9, kcMid: 1.05, kcEnd: 1.0, rootDepth: 0.3, depletionFraction: 0.35 },

  carotte: { name: "Carotte", kcIni: 0.7, kcMid: 1.05, kcEnd: 0.95, rootDepth: 0.4, depletionFraction: 0.35 },
  carrot: { name: "Carrot", kcIni: 0.7, kcMid: 1.05, kcEnd: 0.95, rootDepth: 0.4, depletionFraction: 0.35 },

  "pomme de terre": { name: "Pomme de terre", kcIni: 0.5, kcMid: 1.15, kcEnd: 0.75, rootDepth: 0.5, depletionFraction: 0.35 },
  potato: { name: "Potato", kcIni: 0.5, kcMid: 1.15, kcEnd: 0.75, rootDepth: 0.5, depletionFraction: 0.35 },

  ble: { name: "Blé", kcIni: 0.4, kcMid: 1.15, kcEnd: 0.4, rootDepth: 1.0, depletionFraction: 0.55 },
  wheat: { name: "Wheat", kcIni: 0.4, kcMid: 1.15, kcEnd: 0.4, rootDepth: 1.0, depletionFraction: 0.55 },

  mais: { name: "Maïs", kcIni: 0.4, kcMid: 1.20, kcEnd: 0.6, rootDepth: 0.8, depletionFraction: 0.5 },
  corn: { name: "Corn", kcIni: 0.4, kcMid: 1.20, kcEnd: 0.6, rootDepth: 0.8, depletionFraction: 0.5 },

  oignon: { name: "Oignon", kcIni: 0.7, kcMid: 1.05, kcEnd: 0.95, rootDepth: 0.3, depletionFraction: 0.3 },
  onion: { name: "Onion", kcIni: 0.7, kcMid: 1.05, kcEnd: 0.95, rootDepth: 0.3, depletionFraction: 0.3 },

  fraise: { name: "Fraise", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.75, rootDepth: 0.25, depletionFraction: 0.2 },
  strawberry: { name: "Strawberry", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.75, rootDepth: 0.25, depletionFraction: 0.2 },

  orge: { name: "Orge", kcIni: 0.3, kcMid: 1.15, kcEnd: 0.25, rootDepth: 1.0, depletionFraction: 0.55 },
  barley: { name: "Barley", kcIni: 0.3, kcMid: 1.15, kcEnd: 0.25, rootDepth: 1.0, depletionFraction: 0.55 },

  pommier: { name: "Pommier", kcIni: 0.6, kcMid: 0.95, kcEnd: 0.75, rootDepth: 1.0, depletionFraction: 0.5 },
  apple: { name: "Apple", kcIni: 0.6, kcMid: 0.95, kcEnd: 0.75, rootDepth: 1.0, depletionFraction: 0.5 },

  poirier: { name: "Poirier", kcIni: 0.6, kcMid: 0.95, kcEnd: 0.75, rootDepth: 1.0, depletionFraction: 0.5 },
  pear: { name: "Pear", kcIni: 0.6, kcMid: 0.95, kcEnd: 0.75, rootDepth: 1.0, depletionFraction: 0.5 },

  avocat: { name: "Avocat", kcIni: 0.6, kcMid: 0.85, kcEnd: 0.75, rootDepth: 0.7, depletionFraction: 0.5 },
  avocado: { name: "Avocado", kcIni: 0.6, kcMid: 0.85, kcEnd: 0.75, rootDepth: 0.7, depletionFraction: 0.5 },

  grenadier: { name: "Grenadier", kcIni: 0.5, kcMid: 0.85, kcEnd: 0.6, rootDepth: 0.8, depletionFraction: 0.45 },
  pomegranate: { name: "Pomegranate", kcIni: 0.5, kcMid: 0.85, kcEnd: 0.6, rootDepth: 0.8, depletionFraction: 0.45 },

  figuier: { name: "Figuier", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.65, rootDepth: 1.2, depletionFraction: 0.45 },
  fig: { name: "Fig", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.65, rootDepth: 1.2, depletionFraction: 0.45 },

  vigne: { name: "Vigne", kcIni: 0.3, kcMid: 0.85, kcEnd: 0.45, rootDepth: 1.2, depletionFraction: 0.45 },
  grape: { name: "Grape", kcIni: 0.3, kcMid: 0.85, kcEnd: 0.45, rootDepth: 1.2, depletionFraction: 0.45 },

  pasteque: { name: "Pastèque", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.65, rootDepth: 0.8, depletionFraction: 0.4 },
  watermelon: { name: "Watermelon", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.65, rootDepth: 0.8, depletionFraction: 0.4 },

  melon: { name: "Melon", kcIni: 0.4, kcMid: 0.85, kcEnd: 0.6, rootDepth: 0.8, depletionFraction: 0.4 },

  amandier: { name: "Amandier", kcIni: 0.4, kcMid: 0.9, kcEnd: 0.65, rootDepth: 1.2, depletionFraction: 0.5 },
  almond: { name: "Almond", kcIni: 0.4, kcMid: 0.9, kcEnd: 0.65, rootDepth: 1.2, depletionFraction: 0.5 },

  poivron: { name: "Poivron", kcIni: 0.6, kcMid: 1.05, kcEnd: 0.9, rootDepth: 0.6, depletionFraction: 0.3 },
  pepper: { name: "Pepper", kcIni: 0.6, kcMid: 1.05, kcEnd: 0.9, rootDepth: 0.6, depletionFraction: 0.3 },

  courgette: { name: "Courgette", kcIni: 0.5, kcMid: 0.95, kcEnd: 0.75, rootDepth: 0.6, depletionFraction: 0.4 },
  zucchini: { name: "Zucchini", kcIni: 0.5, kcMid: 0.95, kcEnd: 0.75, rootDepth: 0.6, depletionFraction: 0.4 },

  ail: { name: "Ail", kcIni: 0.5, kcMid: 1.0, kcEnd: 0.7, rootDepth: 0.3, depletionFraction: 0.3 },
  garlic: { name: "Garlic", kcIni: 0.5, kcMid: 1.0, kcEnd: 0.7, rootDepth: 0.3, depletionFraction: 0.3 },

  aubergine: { name: "Aubergine", kcIni: 0.6, kcMid: 1.05, kcEnd: 0.9, rootDepth: 0.7, depletionFraction: 0.45 },
  eggplant: { name: "Eggplant", kcIni: 0.6, kcMid: 1.05, kcEnd: 0.9, rootDepth: 0.7, depletionFraction: 0.45 },

  concombre: { name: "Concombre", kcIni: 0.6, kcMid: 1.0, kcEnd: 0.75, rootDepth: 0.6, depletionFraction: 0.5 },
  cucumber: { name: "Cucumber", kcIni: 0.6, kcMid: 1.0, kcEnd: 0.75, rootDepth: 0.6, depletionFraction: 0.5 },

  laitue: { name: "Laitue", kcIni: 0.7, kcMid: 1.0, kcEnd: 0.95, rootDepth: 0.3, depletionFraction: 0.3 },
  lettuce: { name: "Lettuce", kcIni: 0.7, kcMid: 1.0, kcEnd: 0.95, rootDepth: 0.3, depletionFraction: 0.3 },

  feve: { name: "Fève", kcIni: 0.5, kcMid: 1.15, kcEnd: 1.1, rootDepth: 0.6, depletionFraction: 0.45 },
  "faba bean": { name: "Faba bean", kcIni: 0.5, kcMid: 1.15, kcEnd: 1.1, rootDepth: 0.6, depletionFraction: 0.45 },

  luzerne: { name: "Luzerne", kcIni: 0.4, kcMid: 1.2, kcEnd: 1.15, rootDepth: 1.5, depletionFraction: 0.55 },
  alfalfa: { name: "Alfalfa", kcIni: 0.4, kcMid: 1.2, kcEnd: 1.15, rootDepth: 1.5, depletionFraction: 0.55 }
};

/**
 * Normalizes a text string (e.g. "Sableux" -> "sableux") to lookup in the dataset keys
 */
export function normalizeKey(text: string): string {
  if (!text) return "";
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Remove accents
    .trim();
}

/**
 * Formats a plot, decoding any custom crop embedded in the name
 */
export function formatPlot(plot: any) {
  if (!plot) return null;
  if (plot.nom && plot.nom.includes("|||")) {
    const parts = plot.nom.split("|||");
    const customCropName = parts[0];
    const cleanPlotName = parts[1];

    const normalizedKey = normalizeKey(customCropName);
    const datasetCrop = CROP_DATASET[normalizedKey];
    const kc = datasetCrop ? datasetCrop.kcMid : (plot.crops?.coefficient_kc ?? 0.85);

    return {
      ...plot,
      nom: cleanPlotName,
      crops: {
        ...plot.crops,
        id: plot.crop_id,
        nom: customCropName,
        coefficient_kc: kc,
        stade_croissance: "mi-saison"
      }
    };
  }
  return plot;
}
