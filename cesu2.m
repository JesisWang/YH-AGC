function BatPower = cesu2(Pvend,GenPower,AgcTowards,lastPower,V,StateTv)
    global State
    global Pmax
    
    if StateTv ==1
        State = 3;
        BatPower =0;
        return
    end
    BatPowerMax = Pmax;
    BatPowerMin = -Pmax;
    if abs(Pvend - GenPower) < 9
        BatPower = Pvend - GenPower;
    else
        BatPower =0;
    end
    BatPower = min(BatPower,lastPower+V);
    BatPower = min(BatPower,BatPowerMax);
    BatPower = max(BatPower,lastPower-V);
    BatPower = max(BatPower,BatPowerMin);
    if (GenPower + BatPower - Pvend)*AgcTowards >= 0
        State = 3;
    end
end