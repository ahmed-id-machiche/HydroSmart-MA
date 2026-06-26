import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const userId = searchParams.get("userId");

  let query = supabase
    .from("farmers")
    .select("*")
    .order("created_at", { ascending: false });

  if (userId) {
    if (!uuidRegex.test(userId)) {
      return NextResponse.json(
        { error: "userId invalide" },
        { status: 400 }
      );
    }

    query = query.eq("id", userId);
  }

  const { data, error } = await query;

  if (error) {
    console.error("Supabase farmers error:", error);

    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }

  return NextResponse.json(data);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    if (!body.id || !body.email) {
      return NextResponse.json(
        { error: "id et email sont obligatoires" },
        { status: 400 }
      );
    }

    if (!uuidRegex.test(body.id)) {
      return NextResponse.json(
        { error: "id utilisateur invalide" },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("farmers")
      .upsert(
        {
          id: body.id,
          email: body.email,
          full_name: body.fullName ?? null,
          phone: body.phone ?? null,
          region: body.region ?? null,
          role: body.role ?? "farmer",
        },
        {
          onConflict: "id",
        }
      )
      .select()
      .single();

    if (error) {
      console.error("Supabase upsert farmer error:", error);

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

export async function PATCH(request: Request) {
  try {
    const body = await request.json();

    if (!body.id) {
      return NextResponse.json(
        { error: "id utilisateur obligatoire" },
        { status: 400 }
      );
    }

    if (!uuidRegex.test(body.id)) {
      return NextResponse.json(
        { error: "id utilisateur invalide" },
        { status: 400 }
      );
    }

    const updateData: any = {};
    if (body.fullName !== undefined) updateData.full_name = body.fullName;
    if (body.phone !== undefined) updateData.phone = body.phone;
    if (body.region !== undefined) updateData.region = body.region;
    if (body.role !== undefined) updateData.role = body.role;

    const { data, error } = await supabase
      .from("farmers")
      .update(updateData)
      .eq("id", body.id)
      .select()
      .single();

    if (error) {
      console.error("Supabase update farmer error:", error);

      return NextResponse.json(
        { error: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(data);
  } catch {
    return NextResponse.json(
      { error: "Body JSON invalide" },
      { status: 400 }
    );
  }
}