"use client";

import Sidebar from "@/components/Sidebar";
import { useEffect, useMemo, useState } from "react";

type Farmer = {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  region: string | null;
  role: string | null;
  created_at: string;
};

type Field = {
  id: string;
  user_id: string;
  nom: string;
  superficie: number;
  localisation: string;
  type_sol: string;
  latitude?: number | null;
  longitude?: number | null;
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
  fields?: Field[];
};

export default function FarmersPage() {
  const [farmers, setFarmers] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("all");

  useEffect(() => {
    async function fetchFarmers() {
      try {
        const res = await fetch("/api/users-summary");
        const data = await res.json();

        setFarmers(Array.isArray(data) ? data : []);
      } catch (error) {
        console.error("Farmers page fetch error:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchFarmers();
  }, []);

  async function handleToggleBlock(userId: string, shouldBlock: boolean) {
    try {
      const res = await fetch("/api/farmers", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          id: userId,
          role: shouldBlock ? "blocked" : "farmer",
        }),
      });

      if (!res.ok) {
        throw new Error("Failed to update status");
      }

      setFarmers((prev) =>
        prev.map((farmer) =>
          farmer.userId === userId
            ? { ...farmer, farmerRole: shouldBlock ? "blocked" : "farmer" }
            : farmer
        )
      );
    } catch (error) {
      console.error("Error toggling block status:", error);
      alert("Error updating farmer status.");
    }
  }

  const filteredFarmers = useMemo(() => {
    return farmers.filter((farmer) => {
      const text = [
        farmer.farmerName,
        farmer.farmerEmail,
        farmer.farmerPhone,
        farmer.farmerRegion,
        farmer.userId,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const matchesSearch = text.includes(search.trim().toLowerCase());

      const matchesStatus =
        selectedStatus === "all" ||
        (selectedStatus === "blocked" && farmer.farmerRole === "blocked") ||
        (selectedStatus === "with-fields" && farmer.fieldsCount > 0 && farmer.farmerRole !== "blocked") ||
        (selectedStatus === "without-fields" && farmer.fieldsCount === 0 && farmer.farmerRole !== "blocked") ||
        (selectedStatus === "with-recommendations" &&
          farmer.recommendationsCount > 0 && farmer.farmerRole !== "blocked") ||
        (selectedStatus === "without-recommendations" &&
          farmer.recommendationsCount === 0 && farmer.farmerRole !== "blocked");

      return matchesSearch && matchesStatus;
    });
  }, [farmers, search, selectedStatus]);

  const totalFarmers = farmers.length;

  const activeFarmers = farmers.filter(
    (farmer) => farmer.fieldsCount > 0
  ).length;

  const farmersWithoutFields = farmers.filter(
    (farmer) => farmer.fieldsCount === 0
  ).length;

  const totalFields = farmers.reduce(
    (sum, farmer) => sum + Number(farmer.fieldsCount || 0),
    0
  );

  const totalRecommendations = farmers.reduce(
    (sum, farmer) => sum + Number(farmer.recommendationsCount || 0),
    0
  );

  const totalWater = farmers.reduce(
    (sum, farmer) => sum + Number(farmer.totalWater || 0),
    0
  );

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-lg font-medium text-slate-600">
          Loading farmers...
        </p>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <div className="flex">
        <Sidebar />

        <section className="flex-1 p-6">
          <div className="space-y-6">
            <header className="rounded-3xl bg-gradient-to-r from-emerald-700 to-emerald-500 p-6 text-white shadow-sm">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-wide text-emerald-100">
                    Admin
                  </p>

                  <h1 className="mt-1 text-3xl font-bold">
                    Farmers Management
                  </h1>

                  <p className="mt-2 text-sm text-emerald-50">
                    View farmer accounts, their plots, recommendations, and irrigation statistics.
                  </p>
                </div>

                <div className="rounded-2xl bg-white/15 px-5 py-4">
                  <p className="text-sm text-emerald-50">Total</p>
                  <p className="text-2xl font-bold">{totalFarmers}</p>
                </div>
              </div>
            </header>

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
              <StatCard
                title="Farmers"
                value={totalFarmers}
                subtitle="Registered accounts"
              />

              <StatCard
                title="Active"
                value={activeFarmers}
                subtitle="With plots"
              />

              <StatCard
                title="Without plots"
                value={farmersWithoutFields}
                subtitle="To follow"
              />

              <StatCard
                title="Plots"
                value={totalFields}
                subtitle="Total"
              />

              <StatCard
                title="Total Water"
                value={`${totalWater.toFixed(1)} m³`}
                subtitle={`${totalRecommendations} recommendations`}
              />
            </section>

            <section className="rounded-3xl bg-white p-5 shadow-sm">
              <div className="grid gap-4 xl:grid-cols-3">
                <div>
                  <label className="text-sm font-semibold text-slate-600">
                    Status
                  </label>

                  <select
                    value={selectedStatus}
                    onChange={(event) => setSelectedStatus(event.target.value)}
                    className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
                  >
                    <option value="all">All farmers</option>
                    <option value="blocked">Blocked</option>
                    <option value="with-fields">With plots</option>
                    <option value="without-fields">Without plots</option>
                    <option value="with-recommendations">
                      With recommendations
                    </option>
                    <option value="without-recommendations">
                      Without recommendations
                    </option>
                  </select>
                </div>

                <div className="xl:col-span-2">
                  <label className="text-sm font-semibold text-slate-600">
                    Search
                  </label>

                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Name, email, phone, region..."
                    className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
                  />
                </div>
              </div>
            </section>

            <section className="rounded-3xl bg-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b px-6 py-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">
                    Farmers list
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    {filteredFarmers.length} farmer(s) displayed out of{" "}
                    {totalFarmers}.
                  </p>
                </div>

                <div className="flex gap-2 bg-slate-50 p-1.5 rounded-2xl border border-slate-100">
                  <button
                    onClick={() => {
                      const headers = ["Farmer ID", "Name", "Email", "Phone", "Plots Count", "Recommendations Count", "Total Water (m3)", "Average ET0", "Latest Reco. Date"];
                      const rows = filteredFarmers.map((farmer) => [
                        farmer.userId,
                        farmer.farmerName,
                        farmer.farmerEmail ?? "",
                        farmer.farmerPhone ?? "",
                        farmer.fieldsCount,
                        farmer.recommendationsCount,
                        farmer.totalWater,
                        farmer.averageEt0,
                        farmer.latestRecommendationDate ?? "",
                      ]);
                      exportToCsv("farmers_export.csv", headers, rows);
                    }}
                    className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                  >
                    Export CSV
                  </button>
                  <button
                    onClick={() => exportToJson("farmers_export.json", filteredFarmers)}
                    className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                  >
                    Export JSON
                  </button>
                </div>
              </div>

              <div className="overflow-x-auto p-6">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b text-slate-500">
                      <th className="py-3 pr-4">Farmer</th>
                      <th className="py-3 pr-4">Contact</th>
                      <th className="py-3 pr-4">Plots</th>
                      <th className="py-3 pr-4">Recommendations</th>
                      <th className="py-3 pr-4">Total Water</th>
                      <th className="py-3 pr-4">Average ET0</th>
                      <th className="py-3 pr-4">Latest reco.</th>
                      <th className="py-3 pr-4">Status</th>
                      <th className="py-3 pr-4">Actions</th>
                    </tr>
                  </thead>

                  <tbody>
                    {filteredFarmers.map((farmer) => {
                      const hasFields = farmer.fieldsCount > 0;
                      const hasRecommendations =
                        farmer.recommendationsCount > 0;

                      return (
                        <tr key={farmer.userId} className="border-b">
                          <td className="py-4 pr-4">
                            <p className="font-semibold text-slate-900">
                              {farmer.farmerName ||
                                `Farmer ${shortId(farmer.userId)}`}
                            </p>

                            <p className="mt-1 text-xs text-slate-400">
                              ID: {shortId(farmer.userId)}
                            </p>
                          </td>

                          <td className="py-4 pr-4">
                            <p className="font-medium text-slate-800">
                              {farmer.farmerEmail ?? "-"}
                            </p>

                            <p className="mt-1 text-xs text-slate-500">
                              {farmer.farmerPhone ?? "Phone unavailable"}
                            </p>
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {farmer.fieldsCount}
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {farmer.recommendationsCount}
                          </td>

                          <td className="py-4 pr-4 font-semibold text-emerald-700">
                            {Number(farmer.totalWater || 0).toFixed(2)} m³
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {Number(farmer.averageEt0 || 0).toFixed(2)}
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {farmer.latestRecommendationDate ?? "-"}
                          </td>

                          <td className="py-4 pr-4">
                            {farmer.farmerRole === "blocked" ? (
                              <StatusBadge label="Blocked" tone="red" />
                            ) : hasFields && hasRecommendations ? (
                              <StatusBadge label="Active" tone="green" />
                            ) : hasFields ? (
                              <StatusBadge
                                label="Without reco"
                                tone="orange"
                              />
                            ) : (
                              <StatusBadge
                                label="Without plot"
                                tone="red"
                              />
                            )}
                          </td>

                          <td className="py-4 pr-4">
                            {farmer.farmerRole === "blocked" ? (
                              <button
                                onClick={() => handleToggleBlock(farmer.userId, false)}
                                className="rounded-xl bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition"
                              >
                                Unblock
                              </button>
                            ) : (
                              <button
                                onClick={() => handleToggleBlock(farmer.userId, true)}
                                className="rounded-xl bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition"
                              >
                                Block
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>

                {filteredFarmers.length === 0 && (
                  <div className="flex h-56 items-center justify-center rounded-2xl bg-slate-50">
                    <p className="text-sm text-slate-500">
                      No farmers match the filters.
                    </p>
                  </div>
                )}
              </div>
            </section>
          
          </div>
        </section>
      </div>
    </main>
  );
}

function StatusBadge({
  label,
  tone,
}: {
  label: string;
  tone: "green" | "orange" | "red";
}) {
  const classes = {
    green: "bg-emerald-50 text-emerald-700",
    orange: "bg-orange-50 text-orange-700",
    red: "bg-red-50 text-red-600",
  };

  return (
    <span
      className={`rounded-full px-3 py-1 text-xs font-bold ${classes[tone]}`}
    >
      {label}
    </span>
  );
}

function StatCard({
  title,
  value,
  subtitle,
}: {
  title: string;
  value: string | number;
  subtitle: string;
}) {
  return (
    <div className="rounded-3xl bg-white p-5 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
        {title}
      </p>

      <h2 className="mt-2 text-3xl font-bold text-emerald-700">{value}</h2>

      <p className="mt-1 text-sm text-slate-400">{subtitle}</p>
    </div>
  );
}

function shortId(value: string) {
  if (!value) return "-";

  if (value.length <= 12) {
    return value;
  }

  return `${value.slice(0, 8)}...${value.slice(-4)}`;
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