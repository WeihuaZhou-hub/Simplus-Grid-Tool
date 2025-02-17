
function [AppMDResults,MdDataSave]=AppModalAnalysis(ModeSelect)

N_Apparatus = evalin('base', 'NumApparatus');
N_Bus = evalin('base', 'NumBus');
ApparatusType = evalin('base', 'ApparatusType');
ApparatusBus = evalin('base', 'ApparatusBus');
ApparatusInputStr = evalin('base', 'ApparatusInputStr');
ApparatusOutputStr = evalin('base', 'ApparatusOutputStr');
GsysSsStateStr=evalin('base', 'GsysSsStateStr');
GsysSs = evalin('base', 'GsysSs');
GmDSS_Cell = evalin('base', 'GmDssCell');
Para = evalin('base', 'Para');
ApparatusPowerFlow = evalin('base', 'ApparatusPowerFlow');
Ts = evalin('base', 'Ts');
ListBus = evalin('base', 'ListBus');

% calculation of residues and device impedance values, at the selected mode
[MdMode,ResidueAll,ZmValAll]=...
    SimplusGT.Modal.SSCal(GsysSs, N_Apparatus, ApparatusType, ModeSelect, GmDSS_Cell, ApparatusInputStr, ApparatusOutputStr);


SelIndex = 1;
ApparatusSelL12 = 0;
ApparatusIndex = 1;
for k = 1:N_Apparatus
    if ApparatusType{k} ~= 100 %not a floating bus)
        ApparatusSelL12(SelIndex) = k;
        SelIndex = SelIndex +1;
        ApparatusIndex = ApparatusIndex +1;
    else % floating bus, infinite bus...
    end        
end
ModeSelNum = length(ModeSelect);
ModeSelAll=ModeSelect;

for modei=1:ModeSelNum
    Residue = ResidueAll{modei};
    ZmVal = ZmValAll{modei};
    FreqSel = imag(MdMode(ModeSelAll(modei)));
    [Layer1, Layer2] = SimplusGT.Modal.MdLayer12(Residue,ZmVal,N_Apparatus,ApparatusBus,...
        ApparatusType,modei,ApparatusSelL12,FreqSel,MdMode(ModeSelAll(modei)));
    MdLayer1(modei).mode = [num2str(FreqSel),'~Hz'];
    MdLayer2(modei).mode = [num2str(FreqSel),'~Hz'];
    for count = 1: length(ApparatusSelL12)
        MdLayer1(modei).result(count).Apparatus={['A',num2str(ApparatusSelL12(count))]};
        MdLayer1(modei).result(count).Abs_Max=Layer1(count);
        MdLayer2(modei).result(count).Apparatus={['A',num2str(ApparatusSelL12(count))]};
        MdLayer2(modei).result(count).DeltaLambdaReal=Layer2.real(count);
        MdLayer2(modei).result(count).DeltaLambdaImag=Layer2.imag(count);
        MdLayer2(modei).result(count).DeltaLambdaRealpu=Layer2.real_pu(count);
        MdLayer2(modei).result(count).DeltaLambdaImagpu=Layer2.imag_pu(count);
    end

    %IMR=zeros(N_Bus,1);
    SigmaMag = abs(real(MdMode(ModeSelAll(modei))))*2*pi; %MdMode is in the unite of Hz, so needs to be changed to rad.
    count=1;
    for k=1:N_Bus
        if ApparatusType{k} ~= 100 % not a floating bus
            IMR.Type(count) = ApparatusType{k};
            IMR.IMRVal(count) = SigmaMag/abs(-1*SimplusGT.inner_product_dq(Residue(k),ZmVal(k)));
            count=count+1;
        end
    end
end

AppMDResults.Layer1=MdLayer1;
AppMDResults.Layer2=MdLayer2;
AppMDResults.IMR=IMR;

%% state-space participation factor
StatePF=SimplusGT.Modal.StatePFCal(GsysSs, ModeSelect);
AppMDResults.StatePF.Val=StatePF;
AppMDResults.StatePF.StateString=GsysSsStateStr;

%% save some data for layer-3
MdDataSave.ResidueAll=ResidueAll;
MdDataSave.ZmValAll=ZmValAll;
MdDataSave.MdMode=MdMode;
MdDataSave.ModeSelAll=ModeSelAll;

end