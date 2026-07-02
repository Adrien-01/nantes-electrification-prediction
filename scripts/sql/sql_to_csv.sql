COPY (
    SELECT * FROM main_mart.mart_consommation_horaire
) TO 'consommation_horaire_oneshot.csv' (
    HEADER true, 
    DELIMITER ',', 
    QUOTE '"', 
    ESCAPE '"'
);
