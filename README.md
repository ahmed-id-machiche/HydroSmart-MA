# HydroSmart

HydroSmart est un projet de gestion agricole centré sur l'irrigation intelligente. Le depot contient deux applications qui partagent la meme logique metier et la meme base de donnees:

- une application web d'administration construite avec `Next.js`
- une application mobile agriculteur construite avec `Flutter`

Les deux applications s'appuient sur `Supabase` pour stocker les agriculteurs, les parcelles, les donnees meteo, les recommandations d'irrigation et l'historique.

## Vue d'ensemble

Le projet suit ce flux principal:

1. un agriculteur est cree et authentifie
2. des parcelles sont associees a cet agriculteur
3. des donnees meteo sont recuperees ou saisies
4. le systeme calcule `ET0`
5. le moteur d'irrigation calcule `ETc`, le besoin net, le besoin brut et le volume d'eau
6. la recommandation est enregistree dans Supabase
7. l'action est aussi envoyee dans l'historique d'irrigation

## Structure du depot

```text
HydroSmart/
|-- Web/
|   `-- app/                  # application web Next.js
|       |-- app/              # pages App Router + routes API
|       |-- components/       # composants React reutilisables
|       |-- lib/              # logique metier et acces externes
|       |-- public/           # assets statiques
|       `-- package.json
|-- Mobile/
|   `-- appp/                 # application mobile Flutter
|       |-- lib/
|       |   |-- config/       # configuration API et Supabase
|       |   |-- constants/    # couleurs et constantes UI
|       |   |-- models/       # modeles de donnees
|       |   |-- screens/      # ecrans de l'application
|       |   |-- services/     # appels HTTP et orchestration
|       |   `-- widgets/      # widgets reutilisables
|       `-- pubspec.yaml
`-- README.md
```

## Partie web

La partie web se trouve dans `Web/app`. C'est une application `Next.js 16` avec `React 19`, `TypeScript`, `Tailwind CSS` et `Recharts`.

### Organisation

- `Web/app/app/layout.tsx`
  Point d'entree global de l'application web. Il charge les polices et encapsule toutes les pages.

- `Web/app/components/Sidebar.tsx`
  Barre laterale de navigation. Elle relie les pages `dashboard`, `plots`, `weather`, `recommendations` et `history`.

- `Web/app/app/dashboard/page.tsx`
  Tableau de bord administrateur. Cette page appelle `/api/users-summary`, agrege les informations et affiche:
  - le nombre d'agriculteurs
  - le nombre de parcelles
  - le nombre de recommandations
  - le volume d'eau total
  - des graphiques par agriculteur
  - les dernieres recommandations et l'historique

- `Web/app/app/plots/page.tsx`
  Gestion des parcelles. La page charge les cultures et les parcelles, affiche la liste et permet d'ajouter une parcelle.

- `Web/app/app/weather/page.tsx`
  Gestion des donnees meteo. La page peut:
  - lister les mesures existantes
  - recuperer la meteo via OpenWeather selon la latitude/longitude d'une parcelle
  - enregistrer ces valeurs dans Supabase

- `Web/app/app/recommendations/page.tsx`
  Generation des recommandations d'irrigation. Cette page orchestre tout le calcul:
  - lecture de la parcelle choisie
  - recuperation de la meteo correspondante
  - calcul de `ET0`
  - appel du moteur de recommandation
  - sauvegarde de la recommandation
  - ajout dans l'historique

- `Web/app/app/history/page.tsx`
  Consultation de l'historique d'irrigation enregitre.

### Bibliotheques metier

- `Web/app/lib/supabase.ts`
  Cree le client Supabase a partir des variables d'environnement `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_ANON_KEY`.

- `Web/app/lib/openweather.ts`
  Contient l'acces a l'API OpenWeather. La fonction `fetchCurrentWeather(lat, lon)` renvoie une structure simplifiee pour le projet:
  - temperature
  - humidite
  - vitesse du vent
  - precipitation
  - rayonnement solaire

