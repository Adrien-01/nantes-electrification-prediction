import requests
import pandas as pd
from requests.adapters import HTTPAdapter
from urllib3.util import Retry
from pathlib import Path
from datetime import datetime, timezone

# Récupération de l'année en cours sous forme d'entier (int)
annee_actuelle = datetime.now(timezone.utc).year # Renvoie 2026 directement en entier

def get_jours_feries_fallback(annee_debut=2020, annee_fin=annee_actuelle):
    # Utilisation du domaine alternatif de secours gouvernemental
    url = "https://calendrier.api.gouv.fr/jours-feries/metropole.json"

    session = requests.Session()
    retries = Retry(total=2, backoff_factor=1)
    session.mount('https://', HTTPAdapter(max_retries=retries))

    try:
        response = session.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()

        # Le format ici est {'YYYY-MM-DD': 'Nom'}
        df = pd.DataFrame(list(data.items()), columns=["date_jour", "nom_ferie"])
        df["date_jour"] = pd.to_datetime(df["date_jour"]).dt.date

        # Filtre sur les années du projet énergétique
        df["annee"] = pd.to_datetime(df["date_jour"]).dt.year
        df = df[(df["annee"] >= annee_debut) & (df["annee"] <= annee_fin)].drop(columns=["annee"])

        return df

    except Exception as e:
        print(f"❌ Les deux API gouvernementales semblent indisponibles : {e}")
        print("💡 Plan C : Génération d'une table vide pour ne pas bloquer votre pipeline dbt")
        return pd.DataFrame(columns=["date_jour", "nom_ferie"])

# --- 1. EXÉCUTION DU SCRIPT (On récupère la donnée d'abord !) ---
df_feries = get_jours_feries_fallback()
print(f"✅ Récupération réussie : {len(df_feries)} jours fériés trouvés.")

# --- 2. GESTION DES CHEMINS AVEC PATHLIB ---
# Récupérer le dossier du script actuel
chemin_actuel = Path(__file__).resolve()

# Trouver la racine du projet
racine_projet = None
for parent in chemin_actuel.parents:
    if parent.name == "nantes-electrification-prediction":
        racine_projet = parent
        break

# Sécurité
if racine_projet is None:
    raise FileNotFoundError("Impossible de trouver le dossier racine 'nantes-electrification-prediction'")

# Construire le chemin vers le dossier seeds
dossier_seeds = racine_projet / "dbt_nantes_electricity" / "seeds"
dossier_seeds.mkdir(parents=True, exist_ok=True)

# --- 3. SAUVEGARDE DES FICHIERS ---
# Sauvegarde directe dans le dossier SEEDS de dbt sous le bon nom (raw_jours_feries)
nom_fichier_seed = dossier_seeds / "raw_jours_feries.csv"
df_feries.to_csv(nom_fichier_seed, index=False, sep=",", encoding="utf-8")
print(f"💾 Fichier Seed enregistré dans : {nom_fichier_seed}")

# Optionnel : votre sauvegarde locale de secours
df_feries.to_csv("raw_jours_feries.csv", index=False)
