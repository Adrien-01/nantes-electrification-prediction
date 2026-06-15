# Nantes Electrification & Thermosensitivity Prediction

## 🎯 Objectif du Projet
Ce projet est un outil d'aide à la décision conçu pour les élus et les services techniques de **Nantes Métropole**. Il vise à analyser et prédire l'impact de l'augmentation des températures estivales (vagues de chaleur, canicules) sur la consommation globale d'électricité du territoire à l'horizon 2035/2050 (scénarios du GIEC).

L'objectif est de quantifier la **thermosensibilité estivale** nantaise pour aider à la planification des infrastructures, du réseau électrique et à la priorisation des budgets de rénovation thermique des bâtiments publics.

## 🛠️ Stack Technique & Architecture
* **Ingestion & Data Prep :** Python (Pandas) pour la récupération automatique des données d'API.
* **Transformation & Métriques :** `dbt` (Data Build Tool) pour le nettoyage, le rééchantillonnage horaire et la modélisation sémantique.
* **Data Warehouse :** duckdb.
* **Machine Learning :** Python (Scikit-Learn) pour la modélisation prédictive (Régression / Gradient Boosting).

## 🗂️ Structure du Dépôt
* `data/` : Contient les fichiers de données brutes.
* `dbt_nantes_electricity/` : Requêtes d'agrégation dbt.
* `notebooks/` : Scripts Python d'ingestion, Analyses exploratoires, corrélations Consommation vs Températures et entraînement du modèle de ML.
* `sql/` : Modèles d'analyse.
* `output/` : Graphiques de prévision et KPIs pour les décideurs publics.

## 📊 Données Utilisées
1. **Consommation Électrique :** Données horaires issues d'Éco2mix Métropoles (Plateforme ODRE - Enedis/RTE).
2. **Historique Météo :** Relevés horaires de la station Nantes-Atlantique (API Open-Meteo).
3. **Projections Climatiques :** Scénarios GIEC (RCP 4.5 / 8.5) à l'horizon 2035 et 2050 via le portail DRIAS Climat.

## 🚀 Comment exécuter le projet