- `Web/app/lib/et0-calculator.ts`
  Contient `calculateET0()`. Cette fonction implemente un calcul d'evapotranspiration de reference a partir de:
  - `tMin`
  - `tMax`
  - `tMean`
  - `humidity`
  - `windSpeed`
  - `solarRadiation`

- `Web/app/lib/irrigation-engine.ts`
  Contient `generateIrrigationRecommendation()`. C'est le coeur metier du projet. La fonction calcule:
  - `etc = et0 * kc`
  - `netNeedMm = max(etc - rainfall, 0)`
  - `grossNeedMm = netNeedMm / irrigationEfficiency`
  - `volumeM3 = grossNeedMm * surfaceHectare * 10`

  Elle retourne aussi un message metier et un indicateur `shouldIrrigate`.

### Routes API web

Les routes se trouvent dans `Web/app/app/api`. Elles servent de couche entre le frontend web, l'application mobile et Supabase.

- `/api/farmers`
  Cree, lit et met a jour les profils agriculteurs.

- `/api/plots`
  Lit et cree les parcelles. Le `GET` peut filtrer par `userId`.

- `/api/crops`
  Retourne la liste des cultures.

- `/api/weather-data`
  Lit et enregistre les donnees meteo associees aux parcelles.

- `/api/weather/openweather`
  Proxy interne vers OpenWeather. Evite d'exposer la cle API au client.

- `/api/calculate-et0`
  Expose le calcul de `ET0`.

- `/api/recommendations`
  Expose le moteur de recommandation d'irrigation.

- `/api/irrigation-recommendations`
  Lit et enregistre les recommandations d'irrigation.

- `/api/irrigation-history`
  Lit et enregistre l'historique des actions d'irrigation.

- `/api/users-summary`
  Construit une vue admin consolidee par agriculteur a partir de plusieurs tables Supabase.

## Partie mobile

La partie mobile se trouve dans `Mobile/appp`. C'est une application `Flutter` destinee a l'agriculteur final.

### Point d'entree

- `Mobile/appp/lib/main.dart`
  Initialise Supabase puis lance `HydroSmartApp`.

- `Mobile/appp/lib/screens/splash_screen.dart`
  Ecran de demarrage qui decide si l'utilisateur doit aller vers l'authentification ou l'application principale.

- `Mobile/appp/lib/screens/sign_in_screen.dart`
  Gere la connexion et l'inscription via Supabase Auth. Lors de la creation d'un compte, le mobile appelle aussi l'API web pour creer le profil agriculteur.

- `Mobile/appp/lib/screens/main_navigation.dart`
  Navigation principale avec 5 sections:
  - `Home`
  - `Analyse`
  - `Fields`
  - `History`
  - `Profile`

### Ecrans principaux

- `home_screen.dart`
  Ecran d'accueil. Il charge la position GPS, tente une geolocalisation humaine du lieu, recupere la meteo via l'API web et affiche aussi quelques parcelles de l'utilisateur.

- `analyse_screen.dart`
  Ecran metier principal cote mobile. Il selectionne une parcelle, recupere la meteo, calcule `ET0`, genere la recommandation, l'enregistre et affiche le resultat.

- `fields_screen.dart`
  Liste les parcelles de l'utilisateur et permet d'ouvrir l'ajout ou le detail d'une parcelle.

- `add_field_screen.dart`
  Formulaire d'ajout d'une parcelle. Il charge les cultures, ouvre une carte pour choisir la localisation GPS puis appelle l'API `/api/plots`.

- `map_picker_screen.dart`
  Selection manuelle d'un point GPS avec carte.

- `field_details_screen.dart`
  Affiche le detail d'une parcelle et les informations utiles pour l'irrigation.

- `history_screen.dart`
  Affiche l'historique d'irrigation du compte courant.

- `profile_screen.dart`
  Affiche les informations de l'utilisateur et gere la deconnexion.

