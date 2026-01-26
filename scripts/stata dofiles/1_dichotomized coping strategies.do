use "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata.dta", replace

tab1 Lcs_stress_DomAsset- Lcs_em_FemAnimal
/*
-> tabulation of Lcs_stress_DomAsset  

  Vente d'actifs ou de biens |
  du ménage (radio, meubles, |
         télévision, bijoux) |      Freq.     Percent        Cum.
-----------------------------+-----------------------------------
         no, because no need |     41,303       63.21       63.21
no, because already depleted |      1,038        1.59       64.80
                         yes |      2,734        4.18       68.98
              not applicable |     20,270       31.02      100.00
-----------------------------+-----------------------------------
                       Total |     65,345      100.00

*/

tab1 Lcs_stress_DomAsset- Lcs_em_FemAnimal,nolab
/*
-> tabulation of Lcs_stress_DomAsset  

      Vente |
d'actifs ou |
de biens du |
     ménage |
    (radio, |
   meubles, |
  télévisio |
 n, bijoux) |      Freq.     Percent        Cum.
------------+-----------------------------------
      10.00 |     41,303       63.21       63.21
      20.00 |      1,038        1.59       64.80
      30.00 |      2,734        4.18       68.98
    9999.00 |     20,270       31.02      100.00
------------+-----------------------------------
      Total |     65,345      100.00

*/
*==================================================
* Dichotomization of livelihood-based coping
* (30/20 = 1 ; 10/9999 = 0)
*==================================================

*==================================================
* Livelihood-based coping variables available
*==================================================
local lcs_vars ///
    Lcs_stress_DomAsset ///
    Lcs_stress_Saving ///
    Lcs_stress_EatOut ///
    Lcs_stress_BorrowCash ///
    Lcs_stress_Animals ///
    Lcs_crisis_ProdAssets ///
    Lcs_crisis_Edu_Health ///
    Lcs_crisis_HHSeparation ///
    Lcs_crisis_ChildWork ///
    Lcs_crisis_OutSchool ///
    Lcs_crisis_Health ///
    Lcs_crisis_AgriCare ///
    Lcs_crisis_Seed ///
    Lcs_em_Migration ///
    Lcs_em_ResAsset ///
    Lcs_em_Begged ///
    Lcs_em_IllegalAct ///
    Lcs_em_FemAnimal
	
/*	
local lcs_vars ///
    Lcs_stress_DomAsset ///
    Lcs_stress_Saving ///
    Lcs_stress_EatOut ///
    Lcs_stress_BorrowCash ///
    Lcs_stress_Animals ///
    Lcs_crisis_ProdAssets ///
    Lcs_crisis_Edu_Health ///
    Lcs_crisis_HHSeparation ///
    Lcs_crisis_ChildWork ///
    Lcs_crisis_OutSchool ///
    Lcs_crisis_Health ///
    Lcs_crisis_AgriCare ///
    Lcs_crisis_Seed ///
    Lcs_em_Migration ///
    Lcs_em_ResAsset ///
    Lcs_em_Begged ///
    Lcs_em_IllegalAct ///
    Lcs_em_FemAnimal
*/

foreach var of local lcs_vars {

    gen D_`var' = .

    replace D_`var' = 1 if inlist(`var', 30, 20)
    replace D_`var' = 0 if inlist(`var', 10, 9999)

}



*==================================================
* Dichotomization of rCSI
*==================================================

/*

. tab rCSI

 Indice des |
 Stratégies |
d'Adaptatio |
   n réduit |
   (rCSI) - |
  Catégorie |      Freq.     Percent        Cum.
------------+-----------------------------------
        0-3 |     46,128       70.59       70.59
       4-18 |     12,773       19.55       90.14
       >=19 |      6,444        9.86      100.00
------------+-----------------------------------
      Total |     65,345      100.00

. tab rCSI,nolab

 Indice des |
 Stratégies |
d'Adaptatio |
   n réduit |
   (rCSI) - |
  Catégorie |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     46,128       70.59       70.59
          2 |     12,773       19.55       90.14
          3 |      6,444        9.86      100.00
------------+-----------------------------------
      Total |     65,345      100.00

*/

*==================================================
* Light consumption coping (rCSI category 4–18)
*==================================================

gen D_rCSI_light = .
replace D_rCSI_light = 1 if rCSI == 2
replace D_rCSI_light = 0 if inlist(rCSI, 1, 3)

