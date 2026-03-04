<Qucs Schematic 25.2.0>
<Properties>
  <View=-1,-198,2470,1165,1.45859,519,524>
  <Grid=10,10,1>
  <DataSet=Stub.dat>
  <DataDisplay=Stub.dpl>
  <OpenDisplay=0>
  <Script=Stub.m>
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
  <GND * 1 920 590 0 0 0 0>
  <Pac P1 1 920 540 18 -26 0 1 "1" 1 "50 Ohm" 1 "0 dBm" 1 "440 MHz" 0 "26.85" 0 "true" 0>
  <SUBST Subst1 1 519 358 -30 24 0 0 "4.4" 1 "0.2104" 1 "35 um" 1 "0.02" 1 "1.68e-8" 1 "0.15e-6" 1>
  <.SP SP1 1 529 168 0 50 0 0 "lin" 1 "400 MHz" 1 "500 MHz" 1 "500" 1 "no" 0 "1" 0 "2" 0 "no" 0 "no" 0>
  <Eqn Eqn1 1 760 180 -23 14 0 0 "Trace_Width=0.3421" 1 "yes" 0>
  <GND * 1 1170 580 0 0 0 0>
  <Pac P2 1 1170 530 18 -26 0 1 "2" 1 "50 Ohm" 1 "0 dBm" 1 "440 MHz" 0 "26.85" 0 "true" 0>
  <CLIN CL3 1 1320 490 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "9.45 mm" 1 "Air" 0 "yes" 0>
  <CLIN CL1 1 1040 490 -26 28 0 0 "Subst1" 1 "CPW_Width" 1 "CPW_Space" 1 "10mm" 1 "Air" 0 "yes" 0>
  <Eqn Eqn2 1 770 260 -23 14 0 0 "CPW_Width=0.6" 1 "CPW_Space=0.20" 1 "yes" 0>
</Components>
<Wires>
  <920 570 920 590 "" 0 0 0 "">
  <920 490 920 510 "" 0 0 0 "">
  <920 490 1010 490 "" 0 0 0 "">
  <1170 560 1170 580 "" 0 0 0 "">
  <1070 490 1170 490 "" 0 0 0 "">
  <1170 490 1170 500 "" 0 0 0 "">
</Wires>
<Diagrams>
  <Smith 770 930 200 200 3 #c0c0c0 1 00 1 0 1 1 1 0 4 1 1 0 1 1 315 0 225 1 0 0 "" "" "">
	<"S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4008e+08 -48 -269 3 0 0>
  </Smith>
  <Rect 1090 880 240 160 3 #c0c0c0 1 01 1 4e+08 2e+07 5e+08 1 0.1 1 1 1 -1 1 1 315 0 225 1 1 0 "" "" "">
	<"S[1,1]" #0000ff 1 3 0 0 0>
	  <Mkr 4.4008e+08 71 85 3 0 0>
	<"S[2,1]" #ff0026 0 3 0 0 0>
	  <Mkr 4.40681e+08 158 -194 3 0 0>
	<"S[3,2]" #ff00ff 1 3 0 0 0>
  </Rect>
</Diagrams>
<Paintings>
</Paintings>
