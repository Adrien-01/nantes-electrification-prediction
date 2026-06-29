import io
import pandas as pd
import requests
from pathlib import Path


def download_dataset(dataset_id, code_region="52"):
    url = f"https://opendata.reseaux-energies.fr/api/explore/v2.1/catalog/datasets/{dataset_id}/exports/csv"
    params = {"refine": f"code_insee_region:{code_region}", "delimiter": ","}

    print(f"⏳ Téléchargement du dataset : {dataset_id}...")
    response = requests.get(url, params=params)
    response.raise_for_status()
    return response.text


try:
    # 1. Téléchargement des deux sources
    csv_hist = download_dataset("eco2mix-regional-cons-def")
    csv_tr = download_dataset("eco2mix-regional-tr")

    # 2. Chargement dans des DataFrames Pandas
    df_hist = pd.read_csv(io.StringIO(csv_hist), sep=",")
    df_tr = pd.read_csv(io.StringIO(csv_tr), sep=",")

    # 3. Alignement des colonnes et concaténation
    # concat gère automatiquement les colonnes manquantes ou inversées
    df_total = pd.concat([df_hist, df_tr], ignore_index=True)

    # 4. Conversion et nettoyage de la colonne temporelle
    # Le champ clé d'ODRE s'appelle généralement 'date_heure' ou 'date' + 'heure'
    # On isole la date et l'heure pour créer un vrai type DateTime
    df_total["timestamp"] = pd.to_datetime(df_total["date_heure"], utc=True)

    # 5. Rééchantillonnage à l'heure (Resampling)
    # On regroupe par heure et on fait la moyenne pour les puissances (MW)
    # On met le timestamp en index temporairement pour utiliser resample
    df_hourly = (
        df_total.set_index("timestamp")
        .resample("1h")
        .mean(numeric_only=True)
        .reset_index()
    )

    # Récupération des colonnes textuelles basiques (comme le code insee) si besoin
    df_hourly["code_insee_region"] = 52

    # --- ENREGISTREMENT DU SEED ---
    chemin_actuel = Path(__file__).resolve()
    racine_projet = next(
        p
        for p in chemin_actuel.parents
        if p.name == "nantes-electrification-prediction"
    )
    dossier_seeds = racine_projet / "dbt_nantes_electricity" / "seeds"
    dossier_seeds.mkdir(parents=True, exist_ok=True)

    nom_fichier_seed = dossier_seeds / "raw_rte_co2.csv"
    df_hourly.to_csv(nom_fichier_seed, index=False, encoding="utf-8")

    print(f"✅ Fichier horaire harmonisé créé : {nom_fichier_seed}")

except Exception as e:
    print(f"💥 Échec : {e}")
