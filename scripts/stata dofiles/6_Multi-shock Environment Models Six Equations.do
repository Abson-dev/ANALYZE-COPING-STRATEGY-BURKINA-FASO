/********************************************************************
 Project: Shocks, Coping Strategies, and Food Security – Burkina Faso
 Purpose: Modular estimation with journal-ready tables (AMEs)
 Author: Aboubacar Hema
 Date: 2026-01-28
********************************************************************/

version 19.0
clear all
set more off
set linesize 255
set rmsg on
set varabbrev off

/********************************************************************
 0. LOG FILE
********************************************************************/

capture log close
log using "replication.log", replace text

/********************************************************************
 1. PATHS (PORTABLE)
********************************************************************/

* Root directory = location where do-file is executed
global root "`c(pwd)'"
global data   "$root/data"
global output "$root/output"

cap mkdir "$output"

/********************************************************************
 2. DEPENDENCIES
********************************************************************/

local packages outreg2

foreach pkg of local packages {
    capture which `pkg'
    if _rc {
        di as error "Package `pkg' not installed. Install via: ssc install `pkg'"
        exit 199
    }
}

/********************************************************************
 3. DATA LOADING & INTEGRITY CHECKS
********************************************************************/

use "$data/BurkinaFaso_Shocks_Coping_stataWorked.dta", clear
gen household_id = _n
label variable household_id "Synthetic household PSU (one obs per household)"

drop hhid
egen hhid = group(admin2Pcod year household_id), label

confirm variable hhid weight wavetype

/********************************************************************
 4. SAMPLE DEFINITION
********************************************************************/

//keep if wavetype == 2
drop if missing(weight)

count
di as text "Final estimation sample size = " r(N)

/********************************************************************
 5. SURVEY DESIGN
********************************************************************/

svyset hhid [pweight=weight]
//svydescribe

/********************************************************************
 6. VARIABLE DEFINITIONS
********************************************************************/

* Coping strategies (table columns)
local strategies ///
    Lcs_stress_DomAsset ///
    Lcs_stress_Saving ///
    Lcs_stress_BorrowCash ///
    Lcs_stress_Animals ///
    Lcs_crisis_ProdAssets ///
    Lcs_crisis_OutSchool ////
    Lcs_em_ResAsset ///
    Lcs_em_Begged ///
    Lcs_em_FemAnimal

/*	
foreach var of local strategies {
    replace `var' = 0 if missing(`var')
}
*/

* Controls
local controls area education_head married sex_head

* Shock blocks
local shock1 deadliness danger fragmentation

local shock2 ///
    zs_maize_spell ///
    zs_millet_spell ///
    zs_rice_spell ///
    zs_cowpea_spell ///
    zs_peanut_spell

local shock3 ///
    cdi_rainfall ///
    cdi_evapotranspiration

local shock4 R_drought R_flood R_heat

local shock5 ///
    `shock1' ///
    `shock2' ///
    `shock3' ///
    `shock4'
//egen miss_any = rowmiss(`strategies' `controls' `shock5')
//tab miss_any
//egen miss_shocks = rowmiss(`shock5' `controls')
//keep if !(missing(Lcs_stress_DomAsset))
//keep if miss_shocks == 0

//keep if miss_any == 0

/********************************************************************
 7. EXPLICIT VARIABLE EXCLUSIONS
********************************************************************/

drop ///
    Lcs_stress_EatOut ///
    Lcs_crisis_Seed ///
    Lcs_em_IllegalAct ///
    diffusion ///
    cdi_soilmoisture

/********************************************************************
 8. VARIABLE EXISTENCE CHECKS
********************************************************************/

foreach v of local strategies {
    confirm variable `v'
}

foreach v of local controls {
    confirm variable `v'
}

