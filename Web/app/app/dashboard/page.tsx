"use client";

import Sidebar from "@/components/Sidebar";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const chartBlue = "#2563eb";
const chartGreen = "#059669";

type Crop = {
  id: string;
  nom: string;
  coefficient_kc: number;
  stade_croissance: string;
};

type Farmer = {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  region: string | null;
  role: string | null;
  created_at: string;
};

type UserField = {
  id: string;
  user_id: string;
  nom: string;
  superficie: number;
  localisation: string;
  type_sol: string;
  latitude?: number | null;
  longitude?: number | null;
  crops?: Crop | null;
};

type FarmerPlotInfo = {
  id: string;
  user_id: string | null;
  nom: string;
  superficie?: number;
  localisation?: string;
  type_sol?: string;
  latitude?: number | null;
  longitude?: number | null;
  crops?: Crop | null;
};

type FarmerRecommendation = {
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
  plots?: FarmerPlotInfo | FarmerPlotInfo[] | null;
};

type FarmerHistory = {
  id: string;
  plot_id: string;
  recommendation_id: string | null;
  et0: number;
  etc: number;
  quantite_eau: number;
  date: string;
  plots?: FarmerPlotInfo | FarmerPlotInfo[] | null;
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

type UserSummary = {
  userId: string;
  farmer: Farmer | null;
  farmerName: string;
  farmerEmail: string | null;
  farmerPhone: string | null;
  farmerRegion: string | null;
  farmerRole: string;
  fieldsCount: number;
  recommendationsCount: number;
  totalWater: number;
  averageEt0: number;
  averageEtc: number;
  latestRecommendationDate: string | null;
  fields?: UserField[];
  recommendations?: FarmerRecommendation[];
  history?: FarmerHistory[];
};

type ActiveSection = "overview" | "fields" | "recommendations" | "history";

export default function DashboardPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string>("all");
  const [activeSection, setActiveSection] = useState<ActiveSection>("overview");
  const [loading, setLoading] = useState(true);
  const [selectedDrawerField, setSelectedDrawerField] = useState<UserField | null>(null);

  const drawerInfo = useMemo(() => {
    if (!selectedDrawerField) return null;
    
    const recs = users
      .flatMap((u) => safeRecommendations(u.recommendations))
      .filter((r) => r.plot_id === selectedDrawerField.id)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
      
    const hist = users
      .flatMap((u) => safeHistory(u.history))
      .filter((h) => h.plot_id === selectedDrawerField.id)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    return {
      latestRecommendation: recs[0] || null,
      history: hist,
    };
  }, [selectedDrawerField, users]);

  useEffect(() => {
    async function fetchDashboardData() {
      try {
        const res = await fetch("/api/users-summary");
        const data = await res.json();

        const usersData = Array.isArray(data) ? data : [];
        setUsers(usersData);
      } catch (error) {
        console.error("Admin dashboard fetch error:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchDashboardData();
  }, []);

  const filteredUsers = useMemo(() => {
    if (selectedUserId === "all") return users;
    return users.filter((user) => user.userId === selectedUserId);
  }, [users, selectedUserId]);

  const selectedUser =
    selectedUserId === "all"
      ? null
      : users.find((user) => user.userId === selectedUserId) ?? null;

  const selectedFields =
    selectedUserId === "all"
      ? filteredUsers.flatMap((user) => safeFields(user.fields))
      : safeFields(selectedUser?.fields);

  const selectedRecommendations =
    selectedUserId === "all"
      ? filteredUsers.flatMap((user) =>
          safeRecommendations(user.recommendations)
        )
      : safeRecommendations(selectedUser?.recommendations);

  const selectedHistory =
    selectedUserId === "all"
      ? filteredUsers.flatMap((user) => safeHistory(user.history))
      : safeHistory(selectedUser?.history);

  const totalFarmers = filteredUsers.length;

  const totalFields = filteredUsers.reduce(
    (sum, user) => sum + Number(user.fieldsCount || 0),
    0
  );

  const totalRecommendations = filteredUsers.reduce(
    (sum, user) => sum + Number(user.recommendationsCount || 0),
    0
  );

  const totalWater = filteredUsers.reduce(
    (sum, user) => sum + Number(user.totalWater || 0),
    0
  );

  const averageEt0 =
    totalRecommendations > 0
      ? filteredUsers.reduce(
          (sum, user) =>
            sum +
            Number(user.averageEt0 || 0) *
              Number(user.recommendationsCount || 0),
          0
        ) / totalRecommendations
      : 0;

  const averageEtc =
    totalRecommendations > 0
      ? filteredUsers.reduce(
          (sum, user) =>
            sum +
            Number(user.averageEtc || 0) *
              Number(user.recommendationsCount || 0),
          0
        ) / totalRecommendations
      : 0;

  const smallWaterChartData = useMemo(() => {
    return selectedRecommendations
      .slice()
      .reverse()
      .slice(-7)
      .map((rec) => ({
        date: rec.date,
        eau: Number(rec.quantite_eau || 0),
      }));
  }, [selectedRecommendations]);

  const smallEtChartData = useMemo(() => {
    return selectedRecommendations
      .slice()
      .reverse()
      .slice(-7)
      .map((rec) => ({
        date: rec.date,
        et0: Number(rec.et0 || 0),
        etc: Number(rec.etc || 0),
      }));
  }, [selectedRecommendations]);

  const farmerRankingData = useMemo(() => {
    return filteredUsers.map((user) => ({
      name: user.farmerName || shortUserId(user.userId),
      eau: Number(user.totalWater || 0),
      parcelles: Number(user.fieldsCount || 0),
    }));
  }, [filteredUsers]);

  const latestRecommendation = selectedRecommendations[0];
  const fieldsWithGps = selectedFields.filter(
    (field) =>
      typeof field.latitude === "number" &&
      typeof field.longitude === "number" &&
      field.latitude !== 0 &&
      field.longitude !== 0
  );

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-lg font-medium text-slate-600">
          Loading admin dashboard...
        </p>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="flex">
        <Sidebar />

        <section className="flex-1 p-5">
          <div className="space-y-5">
            <header className="rounded-3xl bg-gradient-to-r from-emerald-700 to-emerald-500 p-5 text-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-wide text-emerald-100">
                    HydroSmart-MA
                  </p>
                  <h1 className="mt-1 text-3xl font-bold">
                    Admin Irrigation Dashboard
                  </h1>
                  <p className="mt-1 text-sm text-emerald-50">
                    Filter a farmer and view their data directly.
                  </p>
                </div>

                <div className="flex flex-wrap items-end gap-3 w-full md:w-auto">
                  <div className="flex-1 min-w-[240px] md:flex-initial">
                    <label className="text-xs font-medium text-emerald-50">
                      Farmer
                    </label>
                    <select
                      value={selectedUserId}
                      onChange={(event) => {
                        setSelectedUserId(event.target.value);
                        setActiveSection("overview");
                      }}
                      className="mt-1 w-full rounded-2xl border border-white/30 bg-white px-4 py-3 text-sm font-semibold text-slate-800 outline-none"
                    >
                      <option value="all">All farmers</option>
                      {users.map((user) => (
                        <option key={user.userId} value={user.userId}>
                          {user.farmerName || shortUserId(user.userId)}
                          {user.farmerEmail ? ` - ${user.farmerEmail}` : ""}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="flex-1 min-w-[180px] md:flex-initial">
                    <label className="text-xs font-medium text-emerald-50">
                      Section
                    </label>
                    <select
                      value={activeSection}
                      onChange={(event) =>
                        setActiveSection(event.target.value as ActiveSection)
                      }
                      className="mt-1 w-full rounded-2xl border border-white/30 bg-white px-4 py-3 text-sm font-semibold text-slate-800 outline-none"
                    >
                      <option value="overview">Overview</option>
                      <option value="fields">Fields</option>
                      <option value="recommendations">Recommendations</option>
                      <option value="history">History</option>
                    </select>
                  </div>

                  <div className="flex gap-2 w-full md:w-auto mt-2 md:mt-0">
                    <button
                      onClick={() => {
                        if (activeSection === "fields" || activeSection === "overview") {
                          const headers = ["Name", "Crop", "Surface", "Location", "Soil", "Latitude", "Longitude"];
                          const rows = selectedFields.map((field) => [
                            field.nom,
                            field.crops?.nom ?? "-",
                            `${field.superficie} ha`,
                            field.localisation,
                            field.type_sol,
                            field.latitude ?? "",
                            field.longitude ?? "",
                          ]);
                          exportToCsv("fields_export.csv", headers, rows);
                        }
                        if (activeSection === "recommendations" || activeSection === "overview") {
                          const headers = ["Date", "Plot", "Crop", "ET0", "ETc", "Water (m3)", "Frequency", "Duration (mins)", "Message"];
                          const rows = selectedRecommendations.map((rec) => [
                            rec.date,
                            getPlotName(rec.plots),
                            getCropName(rec.plots),
                            Number(rec.et0 || 0).toFixed(2),
                            Number(rec.etc || 0).toFixed(2),
                            Number(rec.quantite_eau || 0).toFixed(2),
                            rec.frequence ?? "-",
                            rec.duree_irrigation ?? "-",
                            rec.message ?? "",
                          ]);
                          exportToCsv("recommendations_export.csv", headers, rows);
                        }
                        if (activeSection === "history" || activeSection === "overview") {
                          const headers = ["Date", "Plot", "Crop", "ET0", "ETc", "Water (m3)", "Message"];
                          const rows = selectedHistory.map((item) => [
                            item.date,
                            getPlotName(item.plots),
                            getCropName(item.plots),
                            Number(item.et0 || 0).toFixed(2),
                            Number(item.etc || 0).toFixed(2),
                            Number(item.quantite_eau || 0).toFixed(2),
                            item.irrigation_recommendations?.message ?? "History saved.",
                          ]);
                          exportToCsv("history_export.csv", headers, rows);
                        }
                      }}
                      className="flex-1 md:flex-initial rounded-2xl border border-white/30 bg-white/20 px-4 py-3 text-sm font-semibold text-white backdrop-blur-sm hover:bg-white/35 transition outline-none"
                    >
                      Export CSV
                    </button>
                    <button
                      onClick={() => {
                        if (activeSection === "overview") {
                          exportToJson("dashboard_all_export.json", {
                            fields: selectedFields,
                            recommendations: selectedRecommendations,
                            history: selectedHistory,
                          });
                        } else if (activeSection === "fields") {
                          exportToJson("fields_export.json", selectedFields);
                        } else if (activeSection === "recommendations") {
                          exportToJson("recommendations_export.json", selectedRecommendations);
                        } else if (activeSection === "history") {
                          exportToJson("history_export.json", selectedHistory);
                        }
                      }}
                      className="flex-1 md:flex-initial rounded-2xl border border-white/30 bg-white/20 px-4 py-3 text-sm font-semibold text-white backdrop-blur-sm hover:bg-white/35 transition outline-none"
                    >
                      Export JSON
                    </button>
                  </div>
                </div>
              </div>
            </header>

            <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
              <CompactStatCard
                title="Farmers"
                value={totalFarmers}
                subtitle={selectedUserId === "all" ? "Total displayed" : "Selected"}
              />
              <CompactStatCard
                title="Plots"
                value={totalFields}
                subtitle={`${fieldsWithGps.length} with GPS`}
              />
              <CompactStatCard
                title="Recommendations"
                value={totalRecommendations}
                subtitle="Generated calculations"
              />
              <CompactStatCard
                title="Total Water"
                value={`${totalWater.toFixed(1)} m³`}
                subtitle="Recommended volume"
              />
              <CompactStatCard
                title="ET0 / ETc"
                value={`${averageEt0.toFixed(1)} / ${averageEtc.toFixed(1)}`}
                subtitle="Averages"
              />
            </section>

            {activeSection === "overview" && (
              <section className="grid gap-5 xl:grid-cols-3">
                <div className="space-y-5 xl:col-span-2">
                  <div className="grid gap-5 lg:grid-cols-2">
                    <DashboardCard title="Water trend" subtitle="Latest recommendations">
                      {smallWaterChartData.length > 0 ? (
                        <ResponsiveContainer width="100%" height={180}>
                          <BarChart data={smallWaterChartData}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 11 }} />
                            <Tooltip />
                            <Bar
                              dataKey="eau"
                              fill={chartBlue}
                              radius={[8, 8, 0, 0]}
                            />
                          </BarChart>
                        </ResponsiveContainer>
                      ) : (
                        <SmallEmpty />
                      )}
                    </DashboardCard>

                    <DashboardCard title="ET0 / ETc" subtitle="Recent evolution">
                      {smallEtChartData.length > 0 ? (
                        <ResponsiveContainer width="100%" height={180}>
                          <LineChart data={smallEtChartData}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 11 }} />
                            <Tooltip />
                            <Line
                              type="monotone"
                              dataKey="et0"
                              stroke={chartBlue}
                              strokeWidth={2}
                            />
                            <Line
                              type="monotone"
                              dataKey="etc"
                              stroke={chartGreen}
                              strokeWidth={2}
                            />
                          </LineChart>
                        </ResponsiveContainer>
                      ) : (
                        <SmallEmpty />
                      )}
                    </DashboardCard>
                  </div>

                  <div className="grid gap-5 lg:grid-cols-2">
                    <DashboardCard
                      title="Plots Map"
                      subtitle="Satellite view"
                      noPadding
                    >
                      <FieldsMap
                        fields={selectedFields}
                        compact
                        onSelectField={setSelectedDrawerField}
                      />
                    </DashboardCard>

                    <DashboardCard title="Top water consumption" subtitle="Per farmer">
                      {farmerRankingData.length > 0 ? (
                        <ResponsiveContainer width="100%" height={210}>
                          <BarChart data={farmerRankingData}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 11 }} />
                            <Tooltip />
                            <Bar
                              dataKey="eau"
                              fill={chartGreen}
                              radius={[8, 8, 0, 0]}
                            />
                          </BarChart>
                        </ResponsiveContainer>
                      ) : (
                        <SmallEmpty />
                      )}
                    </DashboardCard>
                  </div>
                </div>

                <aside className="space-y-5">
                  <DashboardCard title="Selected farmer" subtitle="Résumé rapide">
                    {selectedUserId === "all" ? (
                      <div className="rounded-2xl bg-emerald-50 p-4">
                        <p className="text-sm font-semibold text-emerald-900">
                          All farmers
                        </p>
                        <p className="mt-1 text-sm text-emerald-700">
                          The displayed statistics are global.
                        </p>
                      </div>
                    ) : selectedUser ? (
                      <div className="space-y-3">
                        <div className="rounded-2xl bg-emerald-50 p-4">
                          <p className="font-bold text-emerald-950">
                            {selectedUser.farmerName}
                          </p>
                          <p className="mt-1 text-sm text-emerald-700">
                            {selectedUser.farmerEmail ?? "Email unavailable"}
                          </p>
                        </div>

                        <InfoLine label="Phone" value={selectedUser.farmerPhone ?? "-"} />
                        <InfoLine
                          label="Region"
                          value={selectedUser.farmerRegion ?? "From GPS/plot"}
                        />
                        <InfoLine label="Plots" value={`${selectedUser.fieldsCount}`} />
                        <InfoLine
                          label="Recommendations"
                          value={`${selectedUser.recommendationsCount}`}
                        />
                      </div>
                    ) : (
                      <p className="text-sm text-slate-500">No farmer.</p>
                    )}
                  </DashboardCard>

                  <DashboardCard title="Latest recommendation" subtitle="Latest decision">
                    {latestRecommendation ? (
                      <div className="space-y-3">
                        <div>
                          <p className="font-semibold text-slate-900">
                            {getPlotName(latestRecommendation.plots)}
                          </p>
                          <p className="text-sm text-slate-500">
                            {getCropName(latestRecommendation.plots)} •{" "}
                            {latestRecommendation.date}
                          </p>
                        </div>

                        <div className="rounded-2xl bg-blue-50 p-4">
                          <p className="text-2xl font-bold text-blue-700">
                            {Number(latestRecommendation.quantite_eau || 0).toFixed(2)} m³
                          </p>
                          <p className="mt-1 text-sm text-blue-700">
                            {latestRecommendation.frequence ?? "-"}
                          </p>
                        </div>

                        <p className="text-sm text-slate-600">
                          {latestRecommendation.message ?? "Recommendation generated."}
                        </p>
                      </div>
                    ) : (
                      <SmallEmpty />
                    )}
                  </DashboardCard>
                </aside>
              </section>
            )}

            {activeSection === "fields" && (
              <section className="grid gap-5 xl:grid-cols-2">
                <DashboardCard title="Map" subtitle="Plots location" noPadding>
                  <FieldsMap
                    fields={selectedFields}
                    onSelectField={setSelectedDrawerField}
                  />
                </DashboardCard>

                <DashboardCard
                  title="Fields table"
                  subtitle="Filtered plots"
                  actions={
                    <div className="flex gap-2">
                      <button
                        onClick={() => {
                          const headers = ["Name", "Crop", "Surface", "Location", "Soil", "Latitude", "Longitude"];
                          const rows = selectedFields.map((field) => [
                            field.nom,
                            field.crops?.nom ?? "-",
                            `${field.superficie} ha`,
                            field.localisation,
                            field.type_sol,
                            field.latitude ?? "",
                            field.longitude ?? "",
                          ]);
                          exportToCsv("fields_export.csv", headers, rows);
                        }}
                        className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                      >
                        Export CSV
                      </button>
                      <button
                        onClick={() => exportToJson("fields_export.json", selectedFields)}
                        className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                      >
                        Export JSON
                      </button>
                    </div>
                  }
                >
                  <DataTable
                    empty="No plots found."
                    headers={["Name", "Crop", "Surface", "Location", "Soil", "GPS"]}
                    rows={selectedFields.map((field) => [
                      field.nom,
                      field.crops?.nom ?? "-",
                      `${field.superficie} ha`,
                      field.localisation,
                      field.type_sol,
                      field.latitude && field.longitude ? "Yes" : "No",
                    ])}
                  />
                </DashboardCard>
              </section>
            )}

            {activeSection === "recommendations" && (
              <DashboardCard
                title="Recommendations"
                subtitle="Latest filtered recommendations"
                actions={
                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        const headers = ["Date", "Plot", "Crop", "ET0", "ETc", "Water (m3)", "Frequency", "Duration (mins)", "Message"];
                        const rows = selectedRecommendations.map((rec) => [
                          rec.date,
                          getPlotName(rec.plots),
                          getCropName(rec.plots),
                          Number(rec.et0 || 0).toFixed(2),
                          Number(rec.etc || 0).toFixed(2),
                          Number(rec.quantite_eau || 0).toFixed(2),
                          rec.frequence ?? "-",
                          rec.duree_irrigation ?? "-",
                          rec.message ?? "",
                        ]);
                        exportToCsv("recommendations_export.csv", headers, rows);
                      }}
                      className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                    >
                      Export CSV
                    </button>
                    <button
                      onClick={() => exportToJson("recommendations_export.json", selectedRecommendations)}
                      className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                    >
                      Export JSON
                    </button>
                  </div>
                }
              >
                <DataTable
                  empty="No recommendations found."
                  headers={["Date", "Plot", "Crop", "ET0", "ETc", "Water", "Frequency"]}
                  rows={selectedRecommendations.map((rec) => [
                    rec.date,
                    getPlotName(rec.plots),
                    getCropName(rec.plots),
                    Number(rec.et0 || 0).toFixed(2),
                    Number(rec.etc || 0).toFixed(2),
                    `${Number(rec.quantite_eau || 0).toFixed(2)} m³`,
                    rec.frequence ?? "-",
                  ])}
                />

                <div className="mt-5 grid gap-3 md:grid-cols-2">
                  {selectedRecommendations.slice(0, 4).map((rec) => (
                    <div
                      key={rec.id}
                      className="rounded-2xl border border-slate-100 bg-slate-50 p-4"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="font-semibold text-slate-900">
                            {getPlotName(rec.plots)}
                          </p>
                          <p className="text-sm text-slate-500">{rec.date}</p>
                        </div>
                        <span className="rounded-full bg-emerald-700 px-3 py-1 text-sm font-semibold text-white">
                          {Number(rec.quantite_eau || 0).toFixed(1)} m³
                        </span>
                      </div>
                      <p className="mt-3 text-sm text-slate-600">
                        {rec.message ?? "Recommendation generated."}
                      </p>
                    </div>
                  ))}
                </div>
              </DashboardCard>
            )}

            {activeSection === "history" && (
              <DashboardCard
                title="Irrigation history"
                subtitle="Filtered history"
                actions={
                  <div className="flex gap-2">
                    <button
                      onClick={() => {
                        const headers = ["Date", "Plot", "Crop", "ET0", "ETc", "Water (m3)", "Message"];
                        const rows = selectedHistory.map((item) => [
                          item.date,
                          getPlotName(item.plots),
                          getCropName(item.plots),
                          Number(item.et0 || 0).toFixed(2),
                          Number(item.etc || 0).toFixed(2),
                          Number(item.quantite_eau || 0).toFixed(2),
                          item.irrigation_recommendations?.message ?? "History saved.",
                        ]);
                        exportToCsv("history_export.csv", headers, rows);
                      }}
                      className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                    >
                      Export CSV
                    </button>
                    <button
                      onClick={() => exportToJson("history_export.json", selectedHistory)}
                      className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                    >
                      Export JSON
                    </button>
                  </div>
                }
              >
                <DataTable
                  empty="No history found."
                  headers={["Date", "Plot", "Crop", "ET0", "ETc", "Water"]}
                  rows={selectedHistory.map((item) => [
                    item.date,
                    getPlotName(item.plots),
                    getCropName(item.plots),
                    Number(item.et0 || 0).toFixed(2),
                    Number(item.etc || 0).toFixed(2),
                    `${Number(item.quantite_eau || 0).toFixed(2)} m³`,
                  ])}
                />
              </DashboardCard>
            )}
          </div>
        </section>
      </div>

      {selectedDrawerField && drawerInfo && (
        <div className="fixed inset-0 z-[999] flex justify-end">
          <style>{`
            @keyframes slideIn {
              from { transform: translateX(100%); }
              to { transform: translateX(0); }
            }
            .drawer-slide-in {
              animation: slideIn 0.3s ease-out forwards;
            }
          `}</style>
          <div
            onClick={() => setSelectedDrawerField(null)}
            className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
          />
          <div className="relative z-10 w-full max-w-lg h-full bg-white shadow-2xl flex flex-col drawer-slide-in overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100 bg-gradient-to-r from-emerald-800 to-emerald-600 text-white">
              <div>
                <span className="text-xs font-semibold uppercase tracking-wider text-emerald-100">
                  Plot Profile
                </span>
                <h2 className="text-xl font-bold mt-0.5">{selectedDrawerField.nom}</h2>
              </div>
              <button
                onClick={() => setSelectedDrawerField(null)}
                className="rounded-full p-2 hover:bg-white/10 transition-colors text-white outline-none"
              >
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="flex-1 p-6 space-y-6">
              <div className="space-y-3">
                <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-400">
                  Characteristics
                </h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-slate-50 p-3 rounded-2xl border border-slate-100">
                    <span className="text-xs text-slate-400">Crop Type</span>
                    <p className="font-semibold text-slate-800 mt-0.5">
                      {selectedDrawerField.crops?.nom ?? "-"}
                    </p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl border border-slate-100">
                    <span className="text-xs text-slate-400">Kc Coefficient</span>
                    <p className="font-semibold text-slate-800 mt-0.5">
                      {selectedDrawerField.crops?.coefficient_kc ?? "-"}
                    </p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl border border-slate-100">
                    <span className="text-xs text-slate-400">Soil Type</span>
                    <p className="font-semibold text-slate-800 mt-0.5">
                      {selectedDrawerField.type_sol ?? "-"}
                    </p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-2xl border border-slate-100">
                    <span className="text-xs text-slate-400">Surface</span>
                    <p className="font-semibold text-slate-800 mt-0.5">
                      {selectedDrawerField.superficie ? `${selectedDrawerField.superficie} ha` : "-"}
                    </p>
                  </div>
                </div>
                <div className="bg-slate-50 p-3 rounded-2xl border border-slate-100 flex flex-wrap justify-between items-center text-xs text-slate-500 gap-2">
                  <span>Location: {selectedDrawerField.localisation}</span>
                  {selectedDrawerField.latitude && selectedDrawerField.longitude && (
                    <span className="font-mono bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full font-semibold">
                      {selectedDrawerField.latitude.toFixed(5)}, {selectedDrawerField.longitude.toFixed(5)}
                    </span>
                  )}
                </div>
              </div>

              <div className="space-y-3">
                <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-400">
                  Latest Recommendation
                </h3>
                {drawerInfo.latestRecommendation ? (
                  <div className="border border-blue-100 bg-blue-50/50 rounded-3xl p-5 space-y-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-xs text-blue-500 font-medium">Recommended Water</p>
                        <p className="text-3xl font-extrabold text-blue-700 mt-0.5">
                          {Number(drawerInfo.latestRecommendation.quantite_eau || 0).toFixed(2)} m³
                        </p>
                      </div>
                      <span className="text-xs text-slate-400 bg-white border border-slate-100 px-2.5 py-1 rounded-full font-medium shadow-sm">
                        {drawerInfo.latestRecommendation.date}
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-3 text-xs">
                      <div className="bg-white/80 p-2.5 rounded-xl">
                        <span className="text-slate-400">Duration</span>
                        <p className="font-semibold text-slate-800 mt-0.5">
                          {drawerInfo.latestRecommendation.duree_irrigation} mins
                        </p>
                      </div>
                      <div className="bg-white/80 p-2.5 rounded-xl">
                        <span className="text-slate-400">Frequency</span>
                        <p className="font-semibold text-slate-800 mt-0.5">
                          {drawerInfo.latestRecommendation.frequence ?? "-"}
                        </p>
                      </div>
                      <div className="bg-white/80 p-2.5 rounded-xl">
                        <span className="text-slate-400">ET0 / ETc</span>
                        <p className="font-semibold text-slate-800 mt-0.5">
                          {drawerInfo.latestRecommendation.et0.toFixed(2)} / {drawerInfo.latestRecommendation.etc.toFixed(2)}
                        </p>
                      </div>
                      <div className="bg-white/80 p-2.5 rounded-xl">
                        <span className="text-slate-400">Net / Gross Need</span>
                        <p className="font-semibold text-slate-800 mt-0.5">
                          {drawerInfo.latestRecommendation.besoin_net.toFixed(1)} / {drawerInfo.latestRecommendation.besoin_brut.toFixed(1)} mm
                        </p>
                      </div>
                    </div>

                    <p className="text-sm text-slate-600 bg-white p-3 rounded-2xl border border-slate-100 leading-relaxed">
                      {drawerInfo.latestRecommendation.message || "Recommendation generated successfully."}
                    </p>
                  </div>
                ) : (
                  <div className="text-center py-6 border border-dashed border-slate-200 rounded-3xl text-sm text-slate-400 bg-slate-50">
                    No recommendations available for this plot.
                  </div>
                )}
              </div>

              <div className="space-y-3">
                <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-400">
                  Irrigation History
                </h3>
                {drawerInfo.history.length > 0 ? (
                  <div className="space-y-2.5 max-h-[280px] overflow-y-auto pr-1">
                    {drawerInfo.history.map((hist) => (
                      <div
                        key={hist.id}
                        className="flex items-center justify-between p-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm transition hover:bg-slate-100/75"
                      >
                        <div>
                          <p className="font-semibold text-slate-800">
                            {Number(hist.quantite_eau || 0).toFixed(2)} m³
                          </p>
                          <p className="text-xs text-slate-400 mt-0.5">
                            ET0: {hist.et0.toFixed(2)} • ETc: {hist.etc.toFixed(2)}
                          </p>
                        </div>
                        <span className="text-xs text-slate-400 font-medium">
                          {hist.date}
                        </span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-6 border border-dashed border-slate-200 rounded-3xl text-sm text-slate-400 bg-slate-50">
                    No irrigation history logged yet.
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

function FieldsMap({
  fields,
  compact = false,
  onSelectField,
}: {
  fields: UserField[];
  compact?: boolean;
  onSelectField?: (field: UserField) => void;
}) {
  const mapElementRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<any>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadMap() {
      if (!mapElementRef.current) return;

      const L = await import("leaflet");

      if (cancelled || !mapElementRef.current) return;

      const fieldsWithGps = fields.filter(
        (field) =>
          typeof field.latitude === "number" &&
          typeof field.longitude === "number" &&
          field.latitude !== 0 &&
          field.longitude !== 0
      );

      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }

      const center =
        fieldsWithGps.length > 0
          ? [
              Number(fieldsWithGps[0].latitude),
              Number(fieldsWithGps[0].longitude),
            ]
          : [31.7917, -7.0926];

      const map = L.map(mapElementRef.current, {
        center: center as [number, number],
        zoom: fieldsWithGps.length > 0 ? 12 : 5,
        zoomControl: true,
      });

      mapInstanceRef.current = map;

      L.tileLayer(
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
        {
          attribution:
            "Tiles © Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community",
          maxZoom: 19,
        }
      ).addTo(map);

      fieldsWithGps.forEach((field) => {
        const marker = L.marker(
          [Number(field.latitude), Number(field.longitude)],
          {
            icon: L.divIcon({
              html: `
                <div style="
                  background:#2563eb;
                  width:18px;
                  height:18px;
                  border-radius:9999px;
                  border:3px solid white;
                  box-shadow:0 2px 8px rgba(0,0,0,.35);
                "></div>
              `,
              className: "",
              iconSize: [18, 18],
              iconAnchor: [9, 9],
            }),
          }
        ).addTo(map);

        marker.bindTooltip(
          `${escapeHtml(field.nom)} (${escapeHtml(field.crops?.nom ?? "Crop")})`,
          {
            permanent: false,
            direction: "top",
          }
        );

        marker.bindPopup(`
          <strong>${escapeHtml(field.nom)}</strong><br/>
          Crop: ${escapeHtml(field.crops?.nom ?? "-")}<br/>
          Surface: ${Number(field.superficie || 0)} ha<br/>
          Location: ${escapeHtml(field.localisation ?? "-")}
        `);

        marker.on("click", () => {
          if (onSelectField) {
            onSelectField(field);
          }
        });
      });

      if (fieldsWithGps.length > 1) {
        const bounds = L.latLngBounds(
          fieldsWithGps.map((field) => [
            Number(field.latitude),
            Number(field.longitude),
          ])
        );

        map.fitBounds(bounds, {
          padding: [40, 40],
        });
      }
    }

    loadMap();

    return () => {
      cancelled = true;

      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [fields]);

  return (
    <div className="relative">
      <div ref={mapElementRef} className={compact ? "h-[260px] w-full" : "h-[500px] w-full"} />

      {fields.length === 0 && (
        <div className="absolute inset-0 flex items-center justify-center bg-slate-900/40 text-white">
          No plots to display.
        </div>
      )}
    </div>
  );
}

function CompactStatCard({
  title,
  value,
  subtitle,
}: {
  title: string;
  value: string | number;
  subtitle: string;
}) {
  return (
    <div className="rounded-2xl bg-white p-4 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
        {title}
      </p>
      <h2 className="mt-2 text-2xl font-bold text-emerald-700">{value}</h2>
      <p className="mt-1 text-xs text-slate-400">{subtitle}</p>
    </div>
  );
}

function DashboardCard({
  title,
  subtitle,
  children,
  noPadding = false,
  actions,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  noPadding?: boolean;
  actions?: React.ReactNode;
}) {
  return (
    <div className="overflow-hidden rounded-3xl bg-white shadow-sm">
      <div className="flex items-center justify-between border-b px-5 py-4">
        <div>
          <h2 className="text-lg font-bold text-slate-900">{title}</h2>
          {subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}
        </div>
        {actions && <div className="flex items-center">{actions}</div>}
      </div>
      <div className={noPadding ? "" : "p-5"}>{children}</div>
    </div>
  );
}

function InfoLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between border-b pb-2 text-sm">
      <span className="text-slate-500">{label}</span>
      <span className="font-semibold text-slate-900">{value}</span>
    </div>
  );
}

function DataTable({
  headers,
  rows,
  empty,
}: {
  headers: string[];
  rows: string[][];
  empty: string;
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b text-slate-500">
            {headers.map((header) => (
              <th key={header} className="py-3 pr-4 font-semibold">
                {header}
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {rows.map((row, index) => (
            <tr key={index} className="border-b">
              {row.map((cell, cellIndex) => (
                <td
                  key={`${index}-${cellIndex}`}
                  className={`py-3 pr-4 ${
                    cellIndex === 0
                      ? "font-semibold text-slate-900"
                      : "text-slate-600"
                  }`}
                >
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      {rows.length === 0 && (
        <p className="py-8 text-center text-sm text-slate-500">{empty}</p>
      )}
    </div>
  );
}

function SmallEmpty() {
  return (
    <div className="flex h-[180px] items-center justify-center rounded-2xl bg-slate-50 text-sm text-slate-500">
      No data available.
    </div>
  );
}

function safeFields(fields: UserField[] | undefined) {
  return Array.isArray(fields) ? fields.filter(Boolean) : [];
}

function safeRecommendations(
  recommendations: FarmerRecommendation[] | undefined
) {
  return Array.isArray(recommendations) ? recommendations.filter(Boolean) : [];
}

function safeHistory(history: FarmerHistory[] | undefined) {
  return Array.isArray(history) ? history.filter(Boolean) : [];
}

function getPlotName(
  plot: FarmerPlotInfo | FarmerPlotInfo[] | null | undefined
) {
  if (!plot) return "Plot";

  if (Array.isArray(plot)) {
    return plot[0]?.nom ?? "Plot";
  }

  return plot.nom ?? "Plot";
}

function getCropName(
  plot: FarmerPlotInfo | FarmerPlotInfo[] | null | undefined
) {
  if (!plot) return "Crop";

  if (Array.isArray(plot)) {
    return plot[0]?.crops?.nom ?? "Crop";
  }

  return plot.crops?.nom ?? "Crop";
}

function shortUserId(userId: string) {
  if (!userId) return "-";

  if (userId.length <= 12) {
    return userId;
  }

  return `${userId.slice(0, 8)}...${userId.slice(-4)}`;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function exportToCsv(filename: string, headers: string[], rows: any[][]) {
  const content = [
    headers.join(","),
    ...rows.map((row) =>
      row
        .map((val) => {
          const str = val === null || val === undefined ? "" : String(val);
          return `"${str.replaceAll('"', '""')}"`;
        })
        .join(",")
    ),
  ].join("\n");

  const blob = new Blob([content], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", filename);
  link.style.visibility = "hidden";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

function exportToJson(filename: string, data: any) {
  const content = JSON.stringify(data, null, 2);
  const blob = new Blob([content], { type: "application/json;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", filename);
  link.style.visibility = "hidden";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}