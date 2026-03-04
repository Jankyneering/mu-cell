<Qucs Schematic 25.2.0>
<Properties>
  <View=-17,-234,2225,1498,1.20229,0,618>
  <Grid=10,10,1>
  <DataSet=Wilkinson_divider.dat>
  <DataDisplay=Wilkinson_divider.dpl>
  <OpenDisplay=0>
  <Script=Wilkinson_divider.m>
  <RunScript=0>
  <showFrame=0>
  <FrameText0=Title>
  <FrameText1=Drawn By:>
  <FrameText2=Date:>
  <FrameText3=Revision:>
</Properties>
<Symbol>
</Symbol>
<Components>
  <GND * 1 960 820 0 0 0 0>
  <Pac P1 1 960 770 18 -26 0 1 "1" 1 "50 Ohm" 1 "0 dBm" 1 "440 MHz" 0 "26.85" 0 "true" 0>
  <GND * 1 1800 750 0 0 0 0>
  <Pac P2 1 1800 700 18 -26 0 1 "2" 1 "50 Ohm" 1 "0 dBm" 1 "440 MHz" 0 "26.85" 0 "true" 0>
  <GND * 1 1750 880 0 0 0 0>
  <Pac P3 1 1750 830 18 -26 0 1 "3" 1 "50 Ohm" 1 "0 dBm" 1 "440 MHz" 0 "26.85" 0 "true" 0>
  <SUBST Subst1 1 589 578 -30 24 0 0 "4.4" 1 "0.2104" 1 "35 um" 1 "0.02" 1 "1.68e-8" 1 "0.15e-6" 1>
  <.SP SP1 1 599 388 0 50 0 0 "lin" 1 "400 MHz" 1 "500 MHz" 1 "500" 1 "no" 0 "1" 0 "2" 0 "no" 0 "no" 0>
  <Eqn Eqn1 1 830 400 -23 14 0 0 "Trace_Width=0.3421" 1 "yes" 0>
  <C C1 1 1150 760 17 -26 0 1 "10p" 1 "" 0 "neutral" 0>
  <GND * 1 1150 820 0 0 0 0>
  <L L1 1 1330 660 -26 10 0 0 "27 nH" 1 "" 0>
  <L L2 1 1330 790 -26 10 0 0 "27 nH" 1 "" 0>
  <GND * 1 1430 850 0 0 0 0>
  <R R1 1 1550 730 15 -26 0 1 "100" 1 "26.85" 0 "0.0" 0 "0.0" 0 "26.85" 0 "european" 0>
  <C C3 1 1430 820 17 -26 0 1 "4.7p" 1 "" 0 "neutral" 0>
  <Eqn Eqn2 1 840 480 -23 14 0 0 "CPW_Width=0.3421" 1 "CPW_Space=0.5" 1 "yes" 0>
  <CLIN CL2 1 1630 660 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "25 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL3 1 1630 790 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "25 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL4 1 1270 660 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "1mm" 1 "Air" 0 "yes" 0>
  <CLIN CL6 1 1190 720 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 ".5 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL5 1 1270 790 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "1 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL1 1 1080 720 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "10 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL7 1 1390 660 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 ".5 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL8 1 1390 790 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 ".5 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL9 1 1470 660 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 ".5 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL10 1 1470 790 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 ".5 mm" 1 "Air" 0 "yes" 0>
  <C C4 1 1430 630 17 -26 0 1 "4.7p" 1 "" 0 "neutral" 0>
  <GND * 1 1430 600 0 -16 1 0>
</Components>
<Wires>
  <960 800 960 820 "" 0 0 0 "">
  <1800 730 1800 750 "" 0 0 0 "">
  <1750 860 1750 880 "" 0 0 0 "">
  <1150 720 1150 730 "" 0 0 0 "">
  <1150 790 1150 820 "" 0 0 0 "">
  <1660 790 1750 790 "" 0 0 0 "">
  <1750 790 1750 800 "" 0 0 0 "">
  <1660 660 1800 660 "" 0 0 0 "">
  <1800 660 1800 670 "" 0 0 0 "">
  <960 720 960 740 "" 0 0 0 "">
  <960 720 1050 720 "" 0 0 0 "">
  <1110 720 1150 720 "" 0 0 0 "">
  <1150 720 1160 720 "" 0 0 0 "">
  <1220 720 1240 720 "" 0 0 0 "">
  <1240 660 1240 720 "" 0 0 0 "">
  <1240 720 1240 790 "" 0 0 0 "">
  <1420 790 1430 790 "" 0 0 0 "">
  <1500 660 1550 660 "" 0 0 0 "">
  <1500 790 1550 790 "" 0 0 0 "">
  <1550 660 1550 700 "" 0 0 0 "">
  <1550 660 1600 660 "" 0 0 0 "">
  <1550 760 1550 790 "" 0 0 0 "">
  <1550 790 1600 790 "" 0 0 0 "">
  <1420 660 1430 660 "" 0 0 0 "">
  <1430 790 1440 790 "" 0 0 0 "">
  <1430 660 1440 660 "" 0 0 0 "">
</Wires>
<Diagrams>
  <Rect 430 1190 240 160 3 #c0c0c0 1 01 1 4e+08 2e+07 5e+08 1 0.1 1 1 1 -1 1 1 315 0 225 1 1 0 "" "" "">
	<"S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4008e+08 171 65 3 0 0>
	<"S[2,1]" #ff0026 0 3 0 0 0>
	  <Mkr 4.40681e+08 158 -194 3 0 0>
	<"S[3,2]" #ff00ff 1 3 0 0 0>
	  <Mkr 4.4008e+08 154 -105 3 0 0>
  </Rect>
  <Smith 820 1200 200 200 3 #c0c0c0 1 00 1 0 1 1 1 0 4 1 1 0 1 1 315 0 225 1 0 0 "" "" "">
	<"S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4008e+08 182 -159 3 0 0>
	<"S[2,1]" #ff0000 1 3 0 0 0>
	<"S[2,2]" #ff00ff 1 3 0 0 0>
  </Smith>
</Diagrams>
<Paintings>
</Paintings>
