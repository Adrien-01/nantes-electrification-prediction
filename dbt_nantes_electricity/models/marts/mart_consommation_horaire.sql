with

-- 1. Import des tables de staging et intermédiaires
conso_horaire as (
    select
        enregistrement_timestamp,
        MWh as consommation_mwh
    from {{ ref('stg_conso_horaire') }}
),

meteo_horaire as (
    select
        enregistrement_timestamp, -- Correction du "s"
        temperature_celsius,
        annee,
        mois,
        heure
    from {{ ref('stg_meteo_horaire') }}
),

co2_regional as (
    select
        timestamp_heure,
        taux_co2_g_kwh,
        part_enr_pourcentage
    from {{ ref('int_rte_co2_enrichi') }} -- Notre modèle de calcul ADEME
),

jours_feries as (
    select
        date_jour,
        nom_ferie
    from {{ ref('stg_feries') }}
),

-- 2. Jointure principale et enrichissement des dimensions temporelles
jointure_et_dimensions as (
    select
        conso.enregistrement_timestamp as timestamp,
        meteo.annee,
        meteo.mois,
        meteo.heure,
        conso.consommation_mwh,
        meteo.temperature_celsius,

        -- Ajout des indicateurs RTE (Jointure horaire)
        co2.taux_co2_g_kwh,
        co2.part_enr_pourcentage,

        -- Extraction du jour de la semaine
        extract(dayofweek from conso.enregistrement_timestamp) as index_jour_semaine,

        case extract(dayofweek from conso.enregistrement_timestamp)
            when 1 then 'Dimanche'
            when 2 then 'Lundi'
            when 3 then 'Mardi'
            when 4 then 'Mercredi'
            when 5 then 'Jeudi'
            when 6 then 'Vendredi'
            when 7 then 'Samedi'
        end as nom_jour_semaine,

        case
            when extract(dayofweek from conso.enregistrement_timestamp) in (1, 7) then 'Week-end'
            else 'Semaine'
        end as type_jour,

        -- Ajout du flag jour férié (Jointure à la date)
        case
            when feries.date_jour is not null then true
            else false
        end as est_ferie,
        coalesce(feries.nom_ferie, 'Jour Ouvré') as libelle_jour_special

    from conso_horaire as conso
    inner join meteo_horaire as meteo
        on conso.enregistrement_timestamp = meteo.enregistrement_timestamp
    left join co2_regional as co2
        on conso.enregistrement_timestamp = co2.timestamp_heure
    left join jours_feries as feries
        -- On cast le timestamp horaire en DATE pour matcher le référentiel des jours fériés
        on cast(conso.enregistrement_timestamp as date) = feries.date_jour
),

-- 3. Calculs des fenêtres analytiques (Normales de saison)
_mart_final as (
    select
        t.timestamp,
        t.annee,
        t.mois,
        t.nom_jour_semaine,
        t.type_jour,
        t.est_ferie,
        t.libelle_jour_special,
        t.heure,
        t.consommation_mwh,
        t.temperature_celsius,
        t.taux_co2_g_kwh,
        t.part_enr_pourcentage,

        -- Moyenne par mois/heure sur tout l'historique
        avg(t.temperature_celsius) over(partition by t.mois, t.heure) as temperature_normale_saison_celsius
    from jointure_et_dimensions as t
)

-- 4. Output final ordonné avec écart à la normale
select
    *,
    round(temperature_celsius - temperature_normale_saison_celsius, 2) as ecart_a_la_normale_celsius
from _mart_final
order by timestamp
