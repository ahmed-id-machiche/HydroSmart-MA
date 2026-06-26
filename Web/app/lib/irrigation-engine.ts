import { SOIL_DATASET, CROP_DATASET, normalizeKey } from "./datasets";

type IrrigationInput = {
  et0: number;
  kc: number;
  rainfall: number;
  irrigationEfficiency: number;
  surfaceHectare: number;
  
  // Optional parameters for satellite & soil datasets
  soilType?: string;
  cropName?: string;
  ndvi?: number | null;
  soilMoisture?: number | null;
};

export function generateIrrigationRecommendation(input: IrrigationInput) {
  const { 
    et0, 
    kc, 
    rainfall, 
    irrigationEfficiency, 
    surfaceHectare,
    soilType = "",
    cropName = "",
    ndvi = null,
    soilMoisture = null
  } = input;

  // 1. Resolve Crop properties (default Kc from FAO datasets if available)
  const normCrop = normalizeKey(cropName);
  const cropProp = CROP_DATASET[normCrop];
  
  // 2. Resolve Crop Coefficient (Kc) using Satellite NDVI (live) or fallback
  let resolvedKc = kc;
  let kcSource = "base_db";
  
  if (typeof ndvi === "number" && ndvi !== null) {
    // Standard linear relationship between NDVI and Kc (Kamble et al., 2013)
    const computedKc = 1.25 * ndvi + 0.2;
    resolvedKc = Math.max(0.15, Math.min(1.25, computedKc)); // Cap between 0.15 and 1.25
    kcSource = "satellite_ndvi";
  } else if (cropProp) {
    // If no NDVI, fallback to Mid stage Kc from our crop dataset
    resolvedKc = cropProp.kcMid;
    kcSource = "crop_dataset";
  }

  const etc = et0 * resolvedKc;

  // 3. Resolve Soil properties & Irrigation Efficiency
  const normSoil = normalizeKey(soilType);
  const soilProp = SOIL_DATASET[normSoil];
  const resolvedEfficiency = soilProp ? soilProp.efficiency : irrigationEfficiency;

  // 4. Calculate Net Irrigation Need (using Soil Water Balance or Daily ETc Need)
  let netNeedMm = 0;
  let shouldIrrigate = false;
  let calculationMethod = "daily_etc";
  let taw = 0;
  let raw = 0;
  let depletion = 0;

  if (soilProp && cropProp && typeof soilMoisture === "number" && soilMoisture !== null) {
    // Dynamic Soil Water Balance Model (FAO-56 style)
    calculationMethod = "soil_moisture_balance";
    
    // TAW (Total Available Water in mm) = 1000 * (FC - PWP) * Zr (root depth)
    taw = 1000 * (soilProp.fc - soilProp.pwp) * cropProp.rootDepth;
    // RAW (Readily Available Water in mm) = p (depletion fraction) * TAW
    raw = cropProp.depletionFraction * taw;
    // Dr (Root zone depletion in mm) = 1000 * (FC - SM) * Zr
    depletion = Math.max(1000 * (soilProp.fc - soilMoisture) * cropProp.rootDepth, 0);

    // Irrigate if current depletion exceeds readily available water threshold
    shouldIrrigate = depletion >= raw;
    netNeedMm = shouldIrrigate ? Math.max(depletion - rainfall, 0) : 0;
  } else {
    // Fallback: simple daily crop water need estimation
    netNeedMm = Math.max(etc - rainfall, 0);
    shouldIrrigate = netNeedMm > 1.0; // Irrigate if need is greater than 1mm
  }

  // 5. Calculate Gross Irrigation Need & Water Volume
  const grossNeedMm = netNeedMm / resolvedEfficiency;
  const volumeM3 = grossNeedMm * surfaceHectare * 10;

  // 6. Dynamic Duration & Frequency estimation
  // Assumes a standard drip irrigation emitter flow rate of 4 mm/hour
  const dripAppRateMmPerHour = 4;
  const durationMinutes = shouldIrrigate ? Math.round((grossNeedMm / dripAppRateMmPerHour) * 60) : 0;
  const durationText = shouldIrrigate ? `${durationMinutes} min` : "0 min";

  // Frequency interval calculation (RAW / ETc)
  let intervalDays = 1;
  if (taw > 0 && etc > 0) {
    intervalDays = Math.max(1, Math.floor(raw / etc));
  }
  const frequencyText = shouldIrrigate 
    ? (intervalDays <= 1 ? "every day" : `every ${intervalDays} days`) 
    : "none";

  // 7. Contextual message for the farmer
  let message = "No irrigation is needed today.";
  if (shouldIrrigate) {
    if (calculationMethod === "soil_moisture_balance") {
      message = `Soil water deficit (${depletion.toFixed(1)} mm) exceeds critical threshold (${raw.toFixed(1)} mm). It is recommended to irrigate today with approximately ${volumeM3.toFixed(2)} m³ of water.`;
    } else {
      message = `Crop water need (${etc.toFixed(1)} mm) exceeds rainfall. It is recommended to irrigate today with approximately ${volumeM3.toFixed(2)} m³ of water.`;
    }
  }

  return {
    shouldIrrigate,
    et0: Number(et0.toFixed(2)),
    etc: Number(etc.toFixed(2)),
    rainfall: Number(rainfall.toFixed(2)),
    netNeedMm: Number(netNeedMm.toFixed(2)),
    grossNeedMm: Number(grossNeedMm.toFixed(2)),
    volumeM3: Number(volumeM3.toFixed(2)),
    bestTime: "Early morning or evening",
    message,
    dureeIrrigation: Number((durationMinutes / 60).toFixed(2)), // in hours
    dureeText: durationText,
    frequence: frequencyText,
    metadata: {
      kcSource,
      calculationMethod,
      kc: Number(resolvedKc.toFixed(2)),
      efficiency: resolvedEfficiency,
      ndvi: ndvi,
      soilMoisture: soilMoisture,
      taw: taw > 0 ? Number(taw.toFixed(1)) : null,
      raw: raw > 0 ? Number(raw.toFixed(1)) : null,
      depletion: depletion > 0 ? Number(depletion.toFixed(1)) : null,
    }
  };
}