"use client";

import Sidebar from "@/components/Sidebar";
import { useEffect, useMemo, useState } from "react";

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

type Field = {
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

type FlatField = Field & {
  farmerName: string;
  farmerEmail: string | null;
};

type GpsFilter = "all" | "with-gps" | "without-gps";

export default function PlotsPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedFarmerId, setSelectedFarmerId] = useState("all");
  const [search, setSearch] = useState("");
  const [gpsFilter, setGpsFilter] = useState<GpsFilter>("all");

  useEffect(() => {
    async function fetchData() {
      try {
        const res = await fetch("/api/users-summary");
        const data = await res.json();

        setUsers(Array.isArray(data) ? data : []);
      } catch (error) {
        console.error("Plots page fetch error:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  const allFields = useMemo(() => {
    return users.flatMap((user) => {
      const fields = Array.isArray(user.fields) ? user.fields : [];

      return fields.map((field) => ({
        ...field,
        farmerName: user.farmerName || shortUserId(user.userId),
        farmerEmail: user.farmerEmail,
      }));
    });
  }, [users]);

  const filteredFields = useMemo(() => {
    return allFields.filter((field) => {
      const matchesFarmer =
        selectedFarmerId === "all" || field.user_id === selectedFarmerId;

      const hasGps = hasValidGps(field);

      const matchesGps =
        gpsFilter === "all" ||
        (gpsFilter === "with-gps" && hasGps) ||
        (gpsFilter === "without-gps" && !hasGps);

      const text = [
        field.nom,
        field.localisation,
        field.type_sol,
        field.crops?.nom,
        field.farmerName,
        field.farmerEmail,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const matchesSearch = text.includes(search.trim().toLowerCase());

      return matchesFarmer && matchesGps && matchesSearch;
    });
  }, [allFields, selectedFarmerId, gpsFilter, search]);

  const totalFields = allFields.length;
  const fieldsWithGps = allFields.filter(hasValidGps).length;
  const fieldsWithoutGps = totalFields - fieldsWithGps;
  const totalSurface = allFields.reduce(
    (sum, field) => sum + Number(field.superficie || 0),
    0
  );

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-lg font-medium text-slate-600">
          Loading plots...
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
                    Plots Management
                  </h1>

                  <p className="mt-2 text-sm text-emerald-50">
                    View, filter, and monitor plots created by farmers from the mobile application.
                  </p>
                </div>

                <div className="rounded-2xl bg-white/15 px-5 py-4">
                  <p className="text-sm text-emerald-50">Mode</p>
                  <p className="text-lg font-bold">Read-only</p>
                </div>
              </div>
            </header>

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
              <StatCard
                title="Total plots"
                value={totalFields}
                subtitle="All plots"
              />

              <StatCard
                title="With GPS"
                value={fieldsWithGps}
                subtitle="Displayable on map"
              />

              <StatCard
                title="Without GPS"
                value={fieldsWithoutGps}
                subtitle="To correct from mobile"
              />

              <StatCard
                title="Total surface"
                value={`${totalSurface.toFixed(2)} ha`}
                subtitle="Declared surface"
              />
            </section>

            <section className="rounded-3xl bg-white p-5 shadow-sm">
              <div className="grid gap-4 xl:grid-cols-4">
                <div>
                  <label className="text-sm font-semibold text-slate-600">
                    Farmer
                  </label>

                  <select
                    value={selectedFarmerId}
                    onChange={(event) =>
                      setSelectedFarmerId(event.target.value)
                    }
                    className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
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

                <div>
                  <label className="text-sm font-semibold text-slate-600">
                    GPS
                  </label>

                  <select
                    value={gpsFilter}
                    onChange={(event) =>
                      setGpsFilter(event.target.value as GpsFilter)
                    }
                    className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
                  >
                    <option value="all">All plots</option>
                    <option value="with-gps">With GPS</option>
                    <option value="without-gps">Without GPS</option>
                  </select>
                </div>

                <div className="xl:col-span-2">
                  <label className="text-sm font-semibold text-slate-600">
                    Search
                  </label>

                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Name, crop, location, soil, farmer..."
                    className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
                  />
                </div>
              </div>
            </section>

            <section className="rounded-3xl bg-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b px-6 py-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">
                    Plots list
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    {filteredFields.length} plot(s) displayed out of{" "}
                    {totalFields}.
                  </p>
                </div>

                <div className="flex items-center gap-3">
                  <div className="flex gap-2 bg-slate-50 p-1.5 rounded-2xl border border-slate-100">
                    <button
                      onClick={() => {
                        const headers = ["Plot ID", "Plot Name", "Farmer Name", "Farmer Email", "Crop", "Surface (ha)", "Location", "Soil", "Latitude", "Longitude"];
                        const rows = filteredFields.map((field) => [
                          field.id,
                          field.nom,
                          field.farmerName,
                          field.farmerEmail ?? "",
                          field.crops?.nom ?? "-",
                          field.superficie,
                          field.localisation,
                          field.type_sol,
                          field.latitude ?? "",
                          field.longitude ?? "",
                        ]);
                        exportToCsv("plots_export.csv", headers, rows);
                      }}
                      className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                    >
                      Export CSV
                    </button>
                    <button
                      onClick={() => exportToJson("plots_export.json", filteredFields)}
                      className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                    >
                      Export JSON
                    </button>
                  </div>

                  <div className="rounded-full bg-emerald-50 px-4 py-2 text-sm font-semibold text-emerald-700">
                    Added from mobile
                  </div>
                </div>
              </div>

              <div className="overflow-x-auto p-6">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b text-slate-500">
                      <th className="py-3 pr-4">Plot</th>
                      <th className="py-3 pr-4">Farmer</th>
                      <th className="py-3 pr-4">Crop</th>
                      <th className="py-3 pr-4">Surface</th>
                      <th className="py-3 pr-4">Location</th>
                      <th className="py-3 pr-4">Soil</th>
                      <th className="py-3 pr-4">GPS</th>
                    </tr>
                  </thead>

                  <tbody>
                    {filteredFields.map((field) => {
                      const gps = hasValidGps(field);

                      return (
                        <tr key={field.id} className="border-b">
                          <td className="py-4 pr-4">
                            <p className="font-semibold text-slate-900">
                              {field.nom}
                            </p>

                            <p className="mt-1 text-xs text-slate-400">
                              ID: {shortUserId(field.id)}
                            </p>
                          </td>

                          <td className="py-4 pr-4">
                            <p className="font-medium text-slate-800">
                              {field.farmerName}
                            </p>

                            <p className="mt-1 text-xs text-slate-500">
                              {field.farmerEmail ?? "-"}
                            </p>
                          </td>

                          <td className="py-4 pr-4">
                            <span className="rounded-full bg-indigo-50 px-3 py-1 font-semibold text-indigo-700">
                              {field.crops?.nom ?? "-"}
                            </span>
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {Number(field.superficie || 0)} ha
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {field.localisation || "-"}
                          </td>

                          <td className="py-4 pr-4 text-slate-600">
                            {field.type_sol || "-"}
                          </td>

                          <td className="py-4 pr-4">
                            {gps ? (
                              <div>
                                <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">
                                  GPS OK
                                </span>

                                <p className="mt-2 text-xs text-slate-500">
                                  {Number(field.latitude).toFixed(4)},{" "}
                                  {Number(field.longitude).toFixed(4)}
                                </p>
                              </div>
                            ) : (
                              <span className="rounded-full bg-red-50 px-3 py-1 text-xs font-bold text-red-600">
                                Without GPS
                              </span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>

                {filteredFields.length === 0 && (
                  <div className="flex h-56 items-center justify-center rounded-2xl bg-slate-50">
                    <p className="text-sm text-slate-500">
                      No plots match the filters.
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

function hasValidGps(field: {
  latitude?: number | null;
  longitude?: number | null;
}) {
  return (
    typeof field.latitude === "number" &&
    typeof field.longitude === "number" &&
    field.latitude !== 0 &&
    field.longitude !== 0
  );
}

function shortUserId(value: string) {
  if (!value) return "-";

  if (value.length <= 12) {
    return value;
  }

  return `${value.slice(0, 8)}...${value.slice(-4)}`;
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