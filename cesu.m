function BatPower = cesu(Pvend,Pvstart,GenPower,Agc,Mindistance,Mintime,Tvi,AgcTowards,V,Pvbatstart,StateTv)
    global State
    global lastPower
    global Pmax
    global Tcontinue
    
    if StateTv ==1 || Tcontinue >0
        State = 3;
        BatPower =0;
        return
    end
    BatPowerMax = Pmax;
    BatPowerMin = -Pmax;
    if abs(Pvend - Pvstart) < Mindistance
        BatPower = 0;
        State = 3; % 可越过测速，直接响应调节死区
        return
    end
%     if Tvi < Mintime
%         BatPower = 0;
%         return
%     end
    if abs(Pvend - Pvstart)<=9
        if abs(Pvend - GenPower) <=9
            BatPower = Pvend - GenPower;
        else
            BatPower = 0;
        end
    else
        if (GenPower - Pvbatstart)*AgcTowards >= 0
            BatPower = Pvend - GenPower;
        else
            BatPower = 0;
        end
    end
    BatPower = min(BatPower,lastPower+V);
    BatPower = min(BatPower,BatPowerMax);
    BatPower = max(BatPower,lastPower-V);
    BatPower = max(BatPower,BatPowerMin);
    if (GenPower  - Pvend)*AgcTowards >= 0 %+ BatPower
        State = 3;
    end
%     if abs(Agc - GenPower)<9
%         State = 3;
%     end
end