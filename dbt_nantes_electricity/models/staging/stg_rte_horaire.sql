with source as (
    select * from {{ ref('raw_rte_co2') }}
),

filtrage_et_typage as (
    select
        cast(timestamp as timestamp) as timestamp_heure,
        cast(consommation as double) as consommation_mw,
        cast(thermique as double) as prod_thermique_mw,
-- On additionne le terrestre et l'offshore en sécurisant avec un coalesce
        cast(
            coalesce(eolien_terrestre, 0) + coalesce(eolien_offshore, 0)
            as double
        ) as prod_eolienne_mw,
        cast(solaire as double) as prod_solaire_mw,
        cast(nucleaire as double) as prod_nucleaire_mw,
        cast(hydraulique as double) as prod_hydraulique_mw,
        cast(bioenergies as double) as prod_bioenergies_mw
    from source
    where consommation is not null
)

-- Gestion des rares doublons de l'API (changement d'heure, recalculs)
select
    timestamp_heure,
    -- On prend le max en cas de doublon pour privilégier la donnée consolidée si elle existe
    max(consommation_mw) as consommation_mw,
    max(prod_thermique_mw) as prod_thermique_mw,
    max(prod_eolienne_mw) as prod_eolienne_mw,
    max(prod_solaire_mw) as prod_solaire_mw,
    max(prod_nucleaire_mw) as prod_nucleaire_mw,
    max(prod_hydraulique_mw) as prod_hydraulique_mw,
    max(prod_bioenergies_mw) as prod_bioenergies_mw
from filtrage_et_typage
group by timestamp_heure
