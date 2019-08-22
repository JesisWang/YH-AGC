function BatPower = fantiao(BatPower,Agc,GenPower,Tcontinue)
    global State
    global Thui
    
    if abs(Agc-GenPower)<9+1 && Tcontinue <40
        BatPower = Agc - GenPower;
    else
        BatPower = min(0,BatPower);
        BatPower = max(0,BatPower);
    end
    if Thui > 5
        State = 1;
    end
end