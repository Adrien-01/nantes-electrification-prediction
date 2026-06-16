with source as (
    select * from {{ ref('stg_nantes_consommation_horaire') }}
)

select
    -- Modification type dates
    cast(date_heure as timestamp) as enregistrement_timestamp,

    -- Changement nom
    cast(consommation as float) as MWh,


from source
