import { formatPlot } from "@/lib/datasets";
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export async function POST(request: Request) {
  try {
    const { userId, message } = await request.json();

    if (!message) {
      return NextResponse.json(
        { error: "Le message de l'utilisateur est obligatoire." },
        { status: 400 }
      );
    }

    // 1. Fetch plots and crops for this user
    let plotsData: any[] = [];
    if (userId) {
      const { data: plots, error: plotsError } = await supabase
        .from("plots")
        .select(`
          id,
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
        .eq("user_id", userId);

      if (plots && !plotsError) {
        plotsData = plots.map(formatPlot);
      }
    }

    // 2. Fetch recent irrigation recommendations
    let recommendationsData: any[] = [];
    if (plotsData.length > 0) {
      const plotIds = plotsData.map((p) => p.id);
      const { data: recs, error: recsError } = await supabase
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
            nom
          )
        `)
        .in("plot_id", plotIds)
        .order("date", { ascending: false })
        .limit(5);

      if (recs && !recsError) {
        recommendationsData = recs;
      }
    }

    // 3. Build text context for the AI
    let context = "Voici les informations sur les parcelles de l'agriculteur :\n";
    if (plotsData.length > 0) {
      plotsData.forEach((plot: any) => {
        context += `- Parcelle: "${plot.nom}", Culture: "${plot.crops?.nom || "Non spécifiée"}", Superficie: ${plot.superficie} ha, Type de sol: "${plot.type_sol}", Localisation: "${plot.localisation || "Non spécifiée"}" (Lat: ${plot.latitude || "N/A"}, Lon: ${plot.longitude || "N/A"})\n`;
      });
    } else {
      context += "L'agriculteur n'a configuré aucune parcelle pour le moment.\n";
    }

    if (recommendationsData.length > 0) {
      context += "\nHistorique récent des recommandations d'irrigation calculées :\n";
      recommendationsData.forEach((rec: any) => {
        context += `- Date: ${rec.date}, Parcelle: "${rec.plots?.nom || "Inconnue"}", Volume d'eau recommandé: ${rec.quantite_eau} m³, Durée d'irrigation: ${rec.duree_irrigation} heures (${rec.frequence}), Message: "${rec.message}" (Calculé avec ET0: ${rec.et0} mm/j, ETc: ${rec.etc} mm/j)\n`;
      });
    }

    // 4. Try using Gemini API if GEMINI_API_KEY is configured
    const geminiApiKey = process.env.GEMINI_API_KEY;

    if (geminiApiKey) {
      try {
        const systemPrompt = `
Tu es l'assistant agricole intelligent de l'application HydroSmart, un outil premium d'aide à la décision d'irrigation pour les agriculteurs de la région Souss-Massa au Maroc.
Tu dois répondre de manière polie, professionnelle et chaleureuse. Utilise le tutoiement amical ("tu") adapté à un assistant de confiance. Réponds en français (ou en arabe si la question est en arabe).
Sois précis, concret, et base-toi en priorité sur les données réelles fournies ci-dessous concernant les parcelles du fermier.

Contexte des données actuelles du fermier :
${context}

Directives de réponse :
1. Si le fermier pose une question sur ses parcelles, ses cultures ou ses recommandations, réponds en utilisant précisément les chiffres et informations fournis dans le contexte ci-dessus.
2. Si le fermier pose des questions d'ordre général sur l'agriculture ou l'irrigation (ex: "qu'est-ce que l'ET0 ?"), réponds de manière éducative, simple et claire, en faisant le lien avec ses propres données si possible.
3. Formate tes réponses en Markdown élégant (listes à puces, gras, etc.) pour qu'elles soient très lisibles sur l'application mobile.
4. Reste concis (150-200 mots maximum) : évite le blabla et va droit au but.
5. Si l'agriculteur n'a pas de données ou parcelles correspondantes, explique-lui gentiment comment en ajouter dans l'application.
`;

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiApiKey}`;
        const response = await fetch(geminiUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            contents: [
              {
                parts: [
                  {
                    text: `Prompt utilisateur: "${message}"`
                  }
                ]
              }
            ],
            systemInstruction: {
              parts: [
                {
                  text: systemPrompt
                }
              ]
            }
          }),
        });

        if (response.ok) {
          const resData = await response.json();
          const replyText = resData.candidates?.[0]?.content?.parts?.[0]?.text;
          if (replyText) {
            return NextResponse.json({ reply: replyText });
          }
        }
        console.warn("Gemini API returned non-OK status, falling back to local NLP engine.");
      } catch (err) {
        console.error("Failed to connect to Gemini API, falling back to local NLP engine:", err);
      }
    }

    // 5. Fallback local NLP engine
    const textLower = message.toLowerCase();
    let reply = "";

    // Welcome and greetings
    if (
      textLower.includes("bonjour") ||
      textLower.includes("salut") ||
      textLower.includes("hello") ||
      textLower.includes("hi") ||
      textLower.includes("aide") ||
      textLower.includes("help")
    ) {
      reply = `Bonjour 👋 ! Je suis l'assistant intelligent **HydroSmart**. Je suis là pour t'aider à gérer l'irrigation de tes parcelles et comprendre les données agricoles.

Voici quelques questions que tu peux me poser :
- 📊 *Quelles sont mes parcelles actives ?*
- 💧 *Quels sont les besoins en eau de mes cultures aujourd'hui ?*
- 🌦️ *Comment la météo affecte-t-elle mes parcelles ?*
- 🌾 *Qu'est-ce que l'ET0 et l'ETc et comment les calculez-vous ?*
- 📈 *Montre-moi les dernières recommandations d'irrigation.*

Que puis-je faire pour toi aujourd'hui ?`;
    }
    // Plots and crops list
    else if (
      textLower.includes("parcelle") ||
      textLower.includes("champ") ||
      textLower.includes("verger") ||
      textLower.includes("plot") ||
      textLower.includes("culture") ||
      textLower.includes("cultur")
    ) {
      if (plotsData.length > 0) {
        reply = `Voici la liste de tes parcelles enregistrées sur **HydroSmart** :

`;
        plotsData.forEach((plot) => {
          reply += `- **${plot.nom}** : ${plot.superficie} ha de **${plot.crops?.nom || "culture inconnue"}** (Sol : *${plot.type_sol}*). Située à *${plot.localisation || "Localisation non définie"}*.\n`;
        });
        reply += `\nTu peux ajouter ou modifier des parcelles depuis l'onglet **Mes Parcelles** ou directement à partir de la carte.`;
      } else {
        reply = `Tu n'as pas encore enregistré de parcelles. 

Pour commencer :
1. Rends-toi sur l'onglet **Accueil** ou **Mes Parcelles**.
2. Clique sur le bouton **Ajouter une parcelle** (+).
3. Indique le nom, la culture (Tomate, Agrumes, Olivier...), la superficie et la localisation de ton terrain.`;
      }
    }
    // Irrigation needs and recommendations
    else if (
      textLower.includes("irrigation") ||
      textLower.includes("eau") ||
      textLower.includes("arroser") ||
      textLower.includes("besoin") ||
      textLower.includes("recommandation") ||
      textLower.includes("quantité") ||
      textLower.includes("quantite")
    ) {
      if (recommendationsData.length > 0) {
        reply = `Voici les dernières recommandations d'irrigation calculées pour tes parcelles :\n\n`;
        recommendationsData.forEach((rec) => {
          reply += `### 📍 Parcelle **${rec.plots?.nom || "Inconnue"}** (le ${rec.date})\n`;
          if (rec.quantite_eau > 0) {
            reply += `- **Volume d'eau requis** : \`${rec.quantite_eau} m³\` (soit ${rec.besoin_brut} mm)\n`;
            reply += `- **Durée estimée** : \`${rec.duree_irrigation} heures\` (${rec.frequence})\n`;
            reply += `- **Conseil** : *${rec.message}*\n\n`;
          } else {
            reply += `- **Statut** : \`Pas d'irrigation nécessaire\`\n`;
            reply += `- **Raison** : Les apports météo (pluie) ou l'humidité résiduelle du sol sont suffisants.\n\n`;
          }
        });
        reply += `*Note : Ces calculs sont mis à jour quotidiennement en combinant l'évapotranspiration de référence (ET0), le coefficient de la culture (Kc) et les précipitations.*`;
      } else {
        reply = `Je ne trouve pas de recommandation d'irrigation récente pour tes parcelles.

Pour en générer une :
1. Sélectionne ta parcelle sur l'écran **Accueil**.
2. Clique sur le bouton **Calculer l'irrigation**.
3. HydroSmart interrogera alors la météo en direct de ta commune et calculera précisément les besoins nets en eau.`;
      }
    }
    // Weather queries
    else if (
      textLower.includes("meteo") ||
      textLower.includes("météo") ||
      textLower.includes("pluie") ||
      textLower.includes("precip") ||
      textLower.includes("temps") ||
      textLower.includes("vent")
    ) {
      if (recommendationsData.length > 0) {
        const latest = recommendationsData[0];
        reply = `D'après les dernières données météo relevées sur ta parcelle **${latest.plots?.nom}** :
- **Précipitations récentes** : pris en compte dans le calcul.
- **Évapotranspiration de référence (ET0)** : \`${latest.et0} mm/jour\`.

La météo de la région de Souss-Massa influence directement la vitesse d'assèchement de tes sols. S'il pleut, HydroSmart déduit automatiquement les millimètres d'eau de pluie de ton besoin brut d'irrigation pour te faire économiser de l'eau.`;
      } else {
        reply = `Je n'ai pas de données météo en cache car aucune recommandation n'a été calculée récemment.

Pour consulter la météo de tes parcelles :
1. Assure-toi d'avoir configuré des coordonnées GPS correctes pour tes parcelles.
2. HydroSmart récupère les conditions en direct (température, vent, humidité) via OpenWeather pour estimer l'évapotranspiration.`;
      }
    }
    // ET0 / ETc calculations
    else if (
      textLower.includes("et0") ||
      textLower.includes("etc") ||
      textLower.includes("evapo") ||
      textLower.includes("coefficient") ||
      textLower.includes("kc")
    ) {
      reply = `### Comprendre le calcul de l'irrigation sur HydroSmart 🌾

Nous utilisons la méthode scientifique de la **FAO-56** (Penman-Monteith) pour modéliser le besoin en eau :

1. **ET0 (Évapotranspiration de Référence)** : C'est la quantité d'eau en mm/jour perdue par le sol et un gazon de référence sous l'effet du soleil, du vent, de la température et de l'humidité locale.
2. **Kc (Coefficient Cultural)** : Propre à chaque culture et à son stade de croissance. Par exemple :
   - Tomate (stade mi-saison) : $Kc \\approx 1.15$
   - Olivier : $Kc \\approx 0.70$
3. **ETc (Évapotranspiration de la Culture)** : C'est le besoin brut de ta plante :
   $$ETc = ET0 \\times Kc$$

**Formule finale du besoin d'irrigation :**
$$\\text{Besoin Net} = ETc - \\text{Pluie Efficace}$$
$$\\text{Besoin Brut} = \\frac{\\text{Besoin Net}}{\\text{Efficacité d'irrigation}}$$

Nous multiplions ensuite ce besoin brut (en mm) par la superficie de ta parcelle (en ha) pour obtenir le volume exact en mètres cubes ($m^3$).`;
    }
    // Default reply
    else {
      reply = `Je comprends ta question sur l'irrigation de ton exploitation. 

Pour t'aider au mieux, peux-tu préciser si tu souhaites :
1. Connaître la **liste de tes parcelles** enregistrées.
2. Voir les **recommandations d'arrosage** (m³ d'eau et heures) calculées pour aujourd'hui.
3. Comprendre comment nous calculons les besoins (formule **ET0 et ETc**).
4. Avoir des détails météo de tes localisations.`;
    }

    return NextResponse.json({ reply });
  } catch (error) {
    console.error("Chatboot API error:", error);
    return NextResponse.json(
      { error: "Une erreur est survenue lors du traitement du message." },
      { status: 500 }
    );
  }
}
