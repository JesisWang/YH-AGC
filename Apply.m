% function Apply
clear
load('D:\�㶫�ƺ�\YHEMSdata.mat')
Data = YHdata.data0331;
Agc = Data(:,1);
Pdg = Data(:,2);
%% ȫ�ֱ���
global T                            % ָ�����ܼ�ʱ
global Para                         % ������
global Pvstart                      % ������ʼ����
global Pvend                        % ������ֹ����
global Tsdi                         % ��Ӧ��ʱ
global Tvi                          % ���ټ�ʱ
global Tcontinue                    % ����������ʱ
global lastAgc                      % AgcĿ��ֵ
global Pallsddead                   % �������Ĺ���
global Tsd                          % ����������Сʱ��
global Pallddead                    % ������������Ĺ���
global Pmax                         % ���������
global lastPower                    % ��һ���Ż��Ĵ��ܹ���
global State                        % ����ӦK1�ĵ���
global Pvbatstart                   % ��������������ʼ�����б��
global AgcTowards                   % ���ڷ����־
global DetP                         % ����ָ��ĵ������
global StateTv                      % �����Ƿ���Ӧ��ɱ�־
global StateTx                      % ��Ӧ�Ƿ���Ӧ��ɱ�־
global StateTj                      % �����Ƿ���Ӧ��ɱ�־
global Thui                         % �ӷ����ָ��ı�־
global Tjm                          % ���������������δ���40s��־
%% ��������
    Pgen = 300;                     % ��������
    Pmax = 9;                       % ����ʣ�MW
    Peneg = 4.5;                    % �������MWh
    Skj = Pgen;                     % ��������
    Psddead = min(Skj*0.5/100,5);   % ��Ӧ������С
    Psddeadi = 0.05;                % ��Ӧ��������
    Tsd = 3;                        % ��С����Ӧ����ʱ��
    Pddead = min(Skj*0.5/100,5);    % ����������С
    Pddeadi = 0.05;                 % ������������
    Tschg = 4;                      % ��Ӧ����ά��ʱ��
    Psd = max(Skj*1/100,5);         % ������ʼλ��(����ڵ�����ʼ����)
    Psddet = 1;                     % ������ʼλ������ֵ
    Pendp = 70/100;                 % ������ֹλ�ñ���(���������г�70%)
    Pendpdet = 10/100;              % ������ֹλ�ñ�������ֵ(Ҳ�Ǳ���)
    Tvschg = 4;                     % ������������С����ʱ��
    Pti = Psddead;                  % ������������С�г�
    Tjschg = 40;                    % �������������ʱ��
    Tjschg1 = 20;                   % ����������̳���ʱ��
    V = 1.5;                          % ��������������
    K3m = 0.1;                      % ����K3ֵ
    Detj = (1-K3m)*Pgen*1.5/100;    % ����K3�µ�����ƽ��ƫ��
    SOCaim = 50;                    % SOCĿ��ֵ
    SOCup = 90;                     % SOC����ֵ
    SOCdown = 10;                   % SOC����ֵ
    SOCdead = 5;                    % SOC����
    K1mean = 0.01903;               % ���������л����ƽ������
    Pvdet = 1;                      % ���ٴ�����ʼ��������
    Para = [Psddead,Tschg,Psd,Pti,Tvschg,Pendp,Pddead,Detj,Tjschg,Pgen,V,...
        SOCaim,SOCup,SOCdown,SOCdead];
    % para = [1     2     3   4    5      6     7      8    9      10  11
    %   12      13     14      15
    Length = length(Agc);
    Pbat = zeros(Length,1);
    Pall = zeros(Length,1);
    BatSoc = zeros(Length,1);
    BatSoc(1) = Data(1,5); % ���ó�ʼ����
    Pdgv = zeros(1,10); % �������10���ڵ�ƽ������
    T = 0;
    j = 0;
    Tfan = 0; % ������ʱ
    Thui = 0; % �ص���ʱ
    %% ��ʼ����һ������
    lastPower = 0;
    lastPall = Agc(1)-1;
    AgcTowards = (Agc(1)-lastPall)/abs(Agc(1)-lastPall);
    lastAgc = Agc(1);
    Tvi = 0;
    Tsdi = 0;
    Tcontinue = 0;
    Pallstart = lastPall;
    DetP = abs(Pallstart-lastAgc); % ����ָ����������С
    Pallsddead = Pallstart+(Psddead+Psddeadi)*AgcTowards;
    Pvstart = Pallstart+(Psd-Psddet)*AgcTowards;
    Pvbatstart = Pallstart+(Agc(1)-Pallstart)*Pendp*AgcTowards-Pmax-Pvdet;
    Pvend   = Pallstart+(Agc(1)-Pallstart)*(Pendp+Pendpdet)*AgcTowards;
    Pallddead = lastAgc-(Pddead-Pddeadi)*AgcTowards;
    State = 1;M = 0;Tjm=0;Count = 0;
    StateTv = 0; StateTx = 0; StateTj = 0;
    %% ��ʽ����ѭ��
    for i = 1:Length
        if i == 1066
            Wang = 99;
        end
        if abs(Agc(i)-lastAgc)>(Para(1)+Para(7)+Psddeadi+Pddeadi) || (Agc(i)-lastAgc)*AgcTowards <0
            % AGCָ����仯ʱ
            % ===========ָ����ϲ�=========== %
            if (Agc(i)-lastAgc)*AgcTowards>0 ...
                && (Agc(i)-lastPall)*AgcTowards>0 ...
                && Tcontinue < Tjschg1
                % �ϲ�
                % �ϲ�׷��D
                Lm = i-Count:i-1;
                [Pbat(Lm),BatSoc(Lm),Pall(Lm)] = ImproveD(Pbat(Lm),Agc(Lm),Pall(Lm),BatSoc(Lm),Para,Pmax,Peneg);
                lastPower = Pbat(i-1);
                lastPall = Pall(i-1);
                AgcTowards = (Agc(i)-lastPall)/abs(Agc(i)-lastPall);
                lastAgc = Agc(i);
                DetP = abs(lastPall-lastAgc);
                Pvstart = lastPall+(Psd-Psddet)*AgcTowards; % ���Ƕ�������K1
                Pvend   = lastPall+(Agc(i)-lastPall)*(Pendp+Pendpdet);
                Pvbatstart = Pallstart+(abs(Agc(i)-Pallstart)*Pendp-Pmax-Pvdet)*AgcTowards;
                Pallddead = lastAgc-(Pddead-Pddeadi)*AgcTowards;
                Tvi = 0;
                Tcontinue = 0;
                Pdgv = zeros(1,10);
                j = 0;% �ٶ�ʱ��ļ�ʱ
                StateTv = 0;
                Tjm = 0;
                Count = 0;
            else
                Lm = i-Count:i-1;
                [Pbat(Lm),BatSoc(Lm),Pall(Lm)] = ImproveD(Pbat(Lm),Agc(Lm),Pall(Lm),BatSoc(Lm),Para,Pmax,Peneg);
                lastPower = Pbat(i-1);
                lastPall = Pall(i-1);
                AgcTowards = (Agc(i)-lastPall)/abs(Agc(i)-lastPall);
                lastAgc = Agc(i);
                Tvi = 0;
                Tsdi = 0;
                Tcontinue = 0;
                Pallstart = lastPall;
                DetP = abs(Pallstart-lastAgc);
                Pallsddead = Pallstart+(Psddead+Psddeadi)*AgcTowards;
                Pvstart = Pallstart+(Psd-Psddet)*AgcTowards;
                Pvbatstart = Pallstart+(abs(Agc(i)-Pallstart)*Pendp-Pmax-Pvdet)*AgcTowards;
                Pvend   = Pallstart+(Agc(i)-Pallstart)*(Pendp+Pendpdet);
                Pallddead = lastAgc-(Pddead-Pddeadi)*AgcTowards;
                T = 0; 
                Count = 0;
                Tjm = 0;
                if (Agc(i)-lastPall)*AgcTowards <= Pddead+Psddead
                    % ֱ����������
                    State = 3;
                    StateTv = 1;
                    StateTx = 1;
                    StateTj = 0;
                else
                    State = 1;
                    StateTv = 0;
                    StateTx = 0;
                    StateTj = 0;
                end
                Pdgv = zeros(1,10);
                j = 0;% �ٶ�ʱ��ļ�ʱ,ֻ10s
                M = 0;
            end
        end
        T = T+1;
        Count = Count+1;
%         if M == 1 && abs(PDG-Pdg(i))>0.1
%             j = 1;
%             Pdgv = zeros(1,10);
%         end
        AGC = Agc(i);
        PDG = Pdg(i);
        if j<=10 
            if T>=3 % && (PDG-Pdg(i))*(lastAgc-PDG)>=0
                %% �ӳ�3���,����10s��AGCָ������,��10s�ٶ�
                Pdgv(1:end-1) = Pdgv(2:end);
                Pdgv(end) = abs(PDG-Pdg(i-1));
                j = j+1;
            else
                j = 0;
                Pdgv = zeros(1,10);
            end
        end
        if j>=10 && mean(Pdgv)<K1mean*Pgen/60*0.5 && M == 0
            %��������С��0.5���ı�׼��������
            State = 2.1;% ����Ӧ,���������,��Ӧ��k1Ҳ���ᳬ��2,��Ҳ�޷��ﵽK3
%             StateTv = 1;
            M = 1;
        end
        %% �������,�練��,������
        if i>=2 && (PDG-Pdg(i-1))*AgcTowards<=0
            Tfan = Tfan+1;
            if Tfan > 8
                Thui = 0;
            end
        else
            Thui = Thui+1;
            if Thui > 5
                Tfan = 0;
            end
        end
        if Tfan > 30 && State ~=3 && State ~= 4 && State ~= 1 % && DetP-Pddead >= Pmax
            % �����������
            State = 5;
        end
        
        [BatPower,status] = BatAgcMethod(AGC,PDG,BatSoc(i),0);
        lastPower = BatPower;
        Pbat(i) = BatPower;
        Pall(i) = Pbat(i)+Pdg(i);
%         if Pall(i)>Pvstart && Pall(i)< Pvend
%             Tvi = Tvi+1; % ���������ʱ,������Ӧ4s��ɹ�����
%         end
        lastPall = Pall(i);
        BatSoc(i+1) = BatSoc(i)-BatPower*1/3600/Peneg*100;
         % ʵ�����Ǽ���SOE,SOE��׼,���ڿɿ����޸ĳ�SOC
        BatSoc(i+1) = min(BatSoc(i+1),100);
        BatSoc(i+1) = max(BatSoc(i+1),0);
    end
    %% ��ͼ
    figure()
    plot([Agc,Pdg,Pall,Pbat,BatSoc(1:end-1)])
    legend('Agc','Pdg','Pall','Pbat','SOC')
    [Rall,RALL] = CalMoneyGD(Agc,Pall,Pbat,[0.7,0.3,4]);
    Rall(6),Rall(5)
    [RAll,RALL] = CalMoneyGD(Agc,Data(:,3),Data(:,4),[0.7,0.3,4]);
    RAll(6),RAll(5)
    figure()
    plot([Agc,Pdg,Data(:,3),Data(:,4),Data(:,5)])
    legend('Agc','Pdg','Pall','Pbat','SOC')