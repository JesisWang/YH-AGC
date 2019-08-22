function BatPower = tiaojie(GenPower,Agc,Tcontinue,StateTj,Tjm)
    global State
    
    if StateTj == 1
        State = 4;
        BatPower =0;
        return
    end
    if Tcontinue <= 40
        if abs(Agc-GenPower) < 9+1
            BatPower = Agc - GenPower;
        else
            if Tjm == 1
                BatPower = Agc - GenPower;
            else
                BatPower = 0;
            end
        end
    else
        BatPower = 0;
        State = 4;
    end
end