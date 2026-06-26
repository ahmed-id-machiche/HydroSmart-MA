import { NextResponse } from "next/server";
import { generateIrrigationRecommendation } from "@/lib/irrigation-engine";
import { getOrCreatePolygonId, getLatestNDVI, getSoilData } from "@/lib/agromonitoring";

export async function POST(request: Request) {
  try {
    const body = await request.json();

    let ndvi: number | null = null;
    let soilMoisture: number | null = null;

    // Call Agro Monitoring satellite API if coordinates and plot ID are provided
    if (body.plotId && body.latitude !== undefined && body.longitude !== undefined) {
      try {
        const polyId = await getOrCreatePolygonId(
          body.plotId,
          Number(body.latitude),
          Number(body.longitude)
        );

        // Fetch satellite NDVI & Soil Data
        ndvi = await getLatestNDVI(polyId);
        const soilData = await getSoilData(polyId);
        
        if (soilData) {
          soilMoisture = soilData.moisture;
        }
      } catch (err) {
        console.error("Agro Monitoring fetch failed (falling back to standard PM calculation):", err);
      }
    }

    const recommendation = generateIrrigationRecommendation({
      et0: Number(body.et0),
      kc: Number(body.kc),
      rainfall: Number(body.rainfall),
      irrigationEfficiency: Number(body.irrigationEfficiency),
      surfaceHectare: Number(body.surfaceHectare),
      soilType: body.soilType,
      cropName: body.cropName,
      ndvi: ndvi,
      soilMoisture: soilMoisture,
    });

    return NextResponse.json(recommendation);
  } catch (error) {
    console.error("Recommendation API error:", error);

    return NextResponse.json(
      {
        error: "Erreur lors de la génération de recommandation",
        details: error instanceof Error ? error.message : "Erreur inconnue",
      },
      { status: 500 }
    );
  }
}