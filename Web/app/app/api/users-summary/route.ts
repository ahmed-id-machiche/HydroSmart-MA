import { formatPlot } from "@/lib/datasets";
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

type FarmerRow = {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  region: string | null;
  role: string | null;
  created_at: string;
};

type CropRow = {
  id: string;
  nom: string;
  coefficient_kc: number;
  stade_croissance: string;
};

type PlotRow = {
  id: string;
  user_id: string | null;
  nom: string;
  superficie: number;
  localisation: string;
  type_sol: string;
  latitude: number | null;
  longitude: number | null;
  crops?: CropRow | null;
};

type RecommendationRow = {
  id: string;
  plot_id: string;
  quantite_eau: number;
  duree_irrigation: number;
  frequence: string;
  et0: number;
  etc: number;
  besoin_net: number;
  besoin_brut: number;
  message: string;
  date: string;
  plots?: {
    id: string;
    user_id: string | null;
    nom: string;
    superficie?: number;
    localisation?: string;
    type_sol?: string;
    latitude?: number | null;
    longitude?: number | null;
    crops?: CropRow | null;
  } | null;
};

type HistoryRow = {
  id: string;
  plot_id: string;
  recommendation_id: string | null;
  et0: number;
  etc: number;
  quantite_eau: number;
  date: string;
  plots?: {
    id: string;
    user_id: string | null;
    nom: string;
    superficie?: number;
    localisation?: string;
    type_sol?: string;
    latitude?: number | null;
    longitude?: number | null;
    crops?: CropRow | null;
  } | null;
  irrigation_recommendations?: {
    id: string;
    quantite_eau: number;
    duree_irrigation: number;
    frequence: string;
    et0: number;
    etc: number;
    besoin_net: number;
    besoin_brut: number;
    message: string;
    date: string;
  } | null;
};

