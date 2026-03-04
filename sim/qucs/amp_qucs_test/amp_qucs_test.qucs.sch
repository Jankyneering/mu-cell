<Qucs Schematic 25.2.0>
<Properties>
  <View=-505,-738,2120,708,1.02668,0,0>
  <Grid=10,10,1>
  <DataSet=amp_qucs_sim.qucs.dat>
  <DataDisplay=amp_qucs_sim.qucs.dpl>
  <OpenDisplay=0>
  <Script=amp_qucs_sim.m>
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
  <GND * 1 770 230 0 0 0 0>
  <GND * 1 500 320 0 0 0 0>
  <GND * 1 900 320 0 0 0 0>
  <.SP SP1 1 360 60 0 50 0 0 "lin" 1 "400 MHz" 1 "500 MHz" 1 "200" 1 "no" 0 "1" 0 "2" 0 "no" 0 "no" 0>
  <Pac P1 1 500 290 18 -26 0 1 "1" 1 "50 Ohm" 1 "-20 dBm" 1 "1 MHz" 0 "26.85" 0 "true" 0>
  <SPfile X1 1 710 230 -79 -26 0 1 "GRF5604_S3P/GRF5604_DC2322_Vcc12_5p0v_246mA_Vbias5v_P1RFin_P2Vcc1_P3Vcc2_RFout.s3p" 0 "rectangular" 0 "linear" 0 "open" 0 "3" 0>
  <Pac P2 1 900 290 18 -26 0 1 "2" 1 "50 Ohm" 1 "-200 dBm" 0 "1 MHz" 0 "26.85" 0 "true" 0>
</Components>
<Wires>
  <500 260 680 260 "" 0 0 0 "">
  <740 260 900 260 "" 0 0 0 "">
</Wires>
<Diagrams>
  <Rect 1060 130 240 160 3 #c0c0c0 1 01 1 4e+08 2e+07 5e+08 1 19.337 2 24.382 1 -1 1 1 315 0 225 1 3 0 "" "" "">
	<"amp_qucs_sim.qucs:S[2,1]@frequency" #0000ff 0 3 0 0 0>
  </Rect>
</Diagrams>
<Paintings>
</Paintings>
