type OpenWeatherResponse = {
  main: {
    temp: number;
    humidity: number;
  };
  wind: {
    speed: number;
  };
  rain?: {
    "1h"?: number;
    "3h"?: number;
  };
};

export async function fetchCurrentWeather(lat: number, lon: number) {
  const apiKey = process.env.OPENWEATHER_API_KEY;

  if (!apiKey) {
    throw new Error("Missing OPENWEATHER_API_KEY");
  }

  const url = new URL("https://api.openweathermap.org/data/2.5/weather");

  url.searchParams.set("lat", String(lat));
  url.searchParams.set("lon", String(lon));
  url.searchParams.set("appid", apiKey);
  url.searchParams.set("units", "metric");
  url.searchParams.set("lang", "fr");

  const res = await fetch(url.toString(), {
    cache: "no-store",
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`OpenWeather error: ${errorText}`);
  }

  const data = (await res.json()) as OpenWeatherResponse;

  return {
    temperature: data.main.temp,
    humidite: data.main.humidity,
    vitesseVent: data.wind.speed,
    precipitation: data.rain?.["1h"] ?? data.rain?.["3h"] ?? 0,
    rayonnementSolaire: 20,
  };
}