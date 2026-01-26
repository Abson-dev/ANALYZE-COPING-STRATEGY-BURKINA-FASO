use "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata_dummy.dta", replace


	
*----------------------------------------
* Political / violence shocks
*----------------------------------------
local pol_vars deadliness danger diffusion fragmentation

*----------------------------------------
* Food price shocks (inte, freq, spell)
*----------------------------------------
local food_vars ///
    zs_maize_inte zs_millet_inte zs_rice_inte zs_semolina_inte zs_sorghum_inte ///
    zs_cowpea_inte zs_peanut_inte zs_potato_inte zs_onion_inte zs_orange_inte ///
    zs_beef_inte zs_milkpowder_inte zs_vegoil_inte zs_sugar_inte zs_salt_inte ///
    zs_maize_freq zs_millet_freq zs_rice_freq zs_semolina_freq zs_sorghum_freq ///
    zs_cowpea_freq zs_peanut_freq zs_potato_freq zs_onion_freq zs_orange_freq ///
    zs_beef_freq zs_milkpowder_freq zs_vegoil_freq zs_sugar_freq zs_salt_freq ///
    zs_maize_spell zs_millet_spell zs_rice_spell zs_semolina_spell zs_sorghum_spell ///
    zs_cowpea_spell zs_peanut_spell zs_potato_spell zs_onion_spell zs_orange_spell ///
    zs_beef_spell zs_milkpowder_spell zs_vegoil_spell zs_sugar_spell zs_salt_spell

*----------------------------------------
* Climate hazard shocks
*----------------------------------------
local climate_vars R_drought R_flood R_heat R_composite

*----------------------------------------
* Rainy season performance
*----------------------------------------
local rainy_vars cdi_rainfall cdi_soilmoisture cdi_evapotranspiration cdi_combined

*----------------------------------------
* Extreme weather events (monthly)
*----------------------------------------

local ew_vars ///
    dry_freq_jun dry_spell_jun dry_freq_jul dry_spell_jul dry_freq_aug dry_spell_aug dry_freq_sep dry_spell_sep ///
    heavy_freq_jun heavy_spell_jun heavy_freq_jul heavy_spell_jul heavy_freq_aug heavy_spell_aug heavy_freq_sep heavy_spell_sep ///
    hot_freq_jun hot_spell_jun hot_freq_jul hot_spell_jul hot_freq_aug hot_spell_aug hot_freq_sep hot_spell_sep ///
    cold_freq_jun cold_spell_jun cold_freq_jul cold_spell_jul cold_freq_aug cold_spell_aug cold_freq_sep cold_spell_sep

*--- Événements météo extrêmes (Extreme Weather Jun-Sep) ---

* Définition des racines des variables
local types dry heavy hot cold
local metrics freq spell

foreach t in `types' {
    foreach m in `metrics' {
        * Calcul de la moyenne sur les 4 mois de culture
        egen `t'_`m'_juntosep = rowmean(`t'_`m'_jun `t'_`m'_jul `t'_`m'_aug `t'_`m'_sep)
        
        * Label de la variable agrégée
        local v_label = proper("`t'") + " " + "`m'" + " (Avg Jun-Sep)"
        label var `t'_`m'_juntosep "`v_label'"
    }
}	
* Liste des nouveaux indicateurs créés
local ew_indicators dry_freq_juntosep dry_spell_juntosep heavy_freq_juntosep heavy_spell_juntosep ///
                   hot_freq_juntosep hot_spell_juntosep cold_freq_juntosep cold_spell_juntosep

foreach ind in `ew_indicators' {
    * Calcul des statistiques descriptives nationales (pondérées)
    qui summ `ind' [aw=weight]
    local mu = r(mean)
    local sigma = r(sd)
    
    * Création de D1 : Choc léger (entre 1 et 2 écarts-types)
    gen D1_`ind' = (`ind' >= `mu' + `sigma' & `ind' < `mu' + 2*`sigma') if !missing(`ind')
    
    * Création de D2 : Choc sévère (plus de 2 écarts-types)
    gen D2_`ind' = (`ind' >= `mu' + 2*`sigma') if !missing(`ind')
    
    * Nettoyage des labels pour le tableau final
    label var D1_`ind' "Mild shock: `ind'"
    label var D2_`ind' "Severe shock: `ind'"
}
	
foreach v in `pol_vars' `food_vars' `climate_vars' `rainy_vars'  {
    qui summ `v' [aw=weight] // Utiliser les poids de sondage
    gen D1_`v' = (`v' >= r(mean) + r(sd)) & (`v' < r(mean) + 2*r(sd))
    gen D2_`v' = (`v' >= r(mean) + 2*r(sd))
    
    * Correction pour les variables de pluie (choc = manque)
    if strpos("`rainy_vars'", "`v'") > 0 {
        replace D1_`v' = (`v' <= r(mean) - r(sd)) & (`v' > r(mean) - 2*r(sd))
        replace D2_`v' = (`v' <= r(mean) - 2*r(sd))
    }
}	


