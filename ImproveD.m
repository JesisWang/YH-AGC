function [BatPower,BatSoc,Pall] = ImproveD(BatPower,Agc,Pall,BatSoc,Para,Pmax,Peneg)
    global StateTv
    global StateTj
    global AgcTowards
    global Tcontinue
    
    if  max(BatSoc) >= Para(13)-1
        BatPowerMax = Pmax;
        BatPowerMin = 0;
    end
    if  min(BatSoc) <= Para(14)+1
        BatPowerMin = -Pmax;
        BatPowerMax = 0;
    end
    if min(BatSoc) > Para(14)+1 && max(BatSoc) < Para(13)-1
        BatPowerMax = Pmax;
        BatPowerMin = -Pmax;
    end
    Pdg = Pall - BatPower;
    Len = length(Pdg);% ����ָ��ĳ���
    if AgcTowards ==1 
        % �䴢�ܵ����ٶ�ʱ������ʱ��
        [Value,Location] = max(Pdg);
        Len1 = length(max(0,BatPowerMin):Para(11):BatPowerMax);
    else
        [Value,Location] = min(Pdg);
        Len1 = length(BatPowerMin:Para(11):min(0,BatPowerMax));% ��������������Ҫ�Ĳ���
    end
    if Len > Len1+4
        if AgcTowards == 1
            BatPower(Len-4:Len) = max(BatPowerMax,BatPower(Len-4:Len));
            BatPower(Len-Len1-3:Len-4) = max(0:Para(11):BatPowerMax,BatPower(Len-Len1-3:Len-4)');
            BatPower(Len-Len1-3:Len) = min(BatPower(Len-Len1-3:Len),Agc(Len-Len1-3:Len)-Pdg(Len-Len1-3:Len));
        else
            BatPower(Len-4:Len) = min(BatPowerMin,BatPower(Len-4:Len));
            BatPower(Len-Len1-3:Len-4) = min(0:-Para(11):BatPowerMin,BatPower(Len-Len1-3:Len-4)');
            BatPower(Len-Len1-3:Len) = max(BatPower(Len-Len1-3:Len),Agc(Len-Len1-3:Len)-Pdg(Len-Len1-3:Len));
        end
        for i = Len-Len1-3:Len
            % ����SOC
            BatSoc(i) = BatSoc(i-1)-BatPower(i)*1/3600/Peneg*100;
            BatSoc(i) = min(BatSoc(i),100);
            BatSoc(i) = max(BatSoc(i),0);
        end
    end
    Pall = Pdg +BatPower;
    if StateTj == 1 || Tcontinue >0
        % �൱��State =3,4�����֣�State = 1һ������Ӧ��
        % ����ɹ�����������������D
        % �ò���Ҳ�Ѷ�ά������̬����������
        return
    end
    if StateTv == 0 
        % ����δ��ɣ���Ҫ����D��׷��
        if Len>18
            if Location <= Len-Len1-14 && Location > Len1
                % ����������������Ϊ0����ҪLen1+5+Len1�ĳ���,��߳�������ʼʱ��ΪLen-Len1-4
                % Ϊ�˲���������Ĳ��Σ�����߳�������ʼʱ��ǰ��10s������ΪLen-Len1-14
                if AgcTowards == 1 
                    % �Ƚ�ԭ���ݣ�ȡ���ӽ���
                    % ��ʽһ������ָ������ֵ���ǻ������
                    % ��ʽ�����ñ���ָ������ֵΪ������ӽ�AGC��D����
                    % �ô���������ʱ��ά����4��
                    BatPower(Location-Len1+1:Location) = max(0:Para(11):BatPowerMax,BatPower(Location-Len1+1:Location)');
                    BatPower(Location:Location+4) = max(BatPowerMax,BatPower(Location:Location+4));
                    BatPower(Location+4:Location+4+Len1-1) = max(BatPowerMax:-Para(11):0,BatPower(Location+4:Location+4+Len1-1)');
                else
                    BatPower(Location-Len1+1:Location) = min(0:-Para(11):BatPowerMin,BatPower(Location-Len1+1:Location)');
                    BatPower(Location:Location+4) = min(BatPowerMin,BatPower(Location:Location+4));
                    BatPower(Location+4:Location+4+Len1-1) = min(BatPowerMin:Para(11):0,BatPower(Location+4:Location+4++Len1-1)');
                end
                % ����SOC
                for i = Location-Len1+1:Location+4+Len1
                    BatSoc(i) = BatSoc(i-1)-BatPower(i)*1/3600/Peneg*100;
                    BatSoc(i) = min(BatSoc(i),100);
                    BatSoc(i) = max(BatSoc(i),0);
                end
            end
%             if Location >= Len-Len1-4
%                 % �ⲿ���������غϣ����������Ƿ����ֵ��������������Ҫ������ǰ����
%                 if AgcTowards == 1
%                     BatPower(Len-Len1+1:Len) = max(BatPowerMax:-Para(11):0,BatPower(Len-Len1+1:Len)');
%                     BatPower(Len-Len1-3:Len-Len1+1) = max(BatPowerMax,BatPower(Len-Len1-3:Len-Len1+1));
%                     BatPower(Len-2*Len1-2:Len-Len1-3) = max(0:Para(11):BatPowerMax,BatPower(Len-2*Len1-2:Len-Len1-3)');
%                 else
%                     BatPower(Len-Len1+1:Len) = min(BatPowerMin:Para(11):0,BatPower(Len-Len1+1:Len)');
%                     BatPower(Len-Len1-3:Len-Len1+1) = min(BatPowerMin,BatPower(Len-Len1-3:Len-Len1+1));
%                     BatPower(Len-2*Len1-2:Len-Len1-3) = min(0:-Para(11):BatPowerMin,BatPower(Len-2*Len1-2:Len-Len1-3)');
%                 end
%                 % ����SOC
%                 for i = Len-2*Len1-2:Len
%                     BatSoc(i) = BatSoc(i-1)-BatPower(i)*1/3600/Peneg*100;
%                     BatSoc(i) = min(BatSoc(i),100);
%                     BatSoc(i) = max(BatSoc(i),0);
%                 end
%             end
            if Location <= Len1
                if AgcTowards == 1
                    BatPower(2:Len1+1) = max(0:Para(11):BatPowerMax,BatPower(2:Len1+1)');
                    BatPower(Len1+1:Len1+5) = max(BatPowerMax,BatPower(Len1+1:Len1+5));
                    BatPower(Len1+5:2*Len1+4) = max(BatPowerMax:-Para(11):0,BatPower(Len1+5:2*Len1+4)');
                else
                    BatPower(2:Len1+1) = min(0:-Para(11):BatPowerMin,BatPower(2:Len1+1)');
                    BatPower(Len1+1:Len1+5) = min(BatPowerMin,BatPower(Len1+1:Len1+5));
                    BatPower(Len1+5:2*Len1+4) = min(BatPowerMin:Para(11):0,BatPower(Len1+5:2*Len1+4)');
                end
                % ����SOC
                for i = 2:2*Len1+4
                    BatSoc(i) = BatSoc(i-1)-BatPower(i)*1/3600/Peneg*100;
                    BatSoc(i) = min(BatSoc(i),100);
                    BatSoc(i) = max(BatSoc(i),0);
                end
            end
        end
    end
    Pall = Pdg +BatPower;
end