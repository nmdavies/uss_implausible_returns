//Neil Davies 18/05/21
//This scripts uses the data from Jorda et al to investigate world equity and bond returns


use "/Users/ecnmd/Downloads/RORE_QJE_replication/data/rore_public_main.dta",clear

joinby iso year using  "/Users/ecnmd/Downloads/RORE_QJE_replication/data/rore_public_supplement.dta" , unmatched(master)

foreach i in eq_tr housing_tr bond_tr{
	gen r_`i' = (1+`i')/(1 + inflation)-1
	gen real_`i'_30=1
	}

//Generate cummulative returns
forvalues i=1(1)30{
	foreach j in eq_tr housing_tr bond_tr{
		bys iso (year): replace real_`j'_30=real_`j'_30*(1+r_`j'[_n+`i'])
		}
	}
	
//Repeating with a rebalanced portfolio of equities and bonds

gen equity=1
gen bonds=1
gen mixed_55=1
forvalues i=1(1)30{
	bys iso (year): replace equity=equity*(1+r_eq_tr[_n+`i'])
	bys iso (year): replace bonds=bonds*(1+r_bond_tr[_n+`i'])
	bys iso (year): replace mixed_55=0.55*mixed_55*(1+r_eq_tr[_n+`i'])+0.45*mixed_55*(1+r_bond_tr[_n+`i'])
	}

gen annual_equity=(exp(ln(equity)/30)-1)*100
gen annual_bond=(exp(ln(bonds)/30)-1)*100
gen annual_mixed_55=(exp(ln(mixed_55)/30)-1)*100



//Create graphs
cap prog drop graph_returns
prog def graph_returns

line `2'   year if country =="`1'" & year<1986, cmiss(n) yline(0.002)  yline(0.2) title("`1'") ///
	graphregion(color(white)) ylab(-2(2)10, nogrid format("%9.0f")) xlab(1870(40)1990, format("%9.0f")) name("graph_`1'", replace) ///
	xtitle("", axis(#)) ytitle("", axis(#))

end

levels country
foreach i in `r(levels)'{
	graph_returns "`i'" "annual_mixed_55"
	}


graph combine graph_Australia graph_Belgium  graph_Denmark graph_Finland graph_France graph_Germany graph_Italy graph_Japan ///
	graph_Netherlands graph_Norway graph_Portugal graph_Spain graph_Sweden graph_Switzerland graph_UK graph_USA, ///
	graphregion(color(white)) l1(Real return percentage point) b1(Year)

//Repeat, but work out the GDP weighted globally diversified returns

//Generate total real GDP for each country
gen real_gdp=pop*rgdpmad
//Generate total GDP of all countries
bys year: egen total_gdp=total(real_gdp)
//Share of GDP
gen share_gdp=real_gdp/total_gdp

//Gen annual returns equities
gen equities_share=share_gdp*r_eq_tr
gen bonds_share=share_gdp*r_bond_tr

bys year: egen total_return_eq=total(equities_share)
bys year: egen total_return_bond=total(bonds_share)

//Generate the returns of a 45:55 portfolio 
gen world_returns_55=1
gen world_returns_65=1
gen world_returns_100=1
gen world_returns_0=1


forvalues i=1(1)30{
	bys iso (year): replace world_returns_55=0.55*world_returns_55*(1+total_return_eq[_n+`i'])+0.45*world_returns_55*(1+total_return_bond[_n+`i'])
	bys iso (year): replace world_returns_65=0.65*world_returns_65*(1+total_return_eq[_n+`i'])+0.35*world_returns_65*(1+total_return_bond[_n+`i'])
	bys iso (year): replace world_returns_100=world_returns_100*(1+total_return_eq[_n+`i'])
	bys iso (year): replace world_returns_0=world_returns_0*(1+total_return_bond[_n+`i'])
	}

	
//This gives 116 observations between 1870 and 1985
sum world_returns_* if country=="USA"


gen annual_world_returns_55=(exp(ln(world_returns_55)/30)-1)*100
gen annual_world_returns_65=(exp(ln(world_returns_65)/30)-1)*100
gen annual_world_returns_100=(exp(ln(world_returns_100)/30)-1)*100
gen annual_world_returns_0=(exp(ln(world_returns_0)/30)-1)*100

//Geometric mean returns
ameans annual_world_returns_* if country=="USA"


cap prog drop graph_returns
prog def graph_returns

line `2'   year if country =="`1'" & year<1986, cmiss(n) yline(0.002)  yline(0.2)  ///
	graphregion(color(white)) ylab(-2(2)10, nogrid format("%9.0f")) xlab(1870(40)1990, format("%9.0f")) name("graph_`1'", replace) ///
	xtitle("", axis(#)) ytitle("", axis(#)) ytitle("Real return percentage point") xtitle("Year")

end

graph_returns  USA annual_world_returns_55
graph_returns  USA annual_world_returns_65
graph_returns  USA annual_world_returns_100
graph_returns  USA annual_world_returns_0

