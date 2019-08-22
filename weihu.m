function BatPower = weihu(Agc,BatSoc,SOCaim,SOCdead,GenPower,Pddead)
    if BatSoc < SOCaim-SOCdead
        if abs(GenPower - Agc) < Pddead
            if Agc - GenPower <0
                BatPower = Agc - GenPower;
            else
                BatPower = 0;
            end
        else
            if Agc - GenPower <0
                BatPower = Agc - GenPower;
            else
                BatPower = 0;
            end
        end
    end
    if BatSoc > SOCaim+SOCdead
        if abs(GenPower - Agc) < Pddead
            if Agc - GenPower >0
                BatPower = Agc - GenPower;
            else
                BatPower = 0;
            end
        else
            if Agc - GenPower >0
                BatPower = Agc - GenPower;
            else
                BatPower = 0;
            end
        end
    end
    if BatSoc >= SOCaim-SOCdead &&  BatSoc <= SOCaim+SOCdead
        BatPower = 0;
    end
end