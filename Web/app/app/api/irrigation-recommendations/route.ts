import { formatPlot } from "@/lib/datasets";
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  let query = supabase
    .from("irrigation_recommendations")
    .select(`
      *,
      plots (
        id,
        user_id,
        nom,
        superficie,
        localisation,
        type_sol,
        crops (
          id,
          nom,
          coefficient_kc,
          stade_croissance
        )
      )
    `)
    .order("date", { ascending: false });

  if (userId) {
    query = query.eq("plots.user_id", userId);
  }

  const { data, error } = await query;

  if (error) {
    console.error("Supabase irrigation_recommendations error:", error);

    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }

  const filteredData = userId
    ? data?.filter((item) => item.plots !== null)
    : data;

  return NextResponse.json(filteredData);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    if (
      !body.plotId ||
      body.quantiteEau === undefined ||
      body.dureeIrrigation === undefined ||
      !body.frequence ||
      body.et0 === undefined ||
      body.etc === undefined ||
      body.besoinNet === undefined ||
      body.besoinBrut === undefined ||
      !body.message ||
      !body.date
    ) {
      return NextResponse.json(
        { error: "Champs obligatoires manquants" },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("irrigation_recommendations")
      .insert({
        plot_id: body.plotId,
        quantite_eau: Number(body.quantiteEau),
        duree_irrigation: Number(body.dureeIrrigation),
        frequence: body.frequence,
        et0: Number(body.et0),
        etc: Number(body.etc),
        besoin_net: Number(body.besoinNet),
        besoin_brut: Number(body.besoinBrut),
        message: body.message,
        date: body.date,
      })
      .select()
      .single();

    if (error) {
      console.error("Supabase insert irrigation_recommendations error:", error);

      return NextResponse.json(
        { error: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(data, { status: 201 });
  } catch {
    return NextResponse.json(
      { error: "Body JSON invalide" },
      { status: 400 }
    );
  }
}