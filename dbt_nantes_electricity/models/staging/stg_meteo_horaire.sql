with source as (
    select * from {{ ref('stg_nantes_meteo_horaire') }}
)

select
    -- Modification type dates
    cast(date_heure as timestamp) as enregistrement_timestamp,

    -- Changement nom
    cast(temperature_c as float) as temperature_celsius,

    -- Divisions temporelles
    extract(year from cast(date_heure as timestamp)) as annee,
    extract(month from cast(date_heure as timestamp)) as mois,
    extract(hour from cast(date_heure as timestamp)) as heure

from source
