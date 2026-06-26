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

type HistoryPlot = {
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

type IrrigationRecommendation = {
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
};

type HistoryItem = {
  id: string;
  plot_id: string;
  recommendation_id: string | null;
  et0: number;
  etc: number;
  quantite_eau: number;
  date: string;
  plots?: HistoryPlot | HistoryPlot[] | null;
  irrigation_recommendations?: IrrigationRecommendation | null;
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
  history?: HistoryItem[];
};

type FlatHistoryItem = HistoryItem & {
  farmerId: string;
  farmerName: string;
  farmerEmail: string | null;
};

type StatusFilter = "all" | "with-water" | "no-water";

export default function HistoryPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedFarmerId, setSelectedFarmerId] = useState("all");
  const [selectedFieldId, setSelectedFieldId] = useState("all");
  const [selectedDate, setSelectedDate] = useState("");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [search, setSearch] = useState("");

  useEffect(() => {
    async function fetchData() {
      try {
        const res = await fetch("/api/users-summary");
        const data = await res.json();

        setUsers(Array.isArray(data) ? data : []);
      } catch (error) {
        console.error("History page fetch error:", error);
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
        farmerName: user.farmerName || shortId(user.userId),
        farmerEmail: user.farmerEmail,
      }));
    });
  }, [users]);

  const availableFields = useMemo(() => {
    if (selectedFarmerId === "all") {
      return allFields;
    }

    return allFields.filter((field) => field.user_id === selectedFarmerId);
  }, [allFields, selectedFarmerId]);

  const allHistory = useMemo(() => {
    return users.flatMap((user) => {
      const history = Array.isArray(user.history)
        ? user.history.filter(Boolean)
        : [];

      return history.map((item) => ({
        ...item,
        farmerId: user.userId,
        farmerName: user.farmerName || shortId(user.userId),
        farmerEmail: user.farmerEmail,
      }));
    });
  }, [users]);

  const filteredHistory = useMemo(() => {
    return allHistory.filter((item) => {
      const matchesFarmer =
        selectedFarmerId === "all" || item.farmerId === selectedFarmerId;

      const plotId = getPlotId(item.plots) || item.plot_id;

      const matchesField = selectedFieldId === "all" || plotId === selectedFieldId;

      const matchesDate = selectedDate === "" || item.date === selectedDate;

      const water = Number(item.quantite_eau || 0);

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "with-water" && water > 0) ||
        (statusFilter === "no-water" && water <= 0);

      const text = [
        item.farmerName,
        item.farmerEmail,
        getPlotName(item.plots),
        getCropName(item.plots),
        item.date,
        item.irrigation_recommendations?.message,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const matchesSearch = text.includes(search.trim().toLowerCase());

      return (
        matchesFarmer &&
        matchesField &&
        matchesDate &&
        matchesStatus &&
        matchesSearch
      );
    });
  }, [
    allHistory,
    selectedFarmerId,
    selectedFieldId,
    selectedDate,
    statusFilter,
    search,
  ]);

  const totalRecords = filteredHistory.length;

  const totalWater = filteredHistory.reduce(
    (sum, item) => sum + Number(item.quantite_eau || 0),
    0
  );

  const averageEt0 =
    totalRecords > 0
      ? filteredHistory.reduce((sum, item) => sum + Number(item.et0 || 0), 0) /
        totalRecords
      : 0;

  const averageEtc =
    totalRecords > 0
      ? filteredHistory.reduce((sum, item) => sum + Number(item.etc || 0), 0) /
        totalRecords
      : 0;

  const recordsWithWater = filteredHistory.filter(
    (item) => Number(item.quantite_eau || 0) > 0
  ).length;

  const recordsWithoutWater = totalRecords - recordsWithWater;

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-lg font-medium text-slate-600">
          Loading history...
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
                    Irrigation History
                  </h1>

                  <p className="mt-2 text-sm text-emerald-50">
                    View irrigation histories generated from the mobile application.
                  </p>
                </div>

                <div className="rounded-2xl bg-white/15 px-5 py-4">
                  <p className="text-sm text-emerald-50">Source</p>
                  <p className="text-lg font-bold">Mobile Analysis</p>
                </div>
              </div>
            </header>

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
              <StatCard
                title="Records"
                value={totalRecords}
                subtitle="History items displayed"
              />

              <StatCard
                title="Total Water"
                value={`${totalWater.toFixed(1)} m³`}
                subtitle="Total volume"
              />

              <StatCard
                title="Average ET0"
                value={averageEt0.toFixed(2)}
                subtitle="Filtered average"
              />

              <StatCard
                title="Average ETc"
                value={averageEtc.toFixed(2)}
                subtitle="Filtered average"
              />

              <StatCard
                title="With water"
                value={recordsWithWater}
                subtitle={`${recordsWithoutWater} without water`}
              />
            </section>

            <section className="rounded-3xl bg-white p-5 shadow-sm">
              <div className="grid gap-4 xl:grid-cols-5">
                <FilterBlock label="Farmer">
                  <select
                    value={selectedFarmerId}
                    onChange={(event) => {
                      setSelectedFarmerId(event.target.value);
                      setSelectedFieldId("all");
                    }}
                    className="filter-input"
                  >
                    <option value="all">All farmers</option>

                    {users.map((user) => (
                      <option key={user.userId} value={user.userId}>
                        {user.farmerName || shortId(user.userId)}
                        {user.farmerEmail ? ` - ${user.farmerEmail}` : ""}
                      </option>
                    ))}
                  </select>
                </FilterBlock>

                <FilterBlock label="Plot">
                  <select
                    value={selectedFieldId}
                    onChange={(event) => setSelectedFieldId(event.target.value)}
                    className="filter-input"
                  >
                    <option value="all">All plots</option>

                    {availableFields.map((field) => (
                      <option key={field.id} value={field.id}>
                        {field.nom} - {field.crops?.nom ?? "Crop"}
                      </option>
                    ))}
                  </select>
                </FilterBlock>

                <FilterBlock label="Date">
                  <input
                    type="date"
                    value={selectedDate}
                    onChange={(event) => setSelectedDate(event.target.value)}
                    className="filter-input"
                  />
                </FilterBlock>

                <FilterBlock label="Status">
                  <select
                    value={statusFilter}
                    onChange={(event) =>
                      setStatusFilter(event.target.value as StatusFilter)
                    }
                    className="filter-input"
                  >
                    <option value="all">All statuses</option>
                    <option value="with-water">With water</option>
                    <option value="no-water">Without water</option>
                  </select>
                </FilterBlock>

                <FilterBlock label="Search">
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Farmer, plot, crop..."
                    className="filter-input"
                  />
                </FilterBlock>
              </div>
            </section>

            <section className="rounded-3xl bg-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b px-6 py-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">
                    Saved history
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    {filteredHistory.length} record(s) displayed.
                  </p>
                </div>

                <div className="flex gap-2 bg-slate-50 p-1.5 rounded-2xl border border-slate-100">
                  <button
                    onClick={() => {
                      const headers = ["History ID", "Date", "Farmer Name", "Farmer Email", "Plot Name", "Crop Name", "ET0", "ETc", "Water Volume (m3)", "Message"];
                      const rows = filteredHistory.map((item) => [
                        item.id,
                        item.date,
                        item.farmerName,
                        item.farmerEmail ?? "",
                        getPlotName(item.plots),
                        getCropName(item.plots),
                        Number(item.et0 || 0).toFixed(2),
                        Number(item.etc || 0).toFixed(2),
                        Number(item.quantite_eau || 0).toFixed(2),
                        item.irrigation_recommendations?.message ?? "History saved.",
                      ]);
                      exportToCsv("history_export.csv", headers, rows);
                    }}
                    className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                  >
                    Export CSV
                  </button>
                  <button
                    onClick={() => exportToJson("history_export.json", filteredHistory)}
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
                      <th className="py-3 pr-4">Date</th>
                      <th className="py-3 pr-4">Farmer</th>
                      <th className="py-3 pr-4">Plot</th>
                      <th className="py-3 pr-4">Crop</th>
                      <th className="py-3 pr-4">ET0</th>
                      <th className="py-3 pr-4">ETc</th>
                      <th className="py-3 pr-4">Water</th>
                      <th className="py-3 pr-4">Message</th>
                    </tr>
                  </thead>

                  <tbody>
                    {filteredHistory.map((item) => (
                      <tr key={item.id} className="border-b">
                        <td className="py-4 pr-4 font-semibold text-slate-900">
                          {item.date}
                        </td>

                        <td className="py-4 pr-4">
                          <p className="font-medium text-slate-800">
                            {item.farmerName}
                          </p>
                          <p className="mt-1 text-xs text-slate-500">
                            {item.farmerEmail ?? "-"}
                          </p>
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {getPlotName(item.plots)}
                        </td>

                        <td className="py-4 pr-4">
                          <span className="rounded-full bg-indigo-50 px-3 py-1 font-semibold text-indigo-700">
                            {getCropName(item.plots)}
                          </span>
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.et0 || 0).toFixed(2)}
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.etc || 0).toFixed(2)}
                        </td>

                        <td className="py-4 pr-4 font-semibold text-emerald-700">
                          {Number(item.quantite_eau || 0).toFixed(2)} m³
                        </td>

                        <td className="max-w-[360px] py-4 pr-4 text-slate-600">
                          {item.irrigation_recommendations?.message ??
                            "History saved."}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {filteredHistory.length === 0 && (
                  <div className="flex h-56 items-center justify-center rounded-2xl bg-slate-50">
                    <p className="text-sm text-slate-500">
                      No history matches the filters.
                    </p>
                  </div>
                )}
              </div>
            </section>

            <section className="grid gap-4 xl:grid-cols-2">
              {filteredHistory.slice(0, 4).map((item) => (
                <div
                  key={item.id}
                  className="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm"
                >
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <h3 className="text-lg font-bold text-slate-900">
                        {getPlotName(item.plots)}
                      </h3>

                      <p className="mt-1 text-sm text-slate-500">
                        {item.farmerName} • {getCropName(item.plots)} •{" "}
                        {item.date}
                      </p>
                    </div>

                    <span className="rounded-full bg-emerald-100 px-4 py-2 text-sm font-bold text-emerald-700">
                      {Number(item.quantite_eau || 0).toFixed(2)} m³
                    </span>
                  </div>

                  <p className="mt-4 text-sm text-slate-700">
                    {item.irrigation_recommendations?.message ??
                      "Irrigation history saved."}
                  </p>

                  <div className="mt-4 grid gap-3 md:grid-cols-3">
                    <MiniStat
                      label="ET0"
                      value={Number(item.et0 || 0).toFixed(2)}
                    />
                    <MiniStat
                      label="ETc"
                      value={Number(item.etc || 0).toFixed(2)}
                    />
                    <MiniStat
                      label="Water"
                      value={`${Number(item.quantite_eau || 0).toFixed(2)} m³`}
                    />
                  </div>
                </div>
              ))}
            </section>
          </div>
        </section>
      </div>
    </main>
  );
}

function FilterBlock({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="text-sm font-semibold text-slate-600">{label}</label>
      <div className="mt-2">{children}</div>
    </div>
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

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl bg-slate-50 p-3">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 font-bold text-slate-900">{value}</p>
    </div>
  );
}

function getPlot(plot: HistoryPlot | HistoryPlot[] | null | undefined) {
  if (!plot) return null;

  if (Array.isArray(plot)) {
    return plot[0] ?? null;
  }

  return plot;
}

function getPlotId(plot: HistoryPlot | HistoryPlot[] | null | undefined) {
  return getPlot(plot)?.id ?? null;
}

function getPlotName(plot: HistoryPlot | HistoryPlot[] | null | undefined) {
  return getPlot(plot)?.nom ?? "Plot";
}

function getCropName(plot: HistoryPlot | HistoryPlot[] | null | undefined) {
  return getPlot(plot)?.crops?.nom ?? "Crop";
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