label variable D_rCSI_light "Reduced Coping Strategies Index (rCSI)"

*==================================================
* Severe consumption coping (rCSI category ≥19)
*==================================================

gen D_rCSI_severe = .
replace D_rCSI_severe = 1 if rCSI == 3
replace D_rCSI_severe = 0 if inlist(rCSI, 1, 2)

label variable D_rCSI_severe "Reduced Coping Strategies Index (rCSI)"

/*
label define yesno 0 "No" 1 "Yes", replace

foreach v of varlist D_Lcs_* D_rCSI_* {
    label values `v' yesno
}
*/
*Consistency checks
foreach var of local lcs_vars {
    tab `var' D_`var', missing
}

*==================================================
* Table 2 – Dichotomized coping strategies
*==================================================
//ssc install estout, replace

local table2_vars ///
    D_Lcs_stress_DomAsset ///
    D_Lcs_stress_Saving ///
    D_Lcs_stress_EatOut ///
    D_Lcs_stress_BorrowCash ///
    D_Lcs_stress_Animals ///
    D_Lcs_crisis_ProdAssets ///
    D_Lcs_crisis_Edu_Health ///
    D_Lcs_crisis_HHSeparation ///
    D_Lcs_crisis_ChildWork ///
    D_Lcs_crisis_OutSchool ///
    D_Lcs_crisis_Health ///
    D_Lcs_crisis_AgriCare ///
    D_Lcs_crisis_Seed ///
    D_Lcs_em_Migration ///
    D_Lcs_em_ResAsset ///
    D_Lcs_em_Begged ///
    D_Lcs_em_IllegalAct ///
    D_Lcs_em_FemAnimal



/*
foreach v of local table2_vars {
    label variable `v' "`v'"
}
*/	
label variable D_Lcs_stress_DomAsset ///
    "Selling household assets or goods (radio, furniture, television, jewelry)"

label variable D_Lcs_stress_Saving ///
    "Spending savings"

label variable D_Lcs_stress_EatOut ///
    "Relying on less preferred or less expensive food"

label variable D_Lcs_stress_BorrowCash ///
    "Borrowing money to cover food needs"

label variable D_Lcs_stress_Animals ///
    "Selling animals more than usual"

label variable D_Lcs_crisis_ProdAssets ///
    "Selling productive assets or means of transport"

label variable D_Lcs_crisis_Edu_Health ///
    "Reducing essential non-food expenditure (education/health)"

label variable D_Lcs_crisis_HHSeparation ///
    "Household member separation"

label variable D_Lcs_crisis_ChildWork ///
    "Sending children to work"

label variable D_Lcs_crisis_OutSchool ///
    "Withdrawing children from school"

label variable D_Lcs_crisis_Health ///
    "Reducing health expenditures"

label variable D_Lcs_crisis_AgriCare ///
    "Reducing care of agricultural activities"

label variable D_Lcs_crisis_Seed ///
    "Reducing expenditure on agricultural inputs or seeds"

label variable D_Lcs_em_Migration ///
    "Whole household migration"

label variable D_Lcs_em_ResAsset ///
    "Mortgaging or selling the house or land"

label variable D_Lcs_em_Begged ///
    "Begging or asking strangers for money or food"

label variable D_Lcs_em_IllegalAct ///
    "Engaging in illegal activities"

label variable D_Lcs_em_FemAnimal ///
    "Selling of last female animals"	

estpost tabstat `table2_vars', ///
    statistics(count mean sd min max) ///
    columns(statistics)


esttab ., ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min max") ///
    label ///
    noobs ///
    nonumber ///
    compress

esttab using "Table2_CopingStrategies_Burkina.rtf", ///
    replace ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min max") ///
    label ///
    noobs ///
    nonumber
*/
esttab using "Table2_CopingStrategies_Burkina.rtf", ///
    replace ///
    cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min max") ///
    label ///
    varlabels(_cons "") ///
    nostar ///
    nonumber ///
    title("Table 2: Overview of dichotomized coping strategies, Burkina Faso (2018-2023)")

	
save "C:\Users\AHema\OneDrive - CGIAR\Desktop\2026\Working paper\Replication\Burkina Faso\dataverse_files\BurkinaFaso_Shocks_Coping_stata_dummy.dta", replace	
	
