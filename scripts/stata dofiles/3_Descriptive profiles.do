use "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata_dummy.dta", replace


/*
*------------------------------------------------------------
* 0. Define wave labels
*------------------------------------------------------------
label define wave_lbl ///
    3  "feb-mar2019" ///
    4  "sep-oct2019" ///
    5  "feb-mar2020" ///
    7  "feb-mar2021" ///
    8  "sep-oct2021" ///
    9  "feb-mar2022" ///
    10 "sep-oct2022" ///
    11 "feb-mar2023" ///
    12 "sep-oct2023", replace

label values wave wave_lbl

*------------------------------------------------------------
* 1. Count observations by department and wave
*------------------------------------------------------------
gen one = 1
collapse (sum) n_obs = one, by(admin1name admin2name wave)

*------------------------------------------------------------
* 2. Reshape to wide (waves as columns)
*------------------------------------------------------------
reshape wide n_obs, i(admin1name admin2name) j(wave)

*------------------------------------------------------------
* 3. Rename columns to valid wave names
*------------------------------------------------------------
foreach var of varlist n_obs* {
    local num = substr("`var'", 6, .)                     // Extract wave number
    local lbl : label wave_lbl `num'                      // Get label, e.g., "feb-mar2019"
    local lbl2 = "wave_" + subinstr("`lbl'", "-", "_", .) // Replace - with _
    local lbl2 = subinstr("`lbl2'", " ", "_", .)         // Replace spaces with _
    rename `var' `lbl2'
}

*------------------------------------------------------------
* 4. Row totals (department totals)
*------------------------------------------------------------
egen TOTAL = rowtotal(wave_*)   // sum all wave columns

*------------------------------------------------------------
* 5. Grand total row
*------------------------------------------------------------
preserve
collapse (sum) wave_* TOTAL
gen admin1name = "TOTAL"
gen admin2name = ""
tempfile total
save `total'
restore

append using `total'

*------------------------------------------------------------
* 6. Sort for presentation: TOTAL at bottom
*------------------------------------------------------------
gen sort_order = (admin1name=="TOTAL")
sort sort_order admin1name admin2name
drop sort_order

*------------------------------------------------------------
* 7. Export to Excel with labels
*------------------------------------------------------------
export excel using "Table1_ENSA_Burkina_2018_2023.xlsx", ///
    firstrow(variables) replace 

*/


local table2_vars ///
    D_Lcs_stress_DomAsset ///
    D_Lcs_stress_Saving ///
    D_Lcs_stress_EatOut ///
    D_Lcs_stress_BorrowCash ///
    D_Lcs_stress_Animals ///
    D_Lcs_crisis_ProdAssets ///
    D_Lcs_crisis_Edu_Health ///
    D_Lcs_crisis_OutSchool ///
    D_Lcs_crisis_Health ///
    D_Lcs_crisis_AgriCare ///
    D_Lcs_crisis_Seed ///
    D_Lcs_em_Migration ///
    D_Lcs_em_ResAsset ///
    D_Lcs_em_Begged ///
    D_Lcs_em_IllegalAct ///
    D_Lcs_em_FemAnimal ///
    D_rCSI_light ///
    D_rCSI_severe
	
	
