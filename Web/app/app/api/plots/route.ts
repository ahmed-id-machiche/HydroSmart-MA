import { formatPlot } from "@/lib/datasets";
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  let query = supabase
    .from("plots")
    .select(`
      *,
      crops (
        id,
        nom,
        coefficient_kc,
        stade_croissance
      )
    `)
    .order("created_at", { ascending: false });

  if (userId) {
    query = query.eq("user_id", userId);
  }

  const { data, error } = await query;

  if (error) {
    console.error("Supabase plots error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const formattedData = data ? data.map(formatPlot) : [];
  return NextResponse.json(formattedData);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    if (
      !body.userId ||
      !body.cropId ||
      !body.nom ||
      !body.superficie ||
      !body.localisation ||
      !body.typeSol
    ) {
      return NextResponse.json(
        { error: "Champs obligatoires manquants" },
        { status: 400 }
      );
    }

    const nameToSave = body.customCropName
      ? `${body.customCropName}|||${body.nom}`
      : body.nom;

    const { data, error } = await supabase
      .from("plots")
      .insert({
        user_id: body.userId,
        crop_id: body.cropId,
        nom: nameToSave,
        superficie: Number(body.superficie),
        localisation: body.localisation,
        type_sol: body.typeSol,
        latitude: body.latitude !== undefined ? Number(body.latitude) : null,
        longitude: body.longitude !== undefined ? Number(body.longitude) : null,
      })
      .select()
      .single();

    if (error) {
      console.error("Supabase insert plot error:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data, { status: 201 });
  } catch (err) {
    return NextResponse.json(
      { error: "Body JSON invalide ou erreur interne", details: err instanceof Error ? err.message : String(err) },
      { status: 400 }
    );
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();

    if (!body.id) {
      return NextResponse.json(
        { error: "Plot ID is required" },
        { status: 400 }
      );
    }

    const updateData: any = {};
    if (body.cropId !== undefined) updateData.crop_id = body.cropId;
    if (body.nom !== undefined) {
      updateData.nom = body.customCropName
        ? `${body.customCropName}|||${body.nom}`
        : body.nom;
    }
    if (body.superficie !== undefined) updateData.superficie = Number(body.superficie);
    if (body.localisation !== undefined) updateData.localisation = body.localisation;
    if (body.typeSol !== undefined) updateData.type_sol = body.typeSol;
    if (body.latitude !== undefined) updateData.latitude = body.latitude !== null ? Number(body.latitude) : null;
    if (body.longitude !== undefined) updateData.longitude = body.longitude !== null ? Number(body.longitude) : null;

    const { data, error } = await supabase
      .from("plots")
      .update(updateData)
      .eq("id", body.id)
      .select()
      .single();

    if (error) {
      console.error("Supabase update plot error:", error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data);
  } catch (err) {
    return NextResponse.json(
      { error: "Invalid JSON body or internal error", details: err instanceof Error ? err.message : String(err) },
      { status: 400 }
    );
  }
}

export async function DELETE(request: Request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id");

  if (!id) {
    return NextResponse.json({ error: "Plot ID is required" }, { status: 400 });
  }

  // 1. Delete from irrigation_history
  const { error: historyError } = await supabase
    .from("irrigation_history")
    .delete()
    .eq("plot_id", id);

  if (historyError) {
    console.error("Supabase delete irrigation history error:", historyError);
    return NextResponse.json({ error: historyError.message }, { status: 500 });
  }

  // 2. Delete from irrigation_recommendations
  const { error: recError } = await supabase
    .from("irrigation_recommendations")
    .delete()
    .eq("plot_id", id);

  if (recError) {
    console.error("Supabase delete irrigation recommendations error:", recError);
    return NextResponse.json({ error: recError.message }, { status: 500 });
  }

  // 3. Delete from plots
  const { error: plotError } = await supabase
    .from("plots")
    .delete()
    .eq("id", id);

  if (plotError) {
    console.error("Supabase delete plot error:", plotError);
    return NextResponse.json({ error: plotError.message }, { status: 500 });
  }

  return NextResponse.json({ message: "Plot deleted successfully" });
}