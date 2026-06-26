"use client";

import Sidebar from "@/components/Sidebar";
import { useEffect, useMemo, useState } from "react";
import {
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
const chartOrange = "#f59e0b";

type Crop = {
  id: string;
  nom: string;
  coefficient_kc: number;
  stade_croissance: string;
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

type Farmer = {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  region: string | null;
  role: string | null;
  created_at: string;
};

type UserSummary = {
  userId: string;
  farmer: Farmer | null;
  farmerName: string;
  farmerEmail: string | null;
  farmerPhone: string | null;
  farmerRegion: string | null;
  fieldsCount: number;
  fields?: Field[];
};

type WeatherRecord = {
  id: string;
  plot_id?: string | null;
  temperature: number;
  humidite: number;
  vitesse_vent: number;
  rayonnement_solaire: number;
  precipitation: number;
  date: string;
  plots?: {
    id: string;
    nom: string;
    localisation: string;
    user_id?: string | null;
    crops?: Crop | null;
  } | null;
};

type FlatWeatherRecord = WeatherRecord & {
  farmerId: string | null;
  farmerName: string;
  farmerEmail: string | null;
  fieldName: string;
  fieldLocation: string;
  cropName: string;
};

type WeatherStatusFilter = "all" | "rain" | "hot" | "windy";

export default function WeatherPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [weather, setWeather] = useState<WeatherRecord[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedFarmerId, setSelectedFarmerId] = useState("all");
  const [selectedFieldId, setSelectedFieldId] = useState("all");
  const [selectedDate, setSelectedDate] = useState("");
  const [statusFilter, setStatusFilter] =
    useState<WeatherStatusFilter>("all");
  const [search, setSearch] = useState("");

  useEffect(() => {
    async function fetchData() {
      try {
        const [usersRes, weatherRes] = await Promise.all([
          fetch("/api/users-summary"),
          fetch("/api/weather-data"),
        ]);

        const usersData = await usersRes.json();
        const weatherData = await weatherRes.json();

        setUsers(Array.isArray(usersData) ? usersData : []);
        setWeather(Array.isArray(weatherData) ? weatherData : []);
      } catch (error) {
        console.error("Weather page fetch error:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  const fieldOwnerMap = useMemo(() => {
    const map = new Map<
      string,
      {
        farmerId: string;
        farmerName: string;
        farmerEmail: string | null;
        field: Field;
      }
    >();

    users.forEach((user) => {
      const fields = Array.isArray(user.fields) ? user.fields : [];

      fields.forEach((field) => {
        map.set(field.id, {
          farmerId: user.userId,
          farmerName: user.farmerName || shortId(user.userId),
          farmerEmail: user.farmerEmail,
          field,
        });
      });
    });

    return map;
  }, [users]);

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

  const enrichedWeather = useMemo(() => {
    return weather.map((item) => {
      const plotId = item.plot_id || item.plots?.id || "";
      const owner = fieldOwnerMap.get(plotId);

      return {
        ...item,
        farmerId: owner?.farmerId ?? item.plots?.user_id ?? null,
        farmerName: owner?.farmerName ?? "Unknown farmer",
        farmerEmail: owner?.farmerEmail ?? null,
        fieldName: owner?.field.nom ?? item.plots?.nom ?? "Plot",
        fieldLocation:
          owner?.field.localisation ?? item.plots?.localisation ?? "-",
        cropName:
          owner?.field.crops?.nom ?? item.plots?.crops?.nom ?? "Crop",
      };
    });
  }, [weather, fieldOwnerMap]);

  const availableFields = useMemo(() => {
    if (selectedFarmerId === "all") {
      return allFields;
    }

    return allFields.filter((field) => field.user_id === selectedFarmerId);
  }, [allFields, selectedFarmerId]);

  const filteredWeather = useMemo(() => {
    return enrichedWeather.filter((item) => {
      const matchesFarmer =
        selectedFarmerId === "all" || item.farmerId === selectedFarmerId;

      const matchesField =
        selectedFieldId === "all" ||
        item.plot_id === selectedFieldId ||
        item.plots?.id === selectedFieldId;

      const matchesDate = selectedDate === "" || item.date === selectedDate;

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "rain" && Number(item.precipitation || 0) > 0) ||
        (statusFilter === "hot" && Number(item.temperature || 0) >= 30) ||
        (statusFilter === "windy" && Number(item.vitesse_vent || 0) >= 5);

      const text = [
        item.farmerName,
        item.farmerEmail,
        item.fieldName,
        item.fieldLocation,
        item.cropName,
        item.date,
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
    enrichedWeather,
    selectedFarmerId,
    selectedFieldId,
    selectedDate,
    statusFilter,
    search,
  ]);

  const totalRecords = filteredWeather.length;

  const averageTemp =
    totalRecords > 0
      ? filteredWeather.reduce(
          (sum, item) => sum + Number(item.temperature || 0),
          0
        ) / totalRecords
      : 0;

  const averageHumidity =
    totalRecords > 0
      ? filteredWeather.reduce(
          (sum, item) => sum + Number(item.humidite || 0),
          0
        ) / totalRecords
      : 0;

  const averageWind =
    totalRecords > 0
      ? filteredWeather.reduce(
          (sum, item) => sum + Number(item.vitesse_vent || 0),
          0
        ) / totalRecords
      : 0;

  const totalRain = filteredWeather.reduce(
    (sum, item) => sum + Number(item.precipitation || 0),
    0
  );

  const chartData = useMemo(() => {
    return filteredWeather
      .slice()
      .reverse()
      .slice(-10)
      .map((item) => ({
        date: item.date,
        temp: Number(item.temperature || 0),
        humidity: Number(item.humidite || 0),
        rain: Number(item.precipitation || 0),
      }));
  }, [filteredWeather]);

  const alerts = useMemo(() => {
    const hotCount = filteredWeather.filter(
      (item) => Number(item.temperature || 0) >= 30
    ).length;

    const rainCount = filteredWeather.filter(
      (item) => Number(item.precipitation || 0) > 0
    ).length;

    const windyCount = filteredWeather.filter(
      (item) => Number(item.vitesse_vent || 0) >= 5
    ).length;

    const fieldsWithoutWeather = availableFields.filter((field) => {
      return !enrichedWeather.some(
        (item) => item.plot_id === field.id || item.plots?.id === field.id
      );
    }).length;

    return {
      hotCount,
      rainCount,
      windyCount,
      fieldsWithoutWeather,
    };
  }, [filteredWeather, availableFields, enrichedWeather]);

  if (loading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-slate-50">
        <p className="text-lg font-medium text-slate-600">
          Loading weather data...
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
            <header className="rounded-3xl bg-gradient-to-r from-blue-700 to-emerald-500 p-6 text-white shadow-sm">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-wide text-blue-100">
                    Weather admin
                  </p>

                  <h1 className="mt-1 text-3xl font-bold">
                    Weather monitoring
                  </h1>

                  <p className="mt-2 text-sm text-blue-50">
                    View data retrieved from OpenWeather based on the GPS location of the plots.
                  </p>
                </div>

                <div className="rounded-2xl bg-white/15 px-5 py-4">
                  <p className="text-sm text-blue-50">Main source</p>
                  <p className="text-lg font-bold">OpenWeather</p>
                </div>
              </div>
            </header>

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
              <StatCard
                title="Records"
                value={totalRecords}
                subtitle="Data displayed"
              />

              <StatCard
                title="Average Temp."
                value={`${averageTemp.toFixed(1)}°C`}
                subtitle="Filtered average"
              />

              <StatCard
                title="Average Humidity"
                value={`${averageHumidity.toFixed(0)}%`}
                subtitle="Filtered average"
              />

              <StatCard
                title="Average Wind"
                value={`${averageWind.toFixed(1)} m/s`}
                subtitle="Filtered average"
              />

              <StatCard
                title="Total Rain"
                value={`${totalRain.toFixed(1)} mm`}
                subtitle="Filtered sum"
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
                      setStatusFilter(event.target.value as WeatherStatusFilter)
                    }
                    className="filter-input"
                  >
                    <option value="all">All statuses</option>
                    <option value="rain">Rain detected</option>
                    <option value="hot">High temperature</option>
                    <option value="windy">Strong wind</option>
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

            <section className="grid gap-6 xl:grid-cols-3">
              <div className="rounded-3xl bg-white p-5 shadow-sm xl:col-span-2">
                <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <h2 className="text-xl font-bold text-slate-900">
                      Weather evolution
                    </h2>
                    <p className="mt-1 text-sm text-slate-500">
                      Temperature, humidity, and rain over the latest records.
                    </p>
                  </div>
                </div>

                {chartData.length > 0 ? (
                  <ResponsiveContainer width="100%" height={260}>
                    <LineChart data={chartData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                      <YAxis tick={{ fontSize: 11 }} />
                      <Tooltip />
                      <Line
                        type="monotone"
                        dataKey="temp"
                        stroke={chartOrange}
                        strokeWidth={2}
                        name="Temperature"
                      />
                      <Line
                        type="monotone"
                        dataKey="humidity"
                        stroke={chartBlue}
                        strokeWidth={2}
                        name="Humidity"
                      />
                      <Line
                        type="monotone"
                        dataKey="rain"
                        stroke={chartGreen}
                        strokeWidth={2}
                        name="Rain"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                ) : (
                  <SmallEmpty />
                )}
              </div>

              <div className="rounded-3xl bg-white p-5 shadow-sm">
                <h2 className="text-xl font-bold text-slate-900">
                  Weather alerts
                </h2>

                <div className="mt-4 space-y-3">
                  <AlertLine
                    label="High temperature"
                    value={`${alerts.hotCount} record(s)`}
                    tone="orange"
                  />

                  <AlertLine
                    label="Rain detected"
                    value={`${alerts.rainCount} record(s)`}
                    tone="blue"
                  />

                  <AlertLine
                    label="Strong wind"
                    value={`${alerts.windyCount} record(s)`}
                    tone="red"
                  />

                  <AlertLine
                    label="Plots without weather"
                    value={`${alerts.fieldsWithoutWeather} plot(s)`}
                    tone="slate"
                  />
                </div>

                <div className="mt-5 rounded-2xl bg-blue-50 p-4">
                  <p className="text-sm font-semibold text-blue-900">
                    Admin note
                  </p>
                  <p className="mt-1 text-sm text-blue-700">
                    Weather is automatically retrieved from the GPS position of the plots during mobile analysis.
                  </p>
                </div>
              </div>
            </section>

            <section className="rounded-3xl bg-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b px-6 py-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">
                    Weather history
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    {filteredWeather.length} record(s) displayed.
                  </p>
                </div>

                <div className="flex gap-2 bg-slate-50 p-1.5 rounded-2xl border border-slate-100">
                  <button
                    onClick={() => {
                      const headers = ["Record ID", "Date", "Farmer Name", "Farmer Email", "Plot Name", "Location", "Crop", "Temperature (C)", "Humidity (%)", "Wind Speed (m/s)", "Solar Radiation", "Precipitation (mm)"];
                      const rows = filteredWeather.map((item) => [
                        item.id,
                        item.date,
                        item.farmerName,
                        item.farmerEmail ?? "",
                        item.fieldName,
                        item.fieldLocation,
                        item.cropName,
                        Number(item.temperature || 0).toFixed(1),
                        Number(item.humidite || 0).toFixed(0),
                        Number(item.vitesse_vent || 0).toFixed(1),
                        Number(item.rayonnement_solaire || 0).toFixed(1),
                        Number(item.precipitation || 0).toFixed(1),
                      ]);
                      exportToCsv("weather_export.csv", headers, rows);
                    }}
                    className="rounded-xl bg-white px-3 py-1.5 text-xs font-semibold text-emerald-700 shadow-sm border border-slate-100 hover:bg-emerald-50 hover:text-emerald-800 transition"
                  >
                    Export CSV
                  </button>
                  <button
                    onClick={() => exportToJson("weather_export.json", filteredWeather)}
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
                      <th className="py-3 pr-4">Temp.</th>
                      <th className="py-3 pr-4">Humidity</th>
                      <th className="py-3 pr-4">Wind</th>
                      <th className="py-3 pr-4">Rain</th>
                      <th className="py-3 pr-4">Source</th>
                    </tr>
                  </thead>

                  <tbody>
                    {filteredWeather.map((item) => (
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

                        <td className="py-4 pr-4">
                          <p className="font-medium text-slate-800">
                            {item.fieldName}
                          </p>
                          <p className="mt-1 text-xs text-slate-500">
                            {item.fieldLocation}
                          </p>
                        </td>

                        <td className="py-4 pr-4">
                          <span className="rounded-full bg-indigo-50 px-3 py-1 font-semibold text-indigo-700">
                            {item.cropName}
                          </span>
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.temperature || 0).toFixed(1)}°C
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.humidite || 0).toFixed(0)}%
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.vitesse_vent || 0).toFixed(1)} m/s
                        </td>

                        <td className="py-4 pr-4 text-slate-600">
                          {Number(item.precipitation || 0).toFixed(1)} mm
                        </td>

                        <td className="py-4 pr-4">
                          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">
                            OpenWeather
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {filteredWeather.length === 0 && (
                  <div className="flex h-56 items-center justify-center rounded-2xl bg-slate-50">
                    <p className="text-sm text-slate-500">
                      No weather data matches the filters.
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

function AlertLine({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone: "orange" | "blue" | "red" | "slate";
}) {
  const classes = {
    orange: "bg-orange-50 text-orange-700",
    blue: "bg-blue-50 text-blue-700",
    red: "bg-red-50 text-red-700",
    slate: "bg-slate-50 text-slate-700",
  };

  return (
    <div
      className={`flex items-center justify-between rounded-2xl px-4 py-3 ${classes[tone]}`}
    >
      <span className="text-sm font-medium">{label}</span>
      <span className="text-sm font-bold">{value}</span>
    </div>
  );
}

function SmallEmpty() {
  return (
    <div className="flex h-[260px] items-center justify-center rounded-2xl bg-slate-50 text-sm text-slate-500">
      No data available.
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