*--- 1. Identifier si le ménage utilise au moins une stratégie (any_coping) ---
egen any_coping = rowmax(`table2_vars')
label var any_coping "Implementing at least one of the above coping strategies"

*--- 2. Compter le nombre de stratégies par ménage ---
egen nb_strategies = rowtotal(`table2_vars')
* On ne calcule la moyenne que pour ceux qui ont au moins une stratégie (selon la méthodologie IFPRI)
replace nb_strategies = . if any_coping == 0
label var nb_strategies "Average number of coping strategies (among those with at least one)"


*--- Labels pour les stratégies de stress ---
label var D_Lcs_stress_DomAsset "Selling household assets or goods"
label var D_Lcs_stress_Saving "Spending savings"
label var D_Lcs_stress_EatOut "Reducing expenses on food (eating out)"
label var D_Lcs_stress_BorrowCash "Borrowing money to cover food needs"
label var D_Lcs_stress_Animals "Selling animals more than usual"

*--- Labels pour les stratégies de crise ---
label var D_Lcs_crisis_ProdAssets "Selling productive assets or means of transport"
label var D_Lcs_crisis_Edu_Health "Reducing essential non-food expenditures"
label var D_Lcs_crisis_OutSchool "Withdrawing children from school"
label var D_Lcs_crisis_Health "Reducing health expenses"
label var D_Lcs_crisis_AgriCare "Reducing agricultural inputs"
label var D_Lcs_crisis_Seed "Consuming seed stocks"

*--- Labels pour les stratégies d'urgence ---
label var D_Lcs_em_Migration "Emergency migration"
label var D_Lcs_em_ResAsset "Mortgaging/selling the house or land"
label var D_Lcs_em_Begged "Begging or asking strangers for money/food"
label var D_Lcs_em_IllegalAct "Engaging in illegal activities"
label var D_Lcs_em_FemAnimal "Selling of last female animals"

/*
foreach v of local table2_vars {
    label variable `v' "`v'"
}
*/
*--- Labels pour la consommation et synthèse ---
label var D_rCSI_light "Lightly reducing food consumption (rCSI 4-18)"
label var D_rCSI_severe "Severely reducing food consumption (rCSI >= 19)"
label var any_coping "Implementing at least one of the above coping strategies"
label var nb_strategies "Average number of coping strategies (for active households)"

* 1. S'assurer que les variables sont sur une échelle de 0 à 100
foreach v in `table2_vars' any_coping {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1) // Évite de multiplier deux fois
}

* 2. Calculer les statistiques SANS listwise
* L'absence de 'listwise' permet d'utiliser toutes les données disponibles pour chaque cellule
estpost tabstat `table2_vars' any_coping nb_strategies [aw=weight], ///
    by(year) statistics(mean) columns(statistics)

* 3. Exporter le tableau avec les labels et les années en colonnes
esttab using "Tableau4_Burkina_Faso.rtf", ///
    cells("mean(fmt(1))") ///
    label ///
    unstack ///
    nonumber ///
    nomtitle ///
	collabels(none) ///
    replace ///
    addnotes("Note: To align with the prevailing context, the selection of the three most relevant crisis strategies has changed across the survey waves." "Source: Based on the integrated and enhanced dataset on food security and household coping strategies of Burkina Faso.") ///
    title("Table 4: Livelihood- and consumption-based strategies to cope with food insecurity, Burkina Faso (2019-2023) ")
	
	
	
	
*--- Liste des variables de chocs politiques ---
local pol_shocks D1_deadliness D2_deadliness D1_danger D2_danger ///
                 D1_diffusion D2_diffusion D1_fragmentation D2_fragmentation

*--- 1. Création de l'indicateur 'At least one shock' ---
egen any_pol_shock = rowmax(`pol_shocks')
label var any_pol_shock "At least one of the above shock types"

*--- 2. Nombre moyen de chocs (pour ceux qui en ont au moins un) ---
egen nb_pol_shocks = rowtotal(`pol_shocks')
replace nb_pol_shocks = . if any_pol_shock == 0
label var nb_pol_shocks "Average number of shocks among households facing at least one"
/*
*--- 3. Définition des Labels pour le tableau ---
label var D1_deadliness "D1_deadliness"
label var D2_deadliness "D2_deadliness"
label var D1_danger "D1_danger"
label var D2_danger "D2_danger"
label var D1_diffusion "D1_diffusion"
label var D2_diffusion "D2_diffusion"
label var D1_fragmentation "D1_fragmentation"
label var D2_fragmentation "D2_fragmentation"
*/	
* Conversion en % (0-100) pour l'affichage
foreach v in `pol_shocks' any_pol_shock {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1)
}

* 1. Calcul des statistiques par année
estpost tabstat `pol_shocks' any_pol_shock nb_pol_shocks [aw=weight], ///
    by(year) statistics(mean) columns(statistics)

* 2. Exportation du tableau propre
esttab using "Tableau5_Political_Violence.rtf", ///
    cells("mean(fmt(1))") ///  // 1 décimale
    label ///                 // Utilise les labels
    unstack ///               // Années en colonnes
    nonumber ///              // Pas de numéros de colonnes
    nomtitle ///              // Pas de titre de variable
    collabels(none) ///       // Supprime la ligne "mean"
    replace ///
    addnotes("Source: Based on political violence data merged with household surveys (Burkina Faso).") ///
    title("Table 5: Political violence shocks, Burkina Faso (2019-2023) ")
	
	
	
	
*--- Liste des variables de chocs de prix (Céréales et Légumineuses) ---
local price_shocks D1_zs_maize_inte D2_zs_maize_inte D1_zs_millet_inte D2_zs_millet_inte ///
                   D1_zs_rice_inte D2_zs_rice_inte D1_zs_sorghum_inte D2_zs_sorghum_inte ///
                   D1_zs_cowpea_inte D2_zs_cowpea_inte D1_zs_peanut_inte D2_zs_peanut_inte ///
                   D1_zs_maize_freq D2_zs_maize_freq D1_zs_millet_freq D2_zs_millet_freq ///
                   D1_zs_rice_freq D2_zs_rice_freq D1_zs_sorghum_freq D2_zs_sorghum_freq ///
                   D1_zs_cowpea_freq D2_zs_cowpea_freq D1_zs_peanut_freq D2_zs_peanut_freq ///
                   D1_zs_maize_spell D2_zs_maize_spell D1_zs_millet_spell D2_zs_millet_spell ///
                   D1_zs_rice_spell D2_zs_rice_spell D1_zs_sorghum_spell D2_zs_sorghum_spell ///
                   D1_zs_cowpea_spell D2_zs_cowpea_spell D1_zs_peanut_spell D2_zs_peanut_spell

*--- 1. Indicateur 'At least one price shock' ---
egen any_price_shock = rowmax(`price_shocks')
label var any_price_shock "At least one of the above shock types"

*--- 2. Nombre moyen de chocs (parmi ceux touchés) ---
egen nb_price_shocks = rowtotal(`price_shocks')
replace nb_price_shocks = . if any_price_shock == 0
label var nb_price_shocks "Average number of shocks among households facing at least one"
foreach v in `price_shocks' {
    label var `v' "`v'"
}

* Conversion en % pour les variables binaires
foreach v in `price_shocks' any_price_shock {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1)
}

* 1. Calculer les statistiques par année (ENSA Burkina Faso)
estpost tabstat `price_shocks' any_price_shock nb_price_shocks [aw=weight], ///
    by(year) statistics(mean) columns(statistics)

* 2. Exporter le tableau final
esttab using "Tableau6_Food_Prices.rtf", ///
    cells("mean(fmt(1))") ///  // 1 décimale comme dans l'étude
    label ///                 // Utilise les labels
    unstack ///               // Années en colonnes
    nonumber ///              // Pas de (1), (2)...
    nomtitle ///              // Pas de titre interne
    collabels(none) ///       // Supprime la ligne "mean" répétitive
    replace ///
    addnotes("Note: To align with the prevailing context, the selection of crops might change across survey waves." "Source: Based on the integrated and enhanced dataset of Burkina Faso (2018-2023).") ///
    title("Table 6: Food price shocks, Burkina Faso (2019-2023) ")
	
	
	
*--- Liste des variables de changement climatique (CC) ---
local cc_vars D1_R_drought D2_R_drought D1_R_flood D2_R_flood D1_R_heat D2_R_heat

*--- 1. Création de l'indicateur 'At least one CC shock' ---
egen any_cc_shock = rowmax(`cc_vars')
label var any_cc_shock "At least one of the above shock types"

*--- 2. Nombre moyen de chocs (parmi ceux touchés) ---
egen nb_cc_shocks = rowtotal(`cc_vars')
replace nb_cc_shocks = . if any_cc_shock == 0
label var nb_cc_shocks "Average number of shocks among households facing at least one"

*--- 3. Labels pour le tableau ---
foreach v in `cc_vars' {
    label var `v' "`v'"
}	
	

* Conversion en % (0-100)
foreach v in `cc_vars' any_cc_shock {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1)
}

* 1. Calcul des statistiques globales (Total)
estpost tabstat `cc_vars' any_cc_shock nb_cc_shocks [aw=weight], ///
    statistics(mean) columns(statistics)

* 2. Exportation du tableau
esttab . using "Tableau7_Climate_Change.rtf", ///
    cells("mean(fmt(1))") ///
    label ///
    nonumber ///
    nomtitle ///
    collabels(none) ///
    replace ///
    addnotes("Note: These indicators are based on long-term climate trends (30 years) and are constant across survey waves." "Source: Based on long-term climate data merged with household surveys (Burkina Faso).") ///
    title("Table 7: Climate change hazards, Burkina Faso (2019-2023) ")	
	
	
	
	
	
	
*--- Liste des variables de performance saisonnière (CDI) ---
local seasonal_vars D1_cdi_rainfall D2_cdi_rainfall ///
                    D1_cdi_soilmoisture D2_cdi_soilmoisture ///
                    D1_cdi_evapotranspiration D2_cdi_evapotranspiration

*--- 1. Indicateur 'At least one seasonal shock' ---
egen any_seasonal_shock = rowmax(`seasonal_vars')
label var any_seasonal_shock "At least one of the above shock types"

*--- 2. Nombre moyen de chocs (pour ceux touchés) ---
egen nb_seasonal_shocks = rowtotal(`seasonal_vars')
replace nb_seasonal_shocks = . if any_seasonal_shock == 0
label var nb_seasonal_shocks "Average number of shocks among households facing at least one"
/*
*--- 3. Libellés des variables ---
label var D1_cdi_rainfall "D1_cdi_rainfall"
label var D2_cdi_rainfall "D2_cdi_rainfall"
label var D1_cdi_soilmoisture "D1_cdi_soilmoisture"
label var D2_cdi_soilmoisture "D2_cdi_soilmoisture"
label var D1_cdi_evapotranspiration "D1_cdi_evapotranspiration"
label var D2_cdi_evapotranspiration "D2_cdi_evapotranspiration"
*/
* Conversion en % pour les indicateurs binaires
foreach v in `seasonal_vars' any_seasonal_shock {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1)
}

* 1. Calculer les statistiques par année
estpost tabstat `seasonal_vars' any_seasonal_shock nb_seasonal_shocks [aw=weight], ///
    by(year) statistics(mean) columns(statistics)

* 2. Exporter le tableau propre
esttab . using "Tableau8_Seasonal_Performance.rtf", ///
    cells("mean(fmt(1))") ///  // 1 décimale
    label ///                 // Utilise les labels
    unstack ///               // Années en colonnes
    nonumber ///              // Supprime (1), (2)...
    nomtitle ///              // Supprime le titre de variable
    collabels(none) ///       // Supprime la ligne "mean"
    replace ///
    addnotes("Source: Based on the seasonal performance indicators (CDI) merged with household surveys (Burkina Faso).") ///
    title("Table 8: Seasonal performance shocks, Burkina Faso (2019-2023) ")
	
	
*--- Liste des variables météo (D1 et D2) ---
local ew_shocks D1_dry_freq_juntosep D2_dry_freq_juntosep D1_dry_spell_juntosep D2_dry_spell_juntosep ///
                D1_heavy_freq_juntosep D2_heavy_freq_juntosep D1_heavy_spell_juntosep D2_heavy_spell_juntosep ///
                D1_hot_freq_juntosep D2_hot_freq_juntosep D1_hot_spell_juntosep D2_hot_spell_juntosep ///
                D1_cold_freq_juntosep D2_cold_freq_juntosep D1_cold_spell_juntosep D2_cold_spell_juntosep

*--- 1. Indicateur 'At least one extreme weather shock' ---
egen any_ew_shock = rowmax(`ew_shocks')
label var any_ew_shock "At least one of the above shock types"

*--- 2. Nombre moyen de chocs (parmi les ménages touchés) ---
egen nb_ew_shocks = rowtotal(`ew_shocks')
replace nb_ew_shocks = . if any_ew_shock == 0
label var nb_ew_shocks "Average number of shocks among households facing at least one"
foreach v in `ew_shocks' {
    label var `v' "`v'"
}

* Conversion en % (0-100)
foreach v in `ew_shocks' any_ew_shock {
    qui replace `v' = `v' * 100 if inlist(`v', 0, 1)
}

* 1. Calcul des statistiques par année
estpost tabstat `ew_shocks' any_ew_shock nb_ew_shocks [aw=weight], ///
    by(year) statistics(mean) columns(statistics)

* 2. Exportation vers RTF/Word
esttab . using "Tableau9_Extreme_Weather.rtf", ///
    cells("mean(fmt(1))") ///
    label ///
    unstack ///
    nonumber ///
    nomtitle ///
    collabels(none) ///
    replace ///
    addnotes("Source: Based on daily weather data (CHIRPS/ERA5) aggregated for Jun-Sep and merged with household surveys (Burkina Faso).") ///
    title("Table 9: Extreme weather shocks, Burkina Faso (2019-2023) ")
	

	
	
	



	
	
* PV : Political Violence
gen sh_PV = (any_pol_shock > 0)

* FP : Food Prices
gen sh_FP = (any_price_shock > 0)

* SP : Seasonal Performance (CDI)
gen sh_SP = (any_seasonal_shock > 0)

* EW : Extreme Weather (Jun-Sep)
gen sh_EW = (any_ew_shock > 0)

* CC : Climate Change (D1/D2 Long-term indicators)
* Note: Créez 'any_cc_shock' à partir des variables de changement climatique à long terme
gen sh_CC = (any_cc_shock > 0)


* Générer une variable qui liste les chocs subis par le ménage
gen shock_profile = ""
replace shock_profile = shock_profile + "PV " if sh_PV == 1
replace shock_profile = shock_profile + "FP " if sh_FP == 1
replace shock_profile = shock_profile + "CC " if sh_CC == 1
replace shock_profile = shock_profile + "SP " if sh_SP == 1
replace shock_profile = shock_profile + "EW " if sh_EW == 1

* Nettoyer les espaces et identifier les ménages sans choc
replace shock_profile = trim(shock_profile)
replace shock_profile = "No shocks" if shock_profile == ""

* Transformer en variable numérique avec labels pour le tableau
encode shock_profile, gen(shock_profile_n)


* 1. Vérification dans la console (Années en colonnes)
tab shock_profile_n year [aw=weight], col nofreq

* 2. Exportation propre vers Excel/Word
* Nous utilisons 'estpost' pour garder la cohérence avec vos autres tableaux
estpost tabulate shock_profile_n year [aw=weight]

esttab  using "Tableau10_Shock_Profile.rtf", ///
    cells("colpct(fmt(1))") ///  <-- Affiche le % en colonne avec 1 décimale
    unstack ///
    nonumber ///
    nomtitle ///
    collabels(none) ///
    label ///
    replace ///
    addnotes("Note: PV=Political Violence; FP=Food Price; CC=Climate Change; SP=Seasonal Performance; EW=Extreme Weather." ///
    "Given that the same climate change data have been assigned to all waves, the CC shock profile remains largely constant." ///
    "Source: Based on the integrated and enhanced dataset of Burkina Faso (2018-2023).") ///
    title("Table 10: Shock profile, Burkina Faso (2019-2023) ")	
	

	
	
	
	
* NUMBER OF COPING STRATEGIES
gen nb_strat_cat = nb_strategies
replace nb_strat_cat = 5 if nb_strategies >= 5 & nb_strategies != .


label define lbl_strat 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
label values nb_strat_cat lbl_strat


*==================================================
* PUBLICATION-QUALITY STACKED BAR FIGURES
*==================================================

*-------------------------------
* Global graph style
*-------------------------------
set scheme s2color
graph set window fontface "Arial"

global G_TITLE "size(medsmall)"
global G_AXIS  "labsize(vsmall)"

*==================================================
* Bloc 1 : Education of household head (LEGEND HERE)
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(education_head, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("Percent", size(vsmall)) ///
    title("Education Level of Household Head", $G_TITLE) ///
	legend(off) ///
    name(g1, replace)

*==================================================
* Bloc 2 : Residence area
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(area, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("") ///
    title("Area of Residence", $G_TITLE) ///
    legend(off) ///
    name(g2, replace)

*==================================================
* Bloc 3 : Food Consumption Score (FCS)
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(FCS, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("") ///
    title("Food Consumption Score (FCS)", $G_TITLE) ///
    legend(off) ///
    name(g3, replace)

*==================================================
* Bloc 4 : Household Hunger Scale (HHS)
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(HHS, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("") ///
    title("Household Hunger Scale (HHS)", $G_TITLE) ///
    legend(off) ///
    name(g4, replace)

*==================================================
* Bloc 5 : Sex of household head
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(sex_head, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("") ///
    title("Sex of Household Head", $G_TITLE) ///
    legend(off) ///
    name(g5, replace)

*==================================================
* Bloc 6 : Marital status of household head
*==================================================
qui graph hbar (percent) [pw=weight], ///
    over(nb_strat_cat, label($G_AXIS)) ///
    over(marital_head, label($G_AXIS)) ///
    stack asyvars percentage ///
    yscale(range(0 100)) ///
    ytitle("") ///
    title("Marital Status of Household Head", $G_TITLE) ///
    legend(off) ///
    name(g6, replace)

*==================================================
* COMBINE GRAPHS
*==================================================
graph combine g1 g2 g3 g4 g5 g6, ///
    rows(2) ///
    imargin(small) ///
    ysize(8) xsize(12) ///
    iscale(*0.9) ///
    note("Source: Burkina Faso Integrated Dataset (2018–2023)", size(vsmall))

*==================================================
* EXPORT (high-resolution, publication ready)
*==================================================
graph export "Figure_strategies_profiles.png", ///
    width(4000) replace


* PV : Political Violence
gen PV = nb_pol_shocks
* FP : Food Prices
gen FP = nb_price_shocks
* CC : Climate Change (D1/D2 Long-term indicators)
gen CC = nb_cc_shocks
* SP : Seasonal Performance (CDI)
gen SP = nb_seasonal_shocks
* EW : Extreme Weather
gen EW = nb_ew_shocks	
	
* Liste des nouveaux indicateurs créés
local chocs PV FP CC SP EW

foreach ind in `chocs' {
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
	
	
	
keep hhid year wave admin0Pcod admin0name admin1Pcod admin1name admin2Pcod admin2name area weight sex_head marital_head education_head FCS HDDS HHS CARI Lcs_* rCSI_* D_* D1_* D2_*


expand weight, generate(dup)

drop dup

save "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\data\input arules BurkinaFaso_20262601.dta", replace