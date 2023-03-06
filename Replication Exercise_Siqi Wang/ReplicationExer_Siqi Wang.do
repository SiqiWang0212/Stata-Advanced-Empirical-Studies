clear all                                                                                              
capture log close
set more off

* change to your directory
cd "/Users/wsq/Desktop/Empirical Studies/Replication Exercise"
log using "RepExercise SiqiWang.smcl", replace
use "Replication Exercise_Rajav Data/raw pums80 slim.dta",clear
************************
*     Mom Dataset      *
************************
*recode female: Male 0, Female 1
rename sex female
recode female (2=1)(1=0)
label define fm 1 female 0 male
label values female fm

gen chborn=us80a_chborn-1

order us80a_pernum, after(us80a_serial)
order us80a_momloc, after(us80a_pernum)
order female, after(us80a_momloc)
order age, after(female)
save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/withfemale.dta",replace

* mother(aged 21-35, )
** oldest child less than 18 years old 
gen mother=.
order mother, after(us80a_momloc)
replace mother=1 if female ==1 & inrange(age, 21,35) & us80a_chborn >=3 & us80a_chborn-1 == us80a_nchild
replace mother=0 if mother==.
keep if mother==1
rename age momage
gen us80a_momID1=us80a_pernum
gen us80a_momID2=us80a_pernum

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/mother.dta",replace

************************
*     Child Dataset    *
************************
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/withfemale.dta",clear
* generate boy = (boy=1) 
generate young = (0<=age & age<18) 
generate boy=.
replace boy =1 if (young==1 & female==0)
sort us80a_serial 
generate girl=0
replace girl=1 if (young==1 & female==1)
replace boy=0 if girl==1

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/save1.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/save1.dta",clear

order us80a_serial, before(us80a_momloc)
order us80a_momloc,before(boy)
order age,before(boy)
order female,after(boy)

* generate neg_age
gen neg_age = -age
order neg_age, after(boy)

keep us80a_serial us80a_pernum us80a_momloc age neg_age boy us80a_birthqtr us80a_qsex us80a_qage
generate child_main=1
drop if us80a_momloc==0
drop if neg_age<-18
drop if neg_age==0

bysort us80a_serial: generate kidnumber = _n
drop if kidnumber > 3
sort us80a_serial neg_age
order kidnumber,before(age)
order us80a_momloc,after(boy)
gen  us80a_momID=us80a_momloc
keep us80a_serial kidnumber us80a_momID age boy us80a_birthqtr us80a_qsex us80a_qage
save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/siblings.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/siblings.dta",clear

*reshape
reshape wide us80a_momID age boy us80a_birthqtr us80a_qsex us80a_qage, i(us80a_serial) j(kidnumber)
keep if us80a_qsex1==0 & us80a_qsex2==0 & us80a_qage1==0 & us80a_qage2==0
save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/child_wide.dta",replace
********************************
*    Merge Kids into Mother    *
********************************
use"/Users/wsq/Desktop/Empirical Studies/Replication Exercise/mother.dta"
merge 1:1 us80a_serial us80a_momID1 us80a_momID2 using "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/child_wide"
drop if _merge!=3
drop if momloc!=0

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/mom_child.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/mom_child.dta",clear

************************
* Generate Covariates  *
************************
*Children ever born: chborn

* More than 2 Children
gen mt2child = 0
replace mt2child=1 if chborn>2
sum mt2child

* Boy 1st: boy1
* Boy 2ndL boy2

*Two boys:two_boys
gen two_boys=0
replace two_boys=1 if boy1==1&boy2==1

*Two girls: two_girls
gen two_girls=0
replace two_girls=1 if boy1==0&boy2==0

*Same sex:same_sex
gen same_sex=0
replace same_sex=1 if boy1==boy2

*Twins-2: twin_2
gen twin_2=0
replace twin_2=1 if (age2==age3 & us80a_birthqtr2==us80a_birthqtr3)

*Age:momage

*Age at first birth: age_first_birth
gen age_first_birth = momage - age1

*Worked for pay: =1 if worked for pay in year prior to census
gen workedforpay=0
replace workedforpay=1 if us80a_wkswork1>0

*Weeks worked: weeks worked in year prior to census: us80a_wkswork1