### Services et modeles

- `Mobile/appp/lib/services/api_services.dart`
  Fichier central de communication avec le backend. Il:
  - recupere l'utilisateur courant depuis Supabase
  - appelle les routes API Next.js
  - orchestre tout le flux de recommandation dans `generateRecommendationForPlot()`

  Cette methode fait presque tout le pipeline metier:
  - recupere la meteo de la parcelle
  - calcule `ET0`
  - appelle le moteur de recommandation
  - sauvegarde la recommandation
  - sauvegarde l'historique

- `Mobile/appp/lib/models/plot.dart`
  Modele Dart d'une parcelle avec la culture associee et les coordonnees GPS.

- `Mobile/appp/lib/models/crop.dart`
  Modele d'une culture avec son coefficient `Kc`.

- `Mobile/appp/lib/models/weather_data.dart`
  Modele d'une observation meteo enregistree.

- `Mobile/appp/lib/config/api_config.dart`
  Definit l'URL du backend web. Par defaut, elle vise `http://10.0.2.2:3000` pour l'emulateur Android.

- `Mobile/appp/lib/config/supabase_config.dart`
  Contient l'URL et la cle publique Supabase utilisees par l'application mobile.

## Flux de code le plus important

Le coeur fonctionnel du projet est la generation d'une recommandation d'irrigation.

### Depuis le web

1. l'utilisateur choisit une parcelle dans `app/recommendations/page.tsx`
2. la page lit la derniere meteo disponible
3. elle appelle `/api/calculate-et0`
4. elle appelle `/api/recommendations`
5. elle enregistre le resultat dans `/api/irrigation-recommendations`
6. elle ajoute une ligne dans `/api/irrigation-history`

### Depuis le mobile

1. l'utilisateur choisit une parcelle dans `analyse_screen.dart`
2. `ApiService.generateRecommendationForPlot()` recupere la meteo OpenWeather
3. le mobile appelle `/api/calculate-et0`
4. le mobile appelle `/api/recommendations`
5. le mobile sauvegarde la recommandation
6. le mobile sauvegarde l'historique

## Tables et donnees manipulees

D'apres le code, les principales tables attendues dans Supabase sont:

- `farmers`
- `plots`
- `crops`
- `weather_data`
- `irrigation_recommendations`
- `irrigation_history`

Relations principales:

- un `farmer` possede plusieurs `plots`
- un `plot` reference une `crop`
- un `plot` possede plusieurs entrees `weather_data`
- un `plot` possede plusieurs `irrigation_recommendations`
- `irrigation_history` peut referencer une recommandation

## Technologies

### Web

- `Next.js 16`
- `React 19`
- `TypeScript`
- `Tailwind CSS`
- `Recharts`
- `Supabase JS`

### Mobile

- `Flutter`
- `supabase_flutter`
- `http`
- `geolocator`
- `geocoding`
- `flutter_map`

## Ce qu'il faut retenir dans le code

- le web joue deux roles: interface admin et petit backend applicatif
- le mobile ne parle pas directement a la logique metier: il passe par les routes API du web
- la logique metier importante est centralisee dans `et0-calculator.ts` et `irrigation-engine.ts`
- Supabase est la source de verite pour les donnees metier
- les coordonnees GPS des parcelles sont importantes pour recuperer la meteo reelle

## Pistes d'amelioration visibles dans le code

- uniformiser les composants de navigation web, car certaines pages utilisent `Sidebar` et d'autres ont une sidebar ecrite directement dans la page
- corriger les textes contenant des problemes d'encodage visibles dans plusieurs fichiers
- centraliser davantage les types partages entre pages web
- documenter le schema Supabase avec un fichier SQL ou un diagramme de donnees
- ajouter des tests sur le calcul de `ET0` et le moteur d'irrigation

Install lefleat pour le map dans dashboard
npm install leaflet
npm install -D @types/leaflet