foreach v of local shock5 {
    confirm variable `v'
}

/********************************************************************
 9. MISSINGNESS DIAGNOSTICS (UNWEIGHTED)
********************************************************************/

misstable summarize ///
    FCS_dummy HDDS_dummy HHS_dummy CARI_dummy ///
    `strategies' `controls' ///
    `shock1' `shock2' `shock3' `shock4'

/********************************************************************
 10. CLEAN OUTPUT DIRECTORY
********************************************************************/

cap erase "$output/Table3_ConflictShocks.xls"
cap erase "$output/Table4_CropShocks.xls"
cap erase "$output/Table5_ClimateIndices.xls"
cap erase "$output/Table6_ExtremeEvents.xls"
cap erase "$output/Table7_AllShocks.xls"
cap erase "$output/Table8_FoodSecurity.xls"

/********************************************************************
 11. REVISED PROGRAM: SHOCKS → COPING STRATEGIES
********************************************************************/
capture program drop shock_table
program define shock_table
    syntax , SHOCKS(string) FILENAME(string) STRATS(string) CONTROLS(string)

    tempname first
    scalar `first' = 1

    foreach strat of local strats {
        // Use vce(robust) or the svy default; 
        // Note: margins after svy is memory intensive
        quietly svy: probit `strat' `shocks' `controls'
        
        // Post the AMEs so outreg2 picks up the right coefficients
        quietly margins, dydx(`shocks') post 

        local action = cond(`first'==1, "replace", "append")
        scalar `first' = 0

        outreg2 using "`filename'", `action' ///
            excel label dec(3) tstat /// // tstat/zstat usually preferred for AMEs
            ctitle("`strat'") ///
            addtext(Controls, Yes, Survey design, Yes)
    }
end

/********************************************************************
 12. ESTIMATION: EQUATIONS (1)–(5)
********************************************************************/

* Table 3: Conflict & insecurity shocks
shock_table, ///
    shocks("`shock1'") ///
    strats("`strategies'") ///
    controls("`controls'") ///
    filename("$output/Table3_ConflictShocks.xls")

* Table 4: Crop yield shocks
shock_table, ///
    shocks("`shock2'") ///
    strats("`strategies'") ///
    controls("`controls'") ///
    filename("$output/Table4_CropShocks.xls")

* Table 5: Climate indices
shock_table, ///
    shocks("`shock3'") ///
    strats("`strategies'") ///
    controls("`controls'") ///
    filename("$output/Table5_ClimateIndices.xls")

* Table 6: Extreme weather events
shock_table, ///
    shocks("`shock4'") ///
    strats("`strategies'") ///
    controls("`controls'") ///
    filename("$output/Table6_ExtremeEvents.xls")

* Table 7: All shocks jointly
shock_table, ///
    shocks("`shock5'") ///
    strats("`strategies'") ///
    controls("`controls'") ///
    filename("$output/Table7_AllShocks.xls")

/********************************************************************
 13. EQUATION (6): COPING STRATEGIES → FOOD SECURITY
********************************************************************/

local fs_outcomes ///
    FCS_dummy ///
    HDDS_dummy ///
    HHS_dummy ///
    CARI_dummy
	
	
local first = 1

foreach y of local fs_outcomes {
    
    di as text "Estimating model for: `y'"
    
    * 1. Run Probit with 'asis' to prevent dropping vars if possible, 
    * or just standard svy: probit
    capture quietly svy: probit `y' `strategies' `controls'
    
    if _rc == 0 {
        * 2. Calculate AMEs. 
        * Added 'empty' to handle strategies that might have been dropped
        capture quietly margins, dydx(`strategies') vce(unconditional) post empty
        
        if _rc == 0 {
            local action = cond(`first', "replace", "append")
            local first = 0

            outreg2 using "$output/Table8_FoodSecurity.xls", `action' ///
                excel label dec(3) tstat ///
                ctitle("`y'") ///
                addtext(Controls, Yes, Survey design, Yes)
            
            di as result "Successfully added `y' to Table 8."
        }
        else {
            di as error "Margins failed for `y'. Check for collinearity or lack of variation."
        }
    }
    else {
        di as error "Probit failed to converge for `y'. Error code: " _rc
    }
}

/********************************************************************
 14. CLOSE LOG & EXIT
********************************************************************/

log close
exit



