with staging as (
    select * from {{ ref('stg_rte_horaire') }}
)

select
    timestamp_heure,
    consommation_mw,
    prod_thermique_mw,

    -- Application du facteur ADEME (400g CO2 / kWh pour le thermique de pointe)
    case
        when consommation_mw > 0 then
            round((prod_thermique_mw * 400.0) / consommation_mw, 2)
        else 0.0
    end as taux_co2_g_kwh,

    -- Calcul de la part des énergies renouvelables injectées localement
    case
        when consommation_mw > 0 then
            round(((prod_eolienne_mw + prod_solaire_mw + prod_hydraulique_mw + prod_bioenergies_mw) / consommation_mw) * 100, 2)
        else 0.0
    end as part_enr_pourcentage

from staging
