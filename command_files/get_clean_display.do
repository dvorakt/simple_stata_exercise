*this program gets one source of data from original_data folder
*it outputs annual_data.dat into analysis_data folder

*the working directory needs to be the folder where this code is
cd C:\Users\dvorakt\Documents\research\TIER\simple_stata_exercise\command_files

**************************************************
*retrieve data from WDI database
*wbopendata, indicator(NY.GDP.MKTP.KD.ZG ; GC.DOD.TOTL.GD.ZS; NY.GDP.PCAP.KD; SP.POP.TOTL) clear long 
*save retrieved data (preserves the data as of the date of retrieval)
*save original_data/wdidata08102017, replace
*the two commands above can be commented out after the data is retrieved
use ../original_data/wdidata08102017, clear
*drop "aggregates" (e.g. Europe), keep only countries
drop if region=="Aggregates" | region==""
*public debt data is sparse before 1990 so keep only data after 1990
*keep if year>=1990
*give the variables more recognizable names.
rename gc_dod_totl_gd_zs debttogdp_WDI
rename ny_gdp_mktp_kd_zg gdpgrowth
rename ny_gdp_pcap_kd gdppc
rename countryname country
drop iso2code region

****************************************************
*clean data
*drop countries that at any point had fewer than 500K people
*find the minimum population for each country
egen popmin=min(sp_pop_totl), by(countrycode)
drop if popmin<500000
drop popmin sp_pop_totl

*drop countries that have no debttogdp or gdpgrowth observations
egen no_debttogdp=count(debttogdp) ,by(country)
egen no_gdpgrowth=count(gdpgrowth) ,by(country)
drop if no_debttogdp==0 | no_gdpgrowth==0
*drop observations where we have both debt and growth missing
drop if debttogdp==. & gdpgrowth==.
drop no_debttogdp no_gdpgrowth

*give variables nice var labels
label var debttogdp "Debt to GDP (in \%)"
label var gdpgrowth "GDP growth (in \%)"
label var gdppc "GDP per cap (2010 USD)"

*create a debt_category variable that would put levels of debt in different buckets
g str15 debt_cat="0-30%" if debttogdp<=30
replace debt_cat="30-60%" if debttogdp>30 & debttogdp<=60
replace debt_cat="60-90%" if debttogdp>60 & debttogdp<=90
replace debt_cat="Above 90%" if debttogdp>90 & debttogdp~=.

*a quick look at summary stats
sum gdpgrowth debttogdp gdppc
table country ,contents(freq mean gdpgrowth mean debttogdp min year max year)

*create descriptive statistics table
estpost sum  gdpgrowth debttogdp gdppc ,detail

esttab using "../documents/tables_figures/tab_descriptive_stats.tex",  replace ///
	label title(Summary Statistics) ///
	cells("count(fmt(%9.0gc)) mean(fmt(%9.1fc)) p50(fmt(%9.1fc)) sd(fmt(%9.1fc)) min(fmt(%9.0fc)) max(fmt(%9.0fc))") ///
	noobs nomtitle nonum

*create figure with box plot of GDP growth by debt category	
set scheme s1mono
graph box gdpgrowth , over(debt_cat) medline(lcolor(black)) intensity(0) ///
	marker(1,msize(vsmall)) ///
	ytitle("Real GDP Growth (in %)") ///
	/*title("Contemporaneous relationship between debt and growth")*/ ///
	plotregion(style(none)) 
graph export ../documents/tables_figures/fig_box_annual.eps ,replace


