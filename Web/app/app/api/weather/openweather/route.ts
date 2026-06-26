import { NextResponse } from "next/server";
import { fetchCurrentWeather } from "@/lib/openweather";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);

    const lat = Number(searchParams.get("lat"));
    const lon = Number(searchParams.get("lon"));

    if (!lat || !lon) {
      return NextResponse.json(
        { error: "lat and lon are required" },
        { status: 400 }
      );
    }

    const weather = await fetchCurrentWeather(lat, lon);

    return NextResponse.json(weather);
  } catch (error) {
    console.error("OpenWeather API error:", error);

    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Erreur lors de la récupération météo",
      },
      { status: 500 }
    );
  }
}