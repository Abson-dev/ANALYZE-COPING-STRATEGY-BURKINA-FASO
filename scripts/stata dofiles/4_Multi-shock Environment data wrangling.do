/*------------------------------------------------------------------------------
Project: G5 Sahel - Burkina Enhanced Dataset Cleaning
Purpose: Prep for Econometric Analysis (Waves, Weights, Binary Indicators)
------------------------------------------------------------------------------*/


clear all
set more off

* 1. LOAD DATA
use "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata.dta", replace

tab wave

tab wave, nolab



* 2. WAVE FILTERING (Keep only Sep-Oct waves / Wave Type 2)
* Logic: Waves 2, 4, 6, 8, 10, 12 are the second waves of each year
gen wavetype = (mod(wave, 2) == 0) + 1
//keep if wavetype == 2
label define wavetype_lab 1 "Jan-Feb" 2 "Sep-Oct"
label values wavetype wavetype_lab

* 3. CLEAN COPING STRATEGY VARIABLES (LCS)
* Recode: 10->0 (No), 20/30->1 (Yes/Depleted), 9999->Missing
local lcs_vars Lcs_stress_DomAsset-Lcs_em_FemAnimal
foreach var of varlist `lcs_vars' {
    recode `var' (10 = 0) (20 30 = 1) (9999 = 0)
}

* Drop variables with poor temporal coverage (as requested)
drop Lcs_crisis_ChildWork Lcs_crisis_HHSeparation Lcs_em_Migration

* 4. FOOD SECURITY INDICATORS (Binarization)
* Standardizing: 1 = Food Insecure / 0 = Food Secure

* FCS: 1=poor, 2=borderline, 3=acceptable -> 1 if poor/borderline
gen FCS_dummy = (FCS <= 2) if !missing(FCS)

* CARI: 1=secure, 2=marginal, 3=moderate, 4=severe -> 1 if moderate/severe
gen CARI_dummy = (CARI >= 3) if !missing(CARI)

* HHS: 1=0 (Secure), 2=1, 3=2-3, 4=4, 5=5-6 -> 1 if score > 0
gen HHS_dummy = (HHS >= 2) if !missing(HHS)

* HDDS: 1=>=5 groups (Secure), 2=4, 3=3, 4=2, 5=0-1 -> 1 if < 5 groups
gen HDDS_dummy = (HDDS >= 2) if !missing(HDDS)

* 5. COVARIATE RECODING
* Sex: 1=Male, 0=Female (assuming original 2=Female)
recode sex_head (2 = 0)

* Area: 1=Urban, 0=Rural (assuming original 2=Rural)
recode area (2 = 0)

* Education: 1=Some Education, 0=No Education
replace education_head = 1 if inlist(education_head, 1, 2, 3, 4)

* Marital Status: 1=Married (code 2), 0=Other
gen married = (marital_head == 2) if !missing(marital_head)

* 6. FINAL CLEAN UP
label variable FCS_dummy "HH is Food Insecure (FCS Poor/Borderline)"
label variable CARI_dummy "HH is Food Insecure (CARI Moderate/Severe)"

* 7. SAVE WORKED DATASET
save "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stataWorked.dta", replace

* 8. VERIFICATION
sum FCS_dummy CARI_dummy HHS_dummy HDDS_dummy R_drought deadliness [weight=weight]