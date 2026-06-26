type ET0Input = {
  tMin: number;
  tMax: number;
  tMean: number;
  humidity: number;
  windSpeed: number;
  solarRadiation: number;
};

export function calculateET0(input: ET0Input): number {
  const { tMin, tMax, tMean, humidity, windSpeed, solarRadiation } = input;

  const delta =
    (4098 * (0.6108 * Math.exp((17.27 * tMean) / (tMean + 237.3)))) /
    Math.pow(tMean + 237.3, 2);

  const gamma = 0.665 * 0.1013;

  const esTmax = 0.6108 * Math.exp((17.27 * tMax) / (tMax + 237.3));
  const esTmin = 0.6108 * Math.exp((17.27 * tMin) / (tMin + 237.3));
  const es = (esTmax + esTmin) / 2;
  const ea = es * (humidity / 100);

  const rn = solarRadiation;
  const g = 0;

  const et0 =
    (0.408 * delta * (rn - g) +
      gamma * (900 / (tMean + 273)) * windSpeed * (es - ea)) /
    (delta + gamma * (1 + 0.34 * windSpeed));

  return Number(Math.max(et0, 0).toFixed(2));
}