export async function GET() {
  const { data: farmers, error: farmersError } = await supabase
    .from("farmers")
    .select("*")
    .order("created_at", { ascending: false });

  if (farmersError) {
    console.error("Supabase users-summary farmers error:", farmersError);

    return NextResponse.json(
      { error: farmersError.message },
      { status: 500 }
    );
  }

  const { data: plots, error: plotsError } = await supabase
    .from("plots")
    .select(`
      id,
      user_id,
      nom,
      superficie,
      localisation,
      type_sol,
      latitude,
      longitude,
      crops (
        id,
        nom,
        coefficient_kc,
        stade_croissance
      )
    `)
    .not("user_id", "is", null)
    .order("created_at", { ascending: false });

  if (plotsError) {
    console.error("Supabase users-summary plots error:", plotsError);

    return NextResponse.json(
      { error: plotsError.message },
      { status: 500 }
    );
  }

  const { data: recommendations, error: recommendationsError } =
    await supabase
      .from("irrigation_recommendations")
      .select(`
        id,
        plot_id,
        quantite_eau,
        duree_irrigation,
        frequence,
        et0,
        etc,
        besoin_net,
        besoin_brut,
        message,
        date,
        plots (
          id,
          user_id,
          nom,
          superficie,
          localisation,
          type_sol,
          latitude,
          longitude,
          crops (
            id,
            nom,
            coefficient_kc,
            stade_croissance
          )
        )
      `)
      .order("date", { ascending: false });

  if (recommendationsError) {
    console.error(
      "Supabase users-summary recommendations error:",
      recommendationsError
    );

    return NextResponse.json(
      { error: recommendationsError.message },
      { status: 500 }
    );
  }

  const { data: history, error: historyError } = await supabase
    .from("irrigation_history")
    .select(`
      id,
      plot_id,
      recommendation_id,
      et0,
      etc,
      quantite_eau,
      date,
      plots (
        id,
        user_id,
        nom,
        superficie,
        localisation,
        type_sol,
        latitude,
        longitude,
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
    .order("date", { ascending: false });

  if (historyError) {
    console.error("Supabase users-summary history error:", historyError);

    return NextResponse.json(
      { error: historyError.message },
      { status: 500 }
    );
  }

  const typedFarmers = (farmers ?? []) as unknown as FarmerRow[];
  const typedPlots = (plots ?? []) as unknown as PlotRow[];
  const typedRecommendations =
    (recommendations ?? []) as unknown as RecommendationRow[];
  const typedHistory = (history ?? []) as unknown as HistoryRow[];

  const farmerMap = new Map<string, FarmerRow>();

  for (const farmer of typedFarmers) {
    farmerMap.set(farmer.id, farmer);
  }

  const summaryMap = new Map<
    string,
    {
      userId: string;
      farmer: FarmerRow | null;
      fieldsCount: number;
      recommendationsCount: number;
      totalWater: number;
      averageEt0: number;
      averageEtc: number;
      et0Sum: number;
      etcSum: number;
      latestRecommendationDate: string | null;
      fields: PlotRow[];
      recommendations: RecommendationRow[];
      history: HistoryRow[];
    }
  >();

  function ensureUserSummary(userId: string) {
    if (!summaryMap.has(userId)) {
      summaryMap.set(userId, {
        userId,
        farmer: farmerMap.get(userId) ?? null,
        fieldsCount: 0,
        recommendationsCount: 0,
        totalWater: 0,
        averageEt0: 0,
        averageEtc: 0,
        et0Sum: 0,
        etcSum: 0,
        latestRecommendationDate: null,
        fields: [],
        recommendations: [],
        history: [],
      });
    }

    return summaryMap.get(userId)!;
  }

  for (const farmer of typedFarmers) {
    ensureUserSummary(farmer.id);
  }

  for (const plot of typedPlots) {
    if (!plot.user_id) continue;

    const userSummary = ensureUserSummary(plot.user_id);

    userSummary.fieldsCount += 1;
    userSummary.fields.push(plot);
  }

  for (const recommendation of typedRecommendations) {
    const userId = recommendation.plots?.user_id;

    if (!userId) continue;

    const userSummary = ensureUserSummary(userId);

    userSummary.recommendationsCount += 1;
    userSummary.totalWater += Number(recommendation.quantite_eau || 0);
    userSummary.et0Sum += Number(recommendation.et0 || 0);
    userSummary.etcSum += Number(recommendation.etc || 0);
    userSummary.recommendations.push(recommendation);

    if (
      !userSummary.latestRecommendationDate ||
      recommendation.date > userSummary.latestRecommendationDate
    ) {
      userSummary.latestRecommendationDate = recommendation.date;
    }
  }

  for (const item of typedHistory) {
    const userId = item.plots?.user_id;

    if (!userId) continue;

    const userSummary = ensureUserSummary(userId);

    userSummary.history.push(item);
  }

  const summary = Array.from(summaryMap.values()).map((item) => {
    const averageEt0 =
      item.recommendationsCount > 0
        ? item.et0Sum / item.recommendationsCount
        : 0;

    const averageEtc =
      item.recommendationsCount > 0
        ? item.etcSum / item.recommendationsCount
        : 0;

    return {
      userId: item.userId,
      farmer: item.farmer,
      farmerName:
        item.farmer?.full_name ||
        item.farmer?.email ||
        `Agriculteur ${item.userId.slice(0, 8)}`,
      farmerEmail: item.farmer?.email ?? null,
      farmerPhone: item.farmer?.phone ?? null,
      farmerRegion: item.farmer?.region ?? null,
      farmerRole: item.farmer?.role ?? "farmer",
      fieldsCount: item.fieldsCount,
      recommendationsCount: item.recommendationsCount,
      totalWater: Number(item.totalWater.toFixed(2)),
      averageEt0: Number(averageEt0.toFixed(2)),
      averageEtc: Number(averageEtc.toFixed(2)),
      latestRecommendationDate: item.latestRecommendationDate,
      fields: item.fields,
      recommendations: item.recommendations.slice(0, 10),
      history: item.history.slice(0, 10),
    };
  });

  summary.sort((a, b) => {
    if (!a.latestRecommendationDate && !b.latestRecommendationDate) {
      return a.farmerName.localeCompare(b.farmerName);
    }

    if (!a.latestRecommendationDate) return 1;
    if (!b.latestRecommendationDate) return -1;

    return b.latestRecommendationDate.localeCompare(a.latestRecommendationDate);
  });

  return NextResponse.json(summary);
}