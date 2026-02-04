clear all
set more off

* 1. LOAD DATA
use "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stataWorked.dta", replace



* 2. Label variables for a professional appearance
label var deadliness "deadliness"
label var danger "danger"
label var diffusion "diffusion"
label var fragmentation "fragmentation"
label var zs_maize_spell "zs_maize_spell"
label var zs_millet_spell "zs_millet_spell"
label var zs_rice_spell "zs_rice_spell"
label var zs_cowpea_spell "zs_cowpea_spell"
label var zs_peanut_spell "zs_peanut_spell"
label var R_drought "R_drought"
label var R_flood "R_flood"
label var R_heat "R_heat"
label var cdi_rainfall "cdi_rainfall"
label var cdi_soilmoisture "cdi_soilmoisture"
label var cdi_evapotranspiration "cdi_evapotranspiration"
label var area "area"
label var education_head "education head"
label var married "marital head"
label var sex_head "sex head (female = 1)"
* Use these new dummies in your table instead of the original variables

* 1. Define the list of variables
local vars deadliness danger diffusion fragmentation zs_maize_spell ///
           zs_millet_spell zs_rice_spell zs_cowpea_spell zs_peanut_spell ///
           R_drought R_flood R_heat cdi_rainfall cdi_soilmoisture ///
           cdi_evapotranspiration area education_head married sex_head

* 2. Calculate statistics
estpost summarize `vars', detail

* 3. Display and format the table
esttab using "Tableau1_MSEDescriptive_Stats.rtf",replace  cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
    label nonumber nomtitle noobs ///
    title("Table 1: Descriptive statistics for shocks and demographics") ///
    addnotes("Note: [1] Education of Household Head (education_head): This variable was initially categorized into five levels: no education (0), primary education (1), middle school (2), secondary school (3), and higher education (4). For the purpose of this analysis, the variable was dichotomized, with individuals having no formal education coded as 0, while those with any level of formal education (primary, middle, secondary, or higher) were coded as 1." ///
             "[2] Marital Status of Household Head (marital_head): The original variable included five categories: single (1), married (2), divorced/separated (3), widow(er) (4), and free union (5). To simplify the analysis, the variable was dichotomized by grouping individuals who were single, divorced/separated, widowed, or in a free union under 0, while those who were married were assigned a value of 1." ///
             "Recode HH sex: 2 (female) becomes 1, 1 (male) becomes 0.")
			 
			 
			 
* --- Step 1: Define the Variable List ---
local table_vars Lcs_stress_DomAsset - Lcs_em_FemAnimal ///
    FCS_dummy CARI_dummy HHS_dummy HDDS_dummy

* --- Step 2: Calculate Statistics ---
estpost summarize `table_vars', detail

* --- Step 3: Produce Table in Stata Results Window & Export to Word ---
esttab using "Table2_MSEDescriptives.rtf", replace ///
    cells("count(fmt(%9.0fc)) mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f))") ///
    label nonumber noobs ///
    title("Table 2: Descriptive statistics for coping strategies and food security outcomes") ///
    collabels("Observations" "Mean" "Std. Dev." "Minimum" "Maximum") ///
    addnotes("1 HDDS: 1 = >=5 groups, 0 = <5 groups" ///
             "2 HHS: 1 = No hunger (0), 0 = Any hunger (>0)" ///
             "3 CARI: 1 = Secure/Marginal, 0 = Moderate/Severe" ///
             "4 FCS: 1 = Borderline/Acceptable, 0 = Poor")