*Hours/week: average hours worked per week: us80a_uhrswork

*Labor income (labor earnings in year prior to census, in 1995 dollars):
gen inflated_incwage=(us80a_incwage*2.099173554) 

*Family income  (family income in year prior to census, in 1995 dollars)
gen inflated_ftotinc=(us80a_ftotinc*2.099173554)

*non-wife income(family income minus wife's labor income, in 199')
gen nonwifeincome= us80a_ftotinc-us80a_incwage
gen inflated_nonwifeinc=(nonwifeincome*2.099173554)

*hispanic
gen hispanic=0
replace hispanic=1 if hispan!=0

*white
gen white=0
replace white=1 if race==10

*black
gen black=0
replace black=1 if race==20

*other race
gen otherrace=0
replace otherrace=1 if race!=10 & race!=20

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/covariates.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/covariates.dta",clear

/*Table 2*/
*Column1- All women* 
mean chborn mt2child boy1 boy2 two_boys two_girls same_sex twin_2 momage age_first_birth workedforpay us80a_wkswork us80a_uhrswork inflated_incwage inflated_ftotinc 
outreg2 using Table2, excel stats(mean sd) ctitle(All Women) replace

/*Table 6 */
* Column123- All women 
reg mt2child same_sex momage age_first_birth black hispanic otherrace, robust
outreg2 using Table6, excel keep(boy1 boy2 same_sex) ctitle(OLS_More than 2 children) replace

reg mt2child boy1 boy2 same_sex momage age_first_birth black hispanic otherrace, robust
outreg2 using Table6, excel keep(boy1 boy2 same_sex)  ctitle(OLS_More than 2 children) append

reg mt2child boy1 two_boys two_girls momage age_first_birth black hispanic otherrace, robust
outreg2 using Table6, excel keep(boy1 two_boys two_girls)  ctitle(OLS_More than 2 children) append

/*Table 7*/
*column 1- IV ols for all women *
reg workedforpay mt2child momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 1 worked for pay all women) replace

reg us80a_wkswork1 mt2child momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 1 weeks worked all women) append

reg  us80a_uhrswork mt2child momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 1 hours work per week all women) append

reg inflated_incwage mt2child momage age_first_birth boy1 boy2 black hispanic otherrace,robust
outreg2 using Table7, excel keep(mt2child)  ctitle(column 1 labor income all women) append

gen ln_familyinc=ln(inflated_ftotinc+1)
reg ln_familyinc mt2child momage age_first_birth boy1 boy2 black hispanic otherrace,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 1 ln-family income all women) append

/*Table 7*/
*column 2- IV 2sls for all women 
ivregress 2sls workedforpay (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 2 worked for pay all women) append
ivregress 2sls us80a_wkswork1 (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 2 weeks worked all women) append
ivregress 2sls  us80a_uhrswork (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 2 hours work per week all women) append
ivregress 2sls inflated_incwage (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace,robust
outreg2 using Table7, excel keep(mt2child)  ctitle(column 2 labor income all women) append
ivregress 2sls ln_familyinc (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 2 ln-family income all women) append

/*Table 7*/
*column 3 -2sls for all women
ivregress 2sls workedforpay (mt2child=two_boys two_girls) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 3 worked for pay all women) append

ivregress 2sls us80a_wkswork1 (mt2child=two_boys two_girls)  momage age_first_birth boy1 boy2 black hispanic otherrace, robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 3 weeks worked all women) append

ivregress 2sls us80a_uhrswork (mt2child=two_boys two_girls)  momage age_first_birth boy1 boy2 black hispanic otherrace, robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 3 hours worked per week all women) append

ivregress 2sls inflated_incwage (mt2child=two_boys two_girls)  momage age_first_birth boy1 boy2 black hispanic otherrace, robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7,  excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 3 labor income all women) append

ivregress 2sls ln_familyinc (mt2child=two_boys two_girls) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 3 ln-family income all women) append

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/beforemarried.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/beforemarried",clear

*****************
* Married Women *
*****************
gen birthqtr=0 if us80a_birthqtr1==1
replace birthqtr=0.25 if us80a_birthqtr1==2
replace birthqtr=0.5 if us80a_birthqtr1==3
replace birthqtr=0.75 if us80a_birthqtr1==4

