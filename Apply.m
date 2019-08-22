% function Apply
clear
load('D:\广东云河\YHEMSdata.mat')
Data = YHdata.data0331;
Agc = Data(:,1);
Pdg = Data(:,2);
%% 全局变量
global T                            % 指令内总计时
global Para                         % 参数表
global Pvstart                      % 测速起始功率
global Pvend                        % 测速终止功率
global Tsdi                         % 响应计时
global Tvi                          % 测速计时
global Tcontinue                    % 调节死区计时
global lastAgc                      % Agc目标值
global Pallsddead                   % 出死区的功率
global Tsd                          % 出死区的最小时间
global Pallddead                    % 进入调节死区的功率
global Pmax                         % 储能最大功率
global lastPower                    % 上一步优化的储能功率
global State                        % 不响应K1的调节
global Pvbatstart                   % 测速区，储能起始出力判别点
global AgcTowards                   % 调节方向标志
global DetP                         % 本次指令的调节深度
global StateTv                      % 测速是否响应完成标志
global StateTx                      % 响应是否响应完成标志
global StateTj                      % 调节是否响应完成标志
global Thui                         % 从反调恢复的标志
global Tjm                          % 进入调节死区且尚未完成40s标志
%% 参数设置
    Pgen = 300;                     % 机组额定功率
    Pmax = 9;                       % 最大功率，MW
    Peneg = 4.5;                    % 额定容量，MWh
    Skj = Pgen;                     % 机组额定功率
    Psddead = min(Skj*0.5/100,5);   % 响应死区大小
    Psddeadi = 0.05;                % 响应死区余量
    Tsd = 3;                        % 最小出响应死区时间
    Pddead = min(Skj*0.5/100,5);    % 调节死区大小
    Pddeadi = 0.05;                 % 调节死区余量
    Tschg = 4;                      % 响应死区维持时间
    Psd = max(Skj*1/100,5);         % 测速起始位置(相对于调节起始功率)
    Psddet = 1;                     % 测速起始位置余量值
    Pendp = 70/100;                 % 测速终止位置比例(整个调节行程70%)
    Pendpdet = 10/100;              % 测速终止位置比例余量值(也是比例)
    Tvschg = 4;                     % 测速区间内最小持续时间
    Pti = Psddead;                  % 测速区间内最小行程
    Tjschg = 40;                    % 调节死区最长持续时间
    Tjschg1 = 20;                   % 调节死区最短持续时间
    V = 1.5;                          % 储能最大调节速率
    K3m = 0.1;                      % 期望K3值
    Detj = (1-K3m)*Pgen*1.5/100;    % 期望K3下的理想平均偏差
    SOCaim = 50;                    % SOC目标值
    SOCup = 90;                     % SOC上限值
    SOCdown = 10;                   % SOC下限值
    SOCdead = 5;                    % SOC死区
    K1mean = 0.01903;               % 区域内所有机组的平均速率
    Pvdet = 1;                      % 测速储能起始出力余量
    Para = [Psddead,Tschg,Psd,Pti,Tvschg,Pendp,Pddead,Detj,Tjschg,Pgen,V,...
        SOCaim,SOCup,SOCdown,SOCdead];
    % para = [1     2     3   4    5      6     7      8    9      10  11
    %   12      13     14      15
    Length = length(Agc);
    Pbat = zeros(Length,1);
    Pall = zeros(Length,1);
    BatSoc = zeros(Length,1);
    BatSoc(1) = Data(1,5); % 设置初始条件
    Pdgv = zeros(1,10); % 计算机组10秒内的平均速率
    T = 0;
    j = 0;
    Tfan = 0; % 反调计时
    Thui = 0; % 回调计时
    %% 初始化第一个参数
    lastPower = 0;
    lastPall = Agc(1)-1;
    AgcTowards = (Agc(1)-lastPall)/abs(Agc(1)-lastPall);
    lastAgc = Agc(1);
    Tvi = 0;
    Tsdi = 0;
    Tcontinue = 0;
    Pallstart = lastPall;
    DetP = abs(Pallstart-lastAgc); % 本次指令的需出力大小
    Pallsddead = Pallstart+(Psddead+Psddeadi)*AgcTowards;
    Pvstart = Pallstart+(Psd-Psddet)*AgcTowards;
    Pvbatstart = Pallstart+(Agc(1)-Pallstart)*Pendp*AgcTowards-Pmax-Pvdet;
    Pvend   = Pallstart+(Agc(1)-Pallstart)*(Pendp+Pendpdet)*AgcTowards;
    Pallddead = lastAgc-(Pddead-Pddeadi)*AgcTowards;
    State = 1;M = 0;Tjm=0;Count = 0;
    StateTv = 0; StateTx = 0; StateTj = 0;
    %% 正式进入循环
    for i = 1:Length
        if i == 1066
            Wang = 99;
        end
        if abs(Agc(i)-lastAgc)>(Para(1)+Para(7)+Psddeadi+Pddeadi) || (Agc(i)-lastAgc)*AgcTowards <0
            % AGC指令发生变化时
            % ===========指令发生合并=========== %
            if (Agc(i)-lastAgc)*AgcTowards>0 ...
                && (Agc(i)-lastPall)*AgcTowards>0 ...
                && Tcontinue < Tjschg1
                % 合并
                % 合并追求D
                Lm = i-Count:i-1;
                [Pbat(Lm),BatSoc(Lm),Pall(Lm)] = ImproveD(Pbat(Lm),Agc(Lm),Pall(Lm),BatSoc(Lm),Para,Pmax,Peneg);
                lastPower = Pbat(i-1);
                lastPall = Pall(i-1);
                AgcTowards = (Agc(i)-lastPall)/abs(Agc(i)-lastPall);
                lastAgc = Agc(i);
                DetP = abs(lastPall-lastAgc);
                Pvstart = lastPall+(Psd-Psddet)*AgcTowards; % 考虑独立核算K1
                Pvend   = lastPall+(Agc(i)-lastPall)*(Pendp+Pendpdet);
                Pvbatstart = Pallstart+(abs(Agc(i)-Pallstart)*Pendp-Pmax-Pvdet)*AgcTowards;
                Pallddead = lastAgc-(Pddead-Pddeadi)*AgcTowards;
                Tvi = 0;
                Tcontinue = 0;
                Pdgv = zeros(1,10);
                j = 0;% 速度时间的计时
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
                    % 直接在死区中
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
                j = 0;% 速度时间的计时,只10s
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
                %% 延迟3秒后,连续10s向AGC指令方向出击,测10s速度
                Pdgv(1:end-1) = Pdgv(2:end);
                Pdgv(end) = abs(PDG-Pdg(i-1));
                j = j+1;
            else
                j = 0;
                Pdgv = zeros(1,10);
            end
        end
        if j>=10 && mean(Pdgv)<K1mean*Pgen/60*0.5 && M == 0
            %机组速率小于0.5倍的标准调节速率
            State = 2.1;% 不响应,这种情况下,响应了k1也不会超过2,且也无法达到K3
%             StateTv = 1;
            M = 1;
        end
        %% 特殊控制,如反调,不调等
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
            % 机组产生反调
            State = 5;
        end
        
        [BatPower,status] = BatAgcMethod(AGC,PDG,BatSoc(i),0);
        lastPower = BatPower;
        Pbat(i) = BatPower;
        Pall(i) = Pbat(i)+Pdg(i);
%         if Pall(i)>Pvstart && Pall(i)< Pvend
%             Tvi = Tvi+1; % 测速区间计时,正常响应4s算成功测算
%         end
        lastPall = Pall(i);
        BatSoc(i+1) = BatSoc(i)-BatPower*1/3600/Peneg*100;
         % 实际上是计算SOE,SOE不准,后期可考虑修改成SOC
        BatSoc(i+1) = min(BatSoc(i+1),100);
        BatSoc(i+1) = max(BatSoc(i+1),0);
    end
    %% 绘图
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