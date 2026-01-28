/********************************************************************
 Project: Shocks, Coping Strategies, and Food Security – Burkina Faso
 Purpose: Modular estimation with journal-ready tables (AMEs)
 Author: Aboubacar Hema
 Date: 2026-28-01
********************************************************************/

version 19
clear all
set more off

/********************************************************************
 1. PATHS & DATA
********************************************************************/

* Root directory (NO trailing backslash)
global root "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files"
global output "$root\outputs"

cap mkdir "$output"
cd "$root"

use "BurkinaFaso_Shocks_Coping_stataWorked.dta", clear

keep if wavetype == 2
keep if !missing(weight)
/*
egen sample_test = rowmiss( ///
    FCS_dummy ///
    Lcs_stress_DomAsset ///
    Lcs_stress_Saving ///
    Lcs_stress_BorrowCash ///
    Lcs_stress_Animals ///
    Lcs_crisis_ProdAssets ///
    Lcs_crisis_Edu_Health ///
    Lcs_crisis_OutSchool ///
    Lcs_crisis_Health ///
    Lcs_crisis_AgriCare ///
    Lcs_em_ResAsset ///
    Lcs_em_Begged ///
    Lcs_em_FemAnimal ///
    education_head ///
    married ///
    sex_head ///
    weight )


tab sample_test
*/

/********************************************************************
 2. SURVEY DESIGN
********************************************************************/

svyset hhid [pweight=weight], singleunit(centered)

/********************************************************************
 3. VARIABLE GROUPS
********************************************************************/

* Coping strategies (table columns)
local strategies ///
    Lcs_stress_DomAsset ///
    Lcs_stress_Saving ///
    Lcs_stress_EatOut ///
    Lcs_stress_BorrowCash ///
    Lcs_stress_Animals ///
    Lcs_crisis_ProdAssets ///
    Lcs_crisis_Edu_Health ///
    Lcs_crisis_OutSchool ///
    Lcs_crisis_Health ///
    Lcs_crisis_AgriCare ///
    Lcs_crisis_Seed ///
    Lcs_em_ResAsset ///
    Lcs_em_Begged ///
    Lcs_em_IllegalAct ///
    Lcs_em_FemAnimal

* Controls (included everywhere)
local controls area education_head married sex_head



/********************************************************************
 4. SHOCK BLOCKS (EQUATIONS 1–5)
********************************************************************/

* Eq. (1): Conflict & insecurity
local shock1 deadliness danger diffusion fragmentation

* Eq. (2): Crop yield shocks
local shock2 ///
    zs_maize_spell ///
    zs_millet_spell ///
    zs_rice_spell ///
    zs_cowpea_spell ///
    zs_peanut_spell

* Eq. (3): Climate indices
local shock3 ///
    cdi_rainfall ///
    cdi_soilmoisture ///
    cdi_evapotranspiration

* Eq. (4): Extreme events
local shock4 R_drought R_flood R_heat

* Eq. (5): All shocks jointly
local shock5 ///
    `shock1' ///
    `shock2' ///
    `shock3' ///
    `shock4'


	
misstable summarize FCS_dummy HDDS_dummy HHS_dummy CARI_dummy ///
    `strategies' `controls' `shock1' `shock2' `shock3' `shock4'
/*	
	/********************************************************************
 Export misstable-style summary to Excel
********************************************************************/

* Define variable list exactly as requested
local varlist ///
    FCS_dummy HDDS_dummy HHS_dummy CARI_dummy ///
    `strategies' ///
    `controls' ///
    `shock1' `shock2' `shock3' `shock4'

* Temporary file to store results
tempfile misstbl
postfile handle ///
    str40 variable ///
    obs_missing ///
    obs_nonmissing ///
    obs_total ///
    min ///
    max ///
    using `misstbl', replace

* Loop over variables
foreach v of local varlist {

    quietly count if missing(`v')
    local miss = r(N)

    quietly count if !missing(`v')
    local nonmiss = r(N)

    local total = `miss' + `nonmiss'

    quietly summarize `v', meanonly
    local min = r(min)
    local max = r(max)

    post handle ///
        ("`v'") ///
        (`miss') ///
        (`nonmiss') ///
        (`total') ///
        (`min') ///
        (`max')
}

postclose handle

* Load results
use `misstbl', clear

* Export to Excel
export excel using "$output\Missingness_Summary.xls", ///
    firstrow(variables) replace

	
* Need to drop these variables: Lcs_stress_EatOut, Lcs_crisis_Seed, Lcs_em_IllegalAct ,diffusion,cdi_soilmoisture	
*/
/*
/********************************************************************
 5. PROGRAM: SHOCKS → COPING STRATEGIES
     (One equation = one journal table)
********************************************************************/

capture program drop shock_table
program define shock_table
    syntax , SHOCKS(string) FILENAME(string)

    local first = 1

    foreach strat in `strategies' {

        quietly svy: probit `strat' `shocks' `controls'
        quietly margins, dydx(`shocks') vce(unconditional) post

        local action = cond(`first', "replace", "append")
        local first = 0

        outreg2 using "`filename'", `action' ///
            excel label dec(3) zstat ///
            ctitle("`strat'") ///
            addtext(Controls, Yes, Survey design, Yes)
    }
end

/********************************************************************
 6. ESTIMATION: EQUATIONS 1–5
********************************************************************/

* Table 3: Conflict & insecurity shocks
shock_table, ///
    shocks("`shock1'") ///
    filename("$output\Table3_ConflictShocks.xls")

* Table 4: Crop yield shocks
shock_table, ///
    shocks("`shock2'") ///
    filename("$output\Table4_CropShocks.xls")

* Table 5: Climate indices
shock_table, ///
    shocks("`shock3'") ///
    filename("$output\Table5_ClimateIndices.xls")

* Table 6: Extreme weather events
shock_table, ///
    shocks("`shock4'") ///
    filename("$output\Table6_ExtremeEvents.xls")

* Table 7: All shocks jointly
shock_table, ///
    shocks("`shock5'") ///
    filename("$output\Table7_AllShocks.xls")

/********************************************************************
 7. EQUATION 6: COPING STRATEGIES → FOOD SECURITY
********************************************************************/

local fs_outcomes ///
    FCS_dummy ///
    HDDS_dummy ///
    HHS_dummy ///
    CARI_dummy

local first = 1

foreach y in `fs_outcomes' {

    quietly svy: probit `y' `strategies' `controls'
    quietly margins, dydx(`strategies') vce(unconditional) post

    local action = cond(`first', "replace", "append")
    local first = 0

    outreg2 using "$output\Table8_FoodSecurity.xls", `action' ///
        excel label dec(3) zstat ///
        ctitle("`y'") ///
        addtext(Controls, Yes, Survey design, Yes)
}

/********************************************************************
 END OF DO-FILE
********************************************************************/
*/