gen marrqtr=0 if us80a_marrqtr==1
replace marrqtr=0.25 if us80a_marrqtr==2
replace marrqtr=0.5 if us80a_marrqtr==3
replace marrqtr=0.75 if us80a_marrqtr==4

* were married
keep if us80a_marst==1 | us80a_marst==2
* married at the time of first birth & married only once
keep if (age_first_birth+ birthqtr)-(us80a_agemarr+ marrqtr)>=0 & us80a_marrno==1 
gen us80a_spouseID=us80a_sploc // may delete
save Married, replace

/*Table2*/
mean chborn mt2child boy1 boy2 two_boys two_girls same_sex twin_2 momage age_first_birth workedforpay us80a_wkswork us80a_uhrswork inflated_incwage inflated_ftotinc
outreg2 using Table2, excel stats(mean sd) ctitle(Wives) append

/*Table 6 OLS regression married women*/
*boy1
reg mt2child same_sex, robust
outreg2 using Table6,excel ctitle(OLS_More than 2 children_Married Women) append
*boy1 boy2 samesex covariates
reg mt2child boy1 boy2 same_sex momage age_first_birth black otherrace hispanic, robust
outreg2 using Table6,excel keep(boy1 boy2 same_sex) ctitle(OLS_More than 2 children_Married Women) append
*boy1 two_boys two_girls covariates
reg mt2child boy1 two_boys two_girls momage age_first_birth black otherrace hispanic, robust
outreg2 using Table6, excel keep(boy1 two_boys two_girls) ctitle(OLS_More than 2 children_Married Women) append

/*Table 7 instrumental variable married women*/
*column 4*
reg workedforpay mt2child momage age_first_birth boy1 boy2 black otherrace hispanic,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 worked for pay_married women) append

reg us80a_wkswork1 mt2child momage age_first_birth boy1 boy2 black otherrace hispanic,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 weeks worked_married women) append

reg  us80a_uhrswork mt2child momage age_first_birth boy1 boy2 black otherrace hispanic, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 hours work per week_married women) append

reg inflated_incwage mt2child momage age_first_birth boy1 boy2 black otherrace hispanic, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 labor income_married women) append

reg ln_familyinc mt2child momage age_first_birth boy1 boy2 black otherrace hispanic, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 ln-family income_married women) append

gen ln_nonwifeinc=ln(inflated_nonwifeinc+1)
reg ln_nonwifeinc mt2child momage age_first_birth boy1 boy2 black otherrace hispanic,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 ln-non wife income_married women) append

/*Table 7 instrumental variable married women*/
*column 5*
ivregress 2sls workedforpay (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 worked for pay married women) append

ivregress 2sls us80a_wkswork1 (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 weeks worked married women) append

ivregress 2sls us80a_uhrswork (mt2child=same_sex)momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 hours worked per week married women) append

ivregress 2sls inflated_incwage (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 labor income married women) append

ivregress 2sls ln_familyinc (mt2child=same_sex) momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 ln-family income married women) append

ivregress 2sls ln_nonwifeinc (mt2child=same_sex)momage age_first_birth boy1 boy2 black hispanic otherrace, robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 5 ln-non wife income married women) append

/*Table 7 instrumental variable married women*/

*column 6* ! boy2 is excluded from equation(6)
ivregress 2sls workedforpay (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 worked for pay married women) append

ivregress 2sls us80a_wkswork1 (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 weeks worked married women) append

ivregress 2sls us80a_uhrswork (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 hours worked per week married women) append

ivregress 2sls inflated_incwage (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 labor income married women) append

ivregress 2sls ln_familyinc (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 ln-family income married women) append

ivregress 2sls ln_nonwifeinc (mt2child=two_boys two_girls) momage age_first_birth boy1 black hispanic otherrace,robust
estadd scalar jstat=r(p_score), replace
outreg2 using Table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 6 ln-non wife income married women) append

drop _merge

save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/autosave before spouse.dta",replace
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/autosave before spouse.dta"

