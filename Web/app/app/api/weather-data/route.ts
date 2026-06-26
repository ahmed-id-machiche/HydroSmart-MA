import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export async function GET() {
  const { data, error } = await supabase
    .from("weather_data")
    .select(`
      *,
      plots (
        id,
        nom,
        localisation,
        type_sol
      )
    `)
    .order("date", { ascending: false });

  if (error) {
    console.error("Supabase weather_data error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const { data, error } = await supabase
      .from("weather_data")
      .insert({
        plot_id: body.plotId,
        temperature: Number(body.temperature),
        humidite: Number(body.humidite),
        vitesse_vent: Number(body.vitesseVent),
        rayonnement_solaire: Number(body.rayonnementSolaire),
        precipitation: Number(body.precipitation ?? 0),
        date: body.date,
      })
      .select()
      .single();

    if (error) {
      console.error("Supabase insert weather_data error:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data, { status: 201 });
  } catch {
    return NextResponse.json(
      { error: "Body JSON invalide" },
      { status: 400 }
    );
  }
}