function [BatPower,status] = BatAgcMethod(Agc,GenPower,BatSoc,Verbose)
% function [BatPower,status] = BatAgcMethod(Agc,GenPower,BatSoc,Verbose)
%
% ������ּ��ʵ�ִ���AGC�㷨��������AGC������ֵ�ͻ��鹦������财���ܳ����������
% ���룺
%	Agc��        ��������ʾAGC������ֵ���ɵ��ȸ�������λ��MW��
%	GenPower��   ��������ʾ�������ʵ�⹦��ֵ����λ��MW��
%   BatSoc��     ��������ؿ���������0��100����λ��%��
%   Verbose��    ��������ʾ�澯��ʾ�ȼ���0-9��9��ʾ���澯��0����ʾ�澯��
% �����
%	BatPower��	��������ʾ�����ܹ��ʣ���λ��MW���ŵ�Ϊ����
% �汾������޸��� 2019-06-12
% 2019-06-12 wby
% 1. ��������������������������Ƴ���׫дע�͡�
    
%% ���Ʋ���
    % ȫ�ֱ�������
    global T                            % ָ�����ܼ�ʱ
    global Para                         % ������
    global Pvstart                      % ������ʼ����
    global Pvend                        % ������ֹ����
    global Tsdi                         % ��Ӧ��ʱ
    global Tvi                          % ���ټ�ʱ
    global Tcontinue                    % ����������ʱ
    global Pallsddead                   % �������Ĺ���
    global Tsd                          % ����������Сʱ��
    global Pallddead                    % ������������Ĺ���
    global Pmax                         % ���������
    global lastPower                    % ��һ���Ż��Ĵ��ܹ���
    global State                        % ����ӦK1�ĵ���
    global Pvbatstart                   % ��������������ʼ�����б��
    global AgcTowards                   % ���ڷ����־
    global DetP                         % ����ָ��ĵ������
    global StateTx
    global StateTv
    global StateTj
    global Tjm
    
    status = -1;            % ��ɳ�ʼ����״̬Ϊ-1
    %% ������
    if (isempty(Verbose)||isnan(Verbose))
        Verbose = 0;
    end
    if (isempty(Agc)||isempty(GenPower)||isempty(BatSoc)||isempty(Para)) || ...
       (isnan(Agc)||isnan(GenPower)||isnan(BatSoc)||(sum(isnan(Para))>0)) 
        % ������ڿ������NAN��״̬Ϊ-2
        status = -2;
        WarnLevel = 1;
        if WarnLevel < Verbose
            fprintf('Input data can not be empty or NaN!');
        end
        return
    elseif (length(Para) ~= 15)
        % �������ݸ�ʽ������Ҫ��״̬Ϊ-3
        status = -3;
        WarnLevel = 1;
        if WarnLevel < Verbose
            fprintf('Para data is not correct format!');
        end
        return
    elseif Agc <= 0
        % AGC��ֵС�ڵ���0��״̬Ϊ0
        status = 0;
        WarnLevel = 3;
        if WarnLevel < Verbose
            fprintf('AGC limit is 0!');
        end
        BatPower = 0; 
        return
    end
    BatPower = 0;
    %% AGC�����㷨����
%     if T == 1
%         StateTx =0;
%         StateTv =0;
%         StateTj =0;
%     end
    if State == 1
        BatPower = xiangying(GenPower,Pallsddead,T,Tsd,AgcTowards,StateTx);
    end
    if State == 2
        BatPower = cesu(Pvend,Pvstart,GenPower,Agc,Para(4),Para(5),Tvi,AgcTowards,Para(11),Pvbatstart,StateTv);
    end
    if State == 2.1
        BatPower = cesu2(Pvend,GenPower,AgcTowards,lastPower,Para(11),StateTv);
    end
    if State == 3
        BatPower = tiaojie(GenPower,Agc,Tcontinue,StateTj,Tjm);
    end
    if State == 4
        BatPower = weihu(Agc,BatSoc,Para(12),Para(15),GenPower,Para(7));
    end
    if State == 5
        BatPower = fantiao(lastPower,Agc,GenPower,Tcontinue);
    end
    
    if  BatSoc >= Para(13)
        BatPowerMax = Pmax;
        BatPowerMin = 0;
    end
    if  BatSoc <= Para(14)
        BatPowerMin = -Pmax;
        BatPowerMax = 0;
    end
    if BatSoc > Para(14) && BatSoc < Para(13)
        BatPowerMax = Pmax;
        BatPowerMin = -Pmax;
    end
    if AgcTowards >0
        BatPower = min(BatPower,lastPower+Para(11));
        BatPower = min(BatPower,BatPowerMax);
        BatPower = max(BatPower,lastPower-0.5);
        BatPower = max(BatPower,BatPowerMin);
    else
        BatPower = min(BatPower,lastPower+0.5);
        BatPower = min(BatPower,BatPowerMax);
        BatPower = max(BatPower,lastPower-Para(11));
        BatPower = max(BatPower,BatPowerMin);
    end
    if (BatPower+GenPower - Pallsddead)*AgcTowards >= 0
        Tsdi = Tsdi+1;
        if Tsdi > 4
            StateTx = 1;
%         else
%             StateTx = 0;
        end
    end
    if abs(BatPower+GenPower -Agc) < Para(7)
        Tcontinue = Tcontinue+1;
        if Tcontinue >40
            StateTj = 1;
%         else
%             StateTj = 0;
        end
    end
    if abs(BatPower+GenPower -Agc) < Para(7) && Tjm == 0
        Tjm = 1;
    end
    if (BatPower+GenPower - Pvstart)*AgcTowards > 0 && (BatPower+GenPower - Pvend)*AgcTowards <= 0
        Tvi = Tvi+1;
    end
    if (BatPower+GenPower - Pvend)*AgcTowards >= 0 && Tvi >=10
        StateTv = 1;
    end
end