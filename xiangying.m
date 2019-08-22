function BatPower = xiangying(GenPower,Pallsddead,T,Tsd,AgcTowards,StateTx)
    global State
    
    if StateTx == 1
        State = 2;
        BatPower =0;
        return
    end
    if T <= Tsd
        if (Pallsddead - GenPower)*AgcTowards > 0
            BatPower = (Pallsddead - GenPower)/3*T;
        else
            BatPower = 0;
        end
    else
        if (Pallsddead - GenPower)*AgcTowards > 0
            BatPower = Pallsddead - GenPower;
            if T > 90
                State = 2;
            end
        else
            BatPower = 0;
            State = 2;
        end
    end
end