/*----------------------------------------------------------------------------
  LABELS POUR LES VARIABLES DE CHOCS DICHOTOMISÉES (D1 & D2)
----------------------------------------------------------------------------*/

*--- Conflits et violence politique ---
label var D1_deadliness "Fatalities of political violence (mild)"
label var D2_deadliness "Fatalities of political violence (severe)"
label var D1_danger "Civilian-targeting events (mild)"
label var D2_danger "Civilian-targeting events (severe)"
label var D1_diffusion "Geographical spread of political violence (mild)"
label var D2_diffusion "Geographical spread of political violence (severe)"
label var D1_fragmentation "Rebel groups and militias (mild)"
label var D2_fragmentation "Rebel groups and militias (severe)"

*--- Intensité des prix (Intensity) ---
foreach c in maize millet rice sorghum cowpea peanut potato onion orange beef milkpowder vegoil sugar salt semolina {
    label var D1_zs_`c'_inte "`c'_intensity: Average price anomaly (mild)"
    label var D2_zs_`c'_inte "`c'_intensity: Average price anomaly (severe)"
}

*--- Fréquence des prix (Frequency) ---
foreach c in maize millet rice sorghum cowpea peanut potato onion orange beef milkpowder vegoil sugar salt semolina {
    label var D1_zs_`c'_freq "`c'_frequency: % months alert/crisis levels (mild)"
    label var D2_zs_`c'_freq "`c'_frequency: % months alert/crisis levels (severe)"
}

*--- Durée des prix (Spell) ---
foreach c in maize millet rice sorghum cowpea peanut potato onion orange beef milkpowder vegoil sugar salt semolina {
    label var D1_zs_`c'_spell "`c'_maxspell: Longest duration alert/crisis (mild)"
    label var D2_zs_`c'_spell "`c'_maxspell: Longest duration alert/crisis (severe)"
}

*--- Aléas climatiques (Climate Hazards) ---
label var D1_R_drought "Ratio of projected and historical  drought index (mild)"
label var D2_R_drought "Ratio of projected and historical  drought index (severe)"
label var D1_R_flood "Ratio of projected and historical  flood index (mild)"
label var D2_R_flood "Ratio of projected and historical  flood index (severe)"
label var D1_R_heat "Ratio of projected and historical  heat index (mild)"
label var D2_R_heat "Ratio of projected and historical  heat index (severe)"

*--- Performance saison des pluies (CDI) ---
label var D1_cdi_rainfall "Seasonal rainfall performance (mild)"
label var D2_cdi_rainfall "Seasonal rainfall performance (severe)"
label var D1_cdi_soilmoisture "Seasonal soil moisture performance (mild)"
label var D2_cdi_soilmoisture "Seasonal soil moisture performance (severe)"
label var D1_cdi_evapotranspiration "Seasonal evapotranspiration performance (mild)"
label var D2_cdi_evapotranspiration "Seasonal evapotranspiration performance (severe)"




*--- Liste de toutes les variables du Tableau 3 ---
local all_vars D1_deadliness D2_deadliness D1_danger D2_danger ///
               D1_diffusion D2_diffusion D1_fragmentation D2_fragmentation ///
               D1_zs_maize_inte D2_zs_maize_inte D1_zs_millet_inte D2_zs_millet_inte ///
               D1_zs_rice_inte D2_zs_rice_inte D1_zs_sorghum_inte D2_zs_sorghum_inte ///
               D1_R_drought D2_R_drought D1_R_flood D2_R_flood D1_R_heat D2_R_heat ///
               D1_cdi_rainfall D2_cdi_rainfall D1_cdi_soilmoisture D2_cdi_soilmoisture ///
               D1_dry_freq_juntosep D2_dry_freq_juntosep D1_heavy_freq_juntosep D2_heavy_freq_juntosep

* 1. Capture des statistiques
* Note: On n'utilise pas de poids [aw=] ici si on veut le N brut (Obs), 
* mais l'étude originale utilise souvent les poids pour le Mean/Std.
estpost summarize `all_vars', detail

* 2. Exportation vers RTF
esttab  using "Tableau3_Descriptive_Stats.rtf", ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") ///
    label ///
    nonumber ///
    nomtitle ///
    replace ///
    varlabels(`all_vars') ///
    collabels("Obs" "Mean" "Std" "Min" "Max") ///
    title("Table 3: Overview of dichotomized shock indicators, Burkina Faso (2018-2023) ")
/*
* Création d'une liste de toutes les variables D1 et D2 créées
unab d_vars : D1_* D2_*

* Commande pour afficher le tableau récapitulatif
estpost summarize `d_vars', listwise
esttab  using "Tableau3_Descriptive_StatsAll.rtf", ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") ///
    label ///
    nonumber ///
    nomtitle ///
    replace ///
    varlabels(`all_vars') ///
    collabels("Obs" "Mean" "Std" "Min" "Max") ///
    title("Table 3: Overview of dichotomized shock indicators, Burkina Faso (2018-2023) ")
	
*/	
save "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata_dummy.dta", replace	
	