**************
* Dad/Spouse *
**************
use "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/withfemale.dta"
gen us80a_spouseID=us80a_pernum
save "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/raw+spouseID.dta",replace
*************************************
*    Merge Dad with Mother+child    *
*************************************
*spouse sample
use Married, replace
keep us80a_sploc us80a_serial
rename us80a_sploc us80a_pernum
merge 1:m us80a_pernum us80a_serial using "/Users/wsq/Desktop/Empirical Studies/Replication Exercise/withfemale.dta"
keep if _merge==3
gen father=1 if _merge==3
replace father=0 if father==.
save father, replace

use father
*merge spouse to children
drop _merge us80a_sploc
rename us80a_incwage fincwage
rename age fage
rename us80a_wkswork1 fwkswork
rename us80a_uhrswork fuhrswork
rename us80a_race frace
rename us80a_pernum us80a_sploc
merge 1:m us80a_sploc us80a_serial using "Married.dta",generate(fatherwchild)
drop if us80a_marrno>1
save fatherwchild, replace

*covariates
gen fworkedforpay=1 if fwkswork>0
replace fworkedforpay=0 if fworkedforpay==.
gen inflated_fincwage=(fincwage*2.099173554)
gen fage_first_birth=fage-age1
gen fblack=1 if frace==3
replace fblack=0 if fblack==.
gen fhispanic=1 if frace==2
replace fhispanic=0 if fhispanic==.
gen fotherrace=1 if frace!=1 & frace!=2 & frace!=3
replace fotherrace=0 if fotherrace==.
save family, replace

*Table2 Married Spouse
mean chborn mt2child boy1 boy2 two_boys two_girls same_sex twin_2 fage fage_first_birth fworkedforpay fwkswork fuhrswork inflated_fincwage
outreg2 using Table2, excel keep(fage fage_first_birth fworkedforpay fwkswork fuhrswork inflated_fincwage) stats(mean sd) ctitle(Married couples) append

/*Table 7 Instrumental variable spouses*/
*column 7*
reg fworkedforpay mt2child fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using Table7, excel keep(mt2child) ctitle(column 7 worked for pay sponse)

reg fwkswork mt2child fage age_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using Table7, excel keep(mt2child) ctitle(column 7 weeks worked sponse)

reg  fuhrswork mt2child fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using Table7, excel keep(mt2child) ctitle(column 7 hours worked per week sponse)

reg  inflated_fincwage mt2child fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using Table7, excel keep(mt2child) ctitle(column 7 labor income sponse)

reg workedforpay mt2child momage fage_first_birth boy1 boy2 black otherrace hispanic,robust
outreg2 using Table7, excel keep(mt2child) ctitle(column 4 worked for pay_married women) append

*column 8*
ivregress 2sls fworkedforpay (mt2child=same_sex)  fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using table7, excel keep(mt2child) ctitle(column 8 worked for pay sponse)
ivregress 2sls fwkswork (mt2child=same_sex)  fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using table7, excel keep(mt2child) ctitle(column 8 weeks worked sponse)
ivregress 2sls fuhrswork (mt2child=same_sex)  fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using table7, excel keep(mt2child) ctitle(column 8 hours worked per week sponse)
ivregress 2sls inflated_fincwage (mt2child=same_sex)  fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
outreg2 using table7, excel keep(mt2child) ctitle(column 8 labor income sponse)

*column 9*
ivregress 2sls fworkedforpay (mt2child=two_boys two_girls) fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 9 worked for pay sponse)

ivregress 2sls fwkswork (mt2child=two_boys two_girls) fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 9 weeks worked sponse)

ivregress 2sls fuhrswork (mt2child=two_boys two_girls) fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 9 hours worked per week sponse)

ivregress 2sls inflated_fincwage (mt2child=two_boys two_girls) fage fage_first_birth boy1 boy2 fblack fotherrace fhispanic if father==1,r
estadd scalar jstat=r(p_score), replace
outreg2 using table7, excel stats(coef se) e(jstat) keep(mt2child) ctitle(column 9 labor income sponse)


capture log close 

translate "RepExercise SiqiWang.smcl" "RepExercise SiqiWang.smcl log.pdf", replace fontsize(9) lmargin(.5) rmargin(.5) tmargin(.75) bmargin(.75) 

