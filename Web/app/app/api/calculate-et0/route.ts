import { NextResponse } from "next/server";
import { calculateET0 } from "@/lib/et0-calculator";

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const et0 = calculateET0({
      tMin: body.tMin,
      tMax: body.tMax,
      tMean: body.tMean,
      humidity: body.humidity,
      windSpeed: body.windSpeed,
      solarRadiation: body.solarRadiation,
    });

    return NextResponse.json({
      et0,
      unit: "mm/day",
    });
  } catch {
    return NextResponse.json(
      { error: "Erreur lors du calcul ET0" },
      { status: 500 }
    );
  }
}