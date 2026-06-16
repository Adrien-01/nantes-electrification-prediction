with source as (
    select * from {{ ref('raw_jours_feries') }}
)

select
    cast(date_jour as date) as date_jour,
    cast(nom_ferie as string) as nom_ferie
from source
