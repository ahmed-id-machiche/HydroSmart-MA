const API_KEY = process.env.AGRO_MONITORING_API_KEY || "";
const BASE_URL = "http://api.agromonitoring.com/agro/1.0";

// Helper to generate a square polygon of ~1 hectare (100m x 100m) around a GPS coordinate
function getSquarePolygonCoordinates(lat: number, lon: number) {
  const deltaLat = 0.0005; // ~55 meters north and south
  const latRad = (lat * Math.PI) / 180;
  const deltaLon = deltaLat / Math.cos(latRad); // Adjust for longitude narrowing at higher latitudes

  return [
    [
      [lon - deltaLon, lat - deltaLat],
      [lon + deltaLon, lat - deltaLat],
      [lon + deltaLon, lat + deltaLat],
      [lon - deltaLon, lat + deltaLat],
      [lon - deltaLon, lat - deltaLat], // Close the loop
    ],
  ];
}

/**
 * Creates a polygon on the Agro Monitoring API for a specific plot coordinate
 */
export async function createAgroPolygon(plotName: string, lat: number, lon: number): Promise<string> {
  if (!API_KEY) {
    throw new Error("AGRO_MONITORING_API_KEY is not defined in environment variables.");
  }

  const coordinates = getSquarePolygonCoordinates(lat, lon);

  const response = await fetch(`${BASE_URL}/polygons?appid=${API_KEY}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      name: plotName,
      geo_json: {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: coordinates,
        },
      },
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Failed to create Agro Monitoring polygon: ${errText}`);
  }

  const data = await response.json();
  return data.id; // Returns the polygon ID
}

/**
 * Gets the polygon ID for a given plot from Agro Monitoring,
 * or creates it if it doesn't exist yet.
 */
export async function getOrCreatePolygonId(plotId: string, lat: number, lon: number): Promise<string> {
  if (!API_KEY) {
    throw new Error("AGRO_MONITORING_API_KEY is not defined in environment variables.");
  }

  try {
    // Fetch all existing polygons
    const listUrl = `${BASE_URL}/polygons?appid=${API_KEY}`;
    const listResponse = await fetch(listUrl);
    
    if (listResponse.ok) {
      const polygons = await listResponse.json();
      // Search for a polygon whose name is the plotId UUID
      const existing = polygons.find((p: any) => p.name === plotId);
      if (existing) {
        return existing.id;
      }
    }
  } catch (err) {
    console.error("Failed to check existing polygons:", err);
  }

  // If not found, create a new polygon
  return await createAgroPolygon(plotId, lat, lon);
}

/**
 * Fetches the latest NDVI value for a specific polygon
 */
export async function getLatestNDVI(polygonId: string): Promise<number | null> {
  if (!API_KEY) return null;

  const nowSeconds = Math.floor(Date.now() / 1000);
  const thirtyDaysAgoSeconds = nowSeconds - 30 * 24 * 60 * 60; // Get data for the last 30 days

  const url = `${BASE_URL}/ndvi/history?polyid=${polygonId}&start=${thirtyDaysAgoSeconds}&end=${nowSeconds}&appid=${API_KEY}`;
  const response = await fetch(url);

  if (!response.ok) {
    console.error("Failed to fetch NDVI history:", await response.text());
    return null;
  }

  const data = await response.json();

  if (!Array.isArray(data) || data.length === 0) {
    return null; // No satellite passes in the last 30 days
  }

  // Get the most recent pass (last element in the array)
  const latestPass = data[data.length - 1];
  return latestPass.data?.mean ?? null;
}

/**
 * Fetches real-time soil moisture and soil temperatures for a specific polygon
 */
export async function getSoilData(polygonId: string) {
  if (!API_KEY) return null;

  const url = `${BASE_URL}/soil?polyid=${polygonId}&appid=${API_KEY}`;
  const response = await fetch(url);

  if (!response.ok) {
    console.error("Failed to fetch soil data:", await response.text());
    return null;
  }

  const data = await response.json();
  return {
    moisture: data.moisture ?? null, // soil moisture in m3/m3
    surfaceTempC: data.t0 ? data.t0 - 273.15 : null, // convert Kelvin to Celsius
    depthTempC: data.t10 ? data.t10 - 273.15 : null, // convert Kelvin to Celsius
  };
}
