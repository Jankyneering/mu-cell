<Qucs Schematic 25.2.0>
<Properties>
  <View=-813,-270,3522,2527,1.57116,1753,867>
  <Grid=10,10,1>
  <DataSet=RX_Front-end.qucs.dat>
  <DataDisplay=RX_Front-end.qucs.dpl>
  <OpenDisplay=0>
  <Script=RX_Front-end.qucs.m>
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
  <GND * 1 860 490 0 0 0 0>
  <Pac P1 1 630 440 18 -26 0 1 "1" 1 "50 Ohm" 1 "0 dBm" 0 "1 MHz" 0 "26.85" 0 "true" 0>
  <GND * 1 630 490 0 0 0 0>
  <GND * 1 1010 490 0 0 0 0>
  <.SP SP1 1 500 400 0 50 0 0 "lin" 1 "400 MHz" 1 "500 MHz" 1 "201" 1 "no" 0 "1" 0 "2" 0 "no" 0 "no" 0>
  <C C1 1 700 390 -26 -49 1 0 "100 pF" 1 "" 0 "neutral" 0>
  <R R1 1 720 480 15 -26 0 1 "1 MOhm" 1 "26.85" 0 "0.0" 0 "0.0" 0 "26.85" 0 "US" 0>
  <GND * 1 720 510 0 0 0 0>
  <Pac P2 1 1010 440 18 -26 0 1 "2" 1 "220 Ohm" 1 "0 dBm" 0 "1 MHz" 0 "26.85" 0 "true" 0>
  <C C2 1 960 440 17 -26 0 1 "6 pF" 1 "" 0 "neutral" 0>
  <L L2 1 860 440 10 -26 0 1 "37 nH" 1 "" 0>
  <L L1 1 780 390 -26 10 0 0 "37 nH" 1 "" 0>
</Components>
<Wires>
  <810 390 860 390 "" 0 0 0 "">
  <860 390 860 410 "" 0 0 0 "">
  <860 470 860 490 "" 0 0 0 "">
  <630 470 630 490 "" 0 0 0 "">
  <860 390 960 390 "" 0 0 0 "">
  <1010 390 1010 410 "" 0 0 0 "">
  <1010 470 1010 490 "" 0 0 0 "">
  <730 390 750 390 "" 0 0 0 "">
  <630 390 670 390 "" 0 0 0 "">
  <630 390 630 410 "" 0 0 0 "">
  <670 450 720 450 "" 0 0 0 "">
  <670 390 670 450 "" 0 0 0 "">
  <960 390 960 410 "" 0 0 0 "">
  <960 390 1010 390 "" 0 0 0 "">
  <960 470 1010 470 "" 0 0 0 "">
</Wires>
<Diagrams>
  <Smith 550 790 200 200 3 #c0c0c0 1 00 1 0 1 1 1 0 4 1 1 0 1 1 315 0 225 1 0 0 "" "" "">
	<"RX_Front-end.qucs:S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4e+08 -22 -230 3 0 0>
  </Smith>
  <Rect 860 770 240 160 3 #c0c0c0 1 01 1 4e+08 2e+07 5e+08 1 0.1 1 1 1 -1 1 1 315 0 225 1 1 0 "" "" "">
	<"RX_Front-end.qucs:S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4e+08 256 -171 3 0 0>
	<"RX_Front-end.qucs:S[2,1]" #ff0000 1 3 0 0 0>
	  <Mkr 4.4e+08 256 -228 3 0 0>
  </Rect>
</Diagrams>
<Paintings>
  <Rectangle 940 370 170 160 #000000 1 1 #c0c0c0 1 0>
</Paintings>
