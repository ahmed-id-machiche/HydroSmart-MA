import { formatPlot } from "@/lib/datasets";
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  if (userId && !uuidRegex.test(userId)) {
    return NextResponse.json(
      { error: "userId invalide" },
      { status: 400 }
    );
  }

  let query = supabase
    .from("irrigation_history")
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
      ),
      irrigation_recommendations (
        id,
        quantite_eau,
        duree_irrigation,
        frequence,
        et0,
        etc,
        besoin_net,
        besoin_brut,
        message,
        date
      )
    `)
    .order("date", { ascending: false })
    .order("created_at", { ascending: false });

  if (userId) {
    query = query.eq("plots.user_id", userId);
  }

  const { data, error } = await query;

  if (error) {
    console.error("Supabase irrigation_history error:", error);

    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }

  const filteredData = userId
    ? data?.filter((item) => item.plots !== null)
    : data;

  const formattedData = filteredData?.map((item) => {
    if (item.plots) {
      return {
        ...item,
        plots: formatPlot(item.plots)
      };
    }
    return item;
  });

  return NextResponse.json(formattedData);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    if (
      !body.plotId ||
      body.et0 === undefined ||
      body.etc === undefined ||
      body.quantiteEau === undefined ||
      !body.date
    ) {
      return NextResponse.json(
        { error: "Champs obligatoires manquants" },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("irrigation_history")
      .insert({
        plot_id: body.plotId,
        recommendation_id: body.recommendationId ?? null,
        et0: Number(body.et0),
        etc: Number(body.etc),
        quantite_eau: Number(body.quantiteEau),
        date: body.date,
      })
      .select()
      .single();

    if (error) {
      console.error("Supabase insert irrigation_history error:", error);

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