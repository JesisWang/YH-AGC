% Agc=1;
% Pdg=1;
% Pbat=1;
% Pall=1;
Prate=300;
Emax=10;
LineMax=length(Agc(:,1));
% global Prate;
% global Emax;
% global Result;
% global Rall;
% global LineMax;
% Pall(1:LineMax) = Pdg(1:LineMax)+Pbat(1:LineMax);  % 总出力
% Pall = Pdg;  % 总出力
% 检验数据合法性
for i=1:1:LineMax
    if isnan(Agc(i))
        Agc(i) = Agc(i-1);
    end
    if isnan(Pall(i))
        Pall(i) = Pall(i-1);
    end
end

% 变量初始化
Result = zeros(100,23); 
T1=0;
% 列数：1,   2,  3, 4,  5, 6,  7, 8, 9,10,  11,  12,13,14,15,16, 17,18
% 定义：Pagc,Pt0,T0,Pt1,T1,Pt2,T2,T3,V,detP,detT,K1,K2,K3,KP,Pend,D,Agc-Pt0（1升-1降）
Bat = zeros(LineMax,3);
% 列数：1,   2,        3
% 定义：Pbat,运行倍率/C,运行DOD%
BatResult = zeros(100,7);
% 列数：1,         2,          3        ,4       ,5       ,6      ,7
% 定义：次运行DOD%,次运行倍率/C,运行倍率/C,循环基数,换能系数,循环次数,每次循环衰减/%
Result(1,1) = Agc(1);
Result(1,2) = Pall(1);
Result(1,3) = 1;
ctrlNo = 1;
Result(ctrlNo,1) = Agc(1);                  % Pagc
Result(ctrlNo,2) = Pall(1);                 % Pt0
Result(ctrlNo,3) = 1;                       % T0

detAGC = 0.5*Prate/100; % detAGC是AGC指令变化的死区，死区内不算变化。
K1dead = 0.5*Prate/100; % K1指标用，机组功率达到新AGC指令的死区，目前取的0.5%机组额定功率。
K2dead = 0.5*Prate/100; % K2指标用，机组功率达到新AGC指令的死区，目前取的0.5%机组额定功率。

K1rate = 0.01903;       % 平均速率
K2rate = 300;           % 标准响应时间
K3rate = 0.015;         % 标准精度

K1set = -1;
K2set = -1;
K3set = -1;
% 收益相关分析计算
scanRate = 1;
for i=1:1:LineMax
    if ((mod(i,scanRate)==1)||(scanRate==1))
        if (Agc(i) > detAGC+Result(ctrlNo,1)) ||  (Agc(i) < Result(ctrlNo,1)-detAGC)
            % ===========================AGC指令改变，指令合并情况=====================================
            if (((Agc(i)-Result(ctrlNo,2))* Result(ctrlNo,18)>0)...         % 1)指令调节方向相同 HB
                    &&((Agc(i)-Result(ctrlNo,1))* Result(ctrlNo,18)>0)...   % 2) 升出力更大，降出力更小
                    && (Result(ctrlNo,8)-Result(ctrlNo,7)<15))               % 3）进入死区不足15s 
                Result(ctrlNo,1) = Agc(i);
                Result(ctrlNo,6) = 0;
                Result(ctrlNo,7) = 0;
                Result(ctrlNo,8) = 0;
                Result(ctrlNo,10) = 0;
            else
                Result(ctrlNo,16) = Pall(i);
            % ===========================AGC指令改变，计算上次调整数据，记录新一次调整初始数据=====================================
                % 计算V detP detT K1 K3 K2 Ki D
                % ==========计算K2 响应时间============
                if (Result(ctrlNo,5)==0) % (无T1)
                    Result(ctrlNo,11) = K2set;
                else
                    % detT = (T1-T0)
                    Result(ctrlNo,11) = (Result(ctrlNo,5)-Result(ctrlNo,3)); 
                    if (Result(ctrlNo,11)<K2rate)
                        Result(ctrlNo,13) = 1-Result(ctrlNo,11)/K2rate;
                    else
                        Result(ctrlNo,11) = K2set;
                    end
                end

                % ==========计算K1 调节速率============
                if (Result(ctrlNo,7)-Result(ctrlNo,5)>30) % T2-T1>30s
                    % V = ABS(Pt2-Pt0)/(T2-T0)*60
                    Result(ctrlNo,9) = abs(Result(ctrlNo,6)-Result(ctrlNo,4))/(Result(ctrlNo,7)-Result(ctrlNo,5))*60; % P2-P1/T2-T1
                    % K1 = V/K1rate*Prate
                    Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                else
                    Result(ctrlNo,9) = K1set;
                end

                % ==========计算K3 调节精度============
                if (Result(ctrlNo,8)-Result(ctrlNo,7)>20) % T3-T2>20s
                    % detP = detP/(T3-T2)
                    Result(ctrlNo,10) = Result(ctrlNo,10)/(Result(ctrlNo,8)-Result(ctrlNo,7))*scanRate;
                    % K2 = 1-detP/(K3rate*Prate)
                    Result(ctrlNo,14) = 1-Result(ctrlNo,10)/(K3rate*Prate);
                else
                    Result(ctrlNo,10) = K3set;
                end

                if (Result(ctrlNo,5)>0)     % T1>0
                    %if (Result(ctrlNo,7)>0) % T2>0
                    %    % D = Pt2-Pt0
                    %    Result(ctrlNo,17) = abs(Result(ctrlNo,6)-Result(ctrlNo,2));
                    %else
                        % D = Pend-Pt0
                        Result(ctrlNo,17) = abs(Result(ctrlNo,16)-Result(ctrlNo,2));
                    %end
                end
                % KP = 0.5*K1+0.25*K2+0.25*K3
                Result(ctrlNo,15) = 0.5*Result(ctrlNo,12)+ 0.25*Result(ctrlNo,13)+ 0.25*Result(ctrlNo,14);
                ctrlNo = ctrlNo + 1;
                Result(ctrlNo,1) = Agc(i);                  % Pagc
                Result(ctrlNo,2) = Pall(i);                 % Pt0
                Result(ctrlNo,3) = i;                       % T0
                if Agc(i) > Result(ctrlNo,2)
                    Result(ctrlNo,18)=1;
                else
                    Result(ctrlNo,18)=-1;
                end
            end
        else        % ===========================AGC指令不变，计算T1、T2、T3并累加detP=====================================
            if (Result(ctrlNo,5) == 0)  % T1未得到
                if (((Result(ctrlNo,1)-Result(ctrlNo,2))*(Pall(i)-Result(ctrlNo,2)))>0)     % 变化方向一致
                    if (abs(Pall(i)-Result(ctrlNo,2))>K2dead)  % 出Pt0死区
                        T1 = T1+1;
                        if (T1>4)
                            Result(ctrlNo,4) = Pall(i);         % Pt1
                            Result(ctrlNo,5) = i;               % T1
                            T1=0;
                        end
                    end
                end
            elseif (Result(ctrlNo,7) == 0)  % T2未得到
                if (Result(ctrlNo,1) > Result(ctrlNo,2))    % AGC指令大于Pt0
                    if (Pall(i) > Result(ctrlNo,1)-K1dead)
                        Result(ctrlNo,6) = Pall(i);     % Pt2
                        Result(ctrlNo,7) = i;           % T2
                    end
                else    % AGC指令小于出力
                    if (Pall(i) < Result(ctrlNo,1)+K1dead)
                        Result(ctrlNo,6) = Pall(i);     % Pt2
                        Result(ctrlNo,7) = i;           % T2
                    end
                end
            else    % 更新T3并累加detP
                if (i-Result(ctrlNo,7))<40  % 40s内累加
                    Result(ctrlNo,8) = i;                   % T3
                    Result(ctrlNo,10) = Result(ctrlNo,10) + abs(Agc(i) - Pall(i));
                end
            end
        end
        if i==LineMax
            % 最后一个数据后，计算V detP detT K1 K2 K3 KP D M E
            % 计算V detP detT K1 K3 K2 Ki D M E
            Result(ctrlNo,16) = Pall(i);
            % ==========计算K2 响应时间============
            if (Result(ctrlNo,5)==0) % (无T1)
                Result(ctrlNo,11) = K2set;
            else
                % detT = (T1-T0)
                Result(ctrlNo,11) = (Result(ctrlNo,5)-Result(ctrlNo,3)); 
                if (Result(ctrlNo,11)<K2rate)
                    Result(ctrlNo,13) = 1-Result(ctrlNo,11)/K2rate;
                else
                    Result(ctrlNo,11) = K2set;
                end
            end

            % ==========计算K1 调节速率============
            if (Result(ctrlNo,7)-Result(ctrlNo,5)>30) % T2-T1>30s
                % V = ABS(Pt2-Pt0)/(T2-T0)*60
                Result(ctrlNo,9) = abs(Result(ctrlNo,6)-Result(ctrlNo,4))/(Result(ctrlNo,7)-Result(ctrlNo,5))*60; % P2-P1/T2-T1
                % K1 = V/K1rate*Prate
                Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
            else
                Result(ctrlNo,9) = K1set;
            end

            % ==========计算K3 调节精度============
            if (Result(ctrlNo,8)-Result(ctrlNo,7)>20) % T3-T2>20s
                % detP = detP/(T3-T2)
                Result(ctrlNo,10) = Result(ctrlNo,10)/(Result(ctrlNo,8)-Result(ctrlNo,7))*scanRate;
                % K2 = 1-detP/(K3rate*Prate)
                Result(ctrlNo,14) = 1-Result(ctrlNo,10)/(K3rate*Prate);
            else
                Result(ctrlNo,10) = K3set;
            end

            if (Result(ctrlNo,5)>0)     % T1>0
                if (Result(ctrlNo,7)>0) % T2>0
                    % D = Pt2-Pt0
                    Result(ctrlNo,17) = abs(Result(ctrlNo,6)-Result(ctrlNo,2));
                else
                    % D = Pend-Pt0
                    Result(ctrlNo,17) = abs(Result(ctrlNo,16)-Result(ctrlNo,2));
                end
            end
            % KP = 0.5*K1+0.25*K2+0.25*K3
            Result(ctrlNo,15) = 0.5*Result(ctrlNo,12)+ 0.25*Result(ctrlNo,13)+ 0.25*Result(ctrlNo,14);
        end
    end
end
% 统计日均K1 K2 K3和总K D
K1=0;
K2=0;
K3=0;
K1counter=0;
K2counter=0;
K3counter=0;
%Dall = 0;
for i=1:1:ctrlNo
    if ((Result(i,9))>-1)
        K1 = K1+Result(i,9);
        K1counter=K1counter+1;
    end
    if ((Result(i,11))>-1)
        K2 = K2+Result(i,11);
        K2counter=K2counter+1;
    end
    if ((Result(i,10))>-1)
        K3 = K3+Result(i,10);
        K3counter=K3counter+1;
    end
end
if K1counter==0
    K1counter=1;
end
if K2counter==0
    K2counter=1;
end
if K3counter==0
    K3counter=1;
end
K1 = min(5, (K1/K1counter)/(K1rate*Prate));
K2 = 1-(K2/K2counter)/K2rate;
K3 = 1-(K3/K3counter)/(K3rate*Prate);
Dall = sum(Result(:,17));
KPall = 0.5*K1+0.25*K2+0.25*K3;
    
% 电池寿命相关分析计算
batNo = 1;
Bat(:,1) = Pbat;
Bat(:,2) = Bat(:,1);        % 运行功率
Bat(:,3) = Bat(:,2)/3600;   % 运行电量%
lastBat = Bat(1,1);
counterB = 0;
for i=1:1:LineMax
    if (Bat(i,1)*lastBat<0) % 充放电方向改变
        BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/120/24; %计算平均单串电输出功率值,2C
        %BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/6/3/6/72; %计算平均单串电输出功率值,3C
        if (BatResult(batNo,2)<0) %计算平均单串电池电流
            BatResult(batNo,2)=BatResult(batNo,2)/3.4;
        else
            BatResult(batNo,2)=BatResult(batNo,2)/3.2;
        end
        BatResult(batNo,2) = abs(BatResult(batNo,2))/120; %计算平均单串电池倍率 % 次运行倍率/C
        %BatResult(batNo,2) = abs(BatResult(batNo,2))/40;  %计算平均单串电池倍率 % 次运行倍率/C
        BatResult(batNo,1) = BatResult(batNo,2)*counterB/3600*100;                % 次运行DOD%    
        
        % 2C
        if (BatResult(batNo,2)>1)                               % 运行倍率/C 1/2,循环基数 6000/4000
            BatResult(batNo,3) = 2;
            BatResult(batNo,4) = 4000;
        else
            BatResult(batNo,3) = 1;
            BatResult(batNo,4) = 6000;
        end
%         % 3C
%         if (BatResult(batNo,2)>2)                               % 运行倍率/C 1/2/3/4,循环基数 10224/9725/9225/8726
%             BatResult(batNo,3) = 3;
%             BatResult(batNo,4) = 9225;
%         elseif (BatResult(batNo,2)>1)
%             BatResult(batNo,3) = 1;
%             BatResult(batNo,4) = 9725;
%         else
%             BatResult(batNo,3) = 1;
%             BatResult(batNo,4) = 10224;
%         end
        X = abs(BatResult(batNo,1));
        %BatResult(batNo,5) = 2502550-71290.22364*X+958.96523*X^2-4.30786*X^3;  % 换能系数，4C
%         BatResult(batNo,5) = (126245.62675*X-4343.98492*X^2+55.75335*X^3-0.24209*X^4)*BatResult(batNo,4)/8726;           % 换能系数，3C
%         if (X<4.28)
%             BatResult(batNo,5) = (479329.63895-1150.96212*X)*BatResult(batNo,4)/8726;                                     % 换能系数，3C
%         end
        %BatResult(batNo,5) = 1140532-3158.36*X;                                     % 换能系数，3C
        BatResult(batNo,5) = (479329.63895-1150.96212*X)*(BatResult(batNo,4)/3644); % 换能系数，2C
        BatResult(batNo,6) = BatResult(batNo,5)/X*2;            % 循环次数
        BatResult(batNo,7) = 20/BatResult(batNo,6);             % 每次循环衰减/%
        if isnan(BatResult(batNo,7))
            BatResult(batNo,7) =0;
        end
        batNo = batNo+1;
        BatResult(batNo,1) = Bat(i,3);
        BatResult(batNo,2) = Bat(i,2);
        counterB = 0;
    else
        BatResult(batNo,1) = BatResult(batNo,1)+Bat(i,3);
        BatResult(batNo,2) = BatResult(batNo,2)+Bat(i,2);
    end
    if (i==LineMax)
        BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/120/24; %计算平均单串电输出功率值,2C
        %BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/6/3/6/72; %计算平均单串电输出功率值,3C
        if (BatResult(batNo,2)<0) %计算平均单串电池电流
            BatResult(batNo,2)=BatResult(batNo,2)/3.4;
        else
            BatResult(batNo,2)=BatResult(batNo,2)/3.2;
        end
        BatResult(batNo,2) = abs(BatResult(batNo,2))/120; %计算平均单串电池倍率 % 次运行倍率/C
        %BatResult(batNo,2) = abs(BatResult(batNo,2))/40;  %计算平均单串电池倍率 %
        %次运行倍率/C
        BatResult(batNo,1) = BatResult(batNo,2)*counterB/3600*100;                % 次运行DOD%    
        
        if (BatResult(batNo,2)>1)                               % 运行倍率/C 1/2,循环基数 6000/4000
            BatResult(batNo,3) = 2;
            BatResult(batNo,4) = 4000;
        else
            BatResult(batNo,3) = 1;
            BatResult(batNo,4) = 6000;
        end
        X = abs(BatResult(batNo,1));
        %BatResult(batNo,5) = 2502550-71290.22364*X+958.96523*X^2-4.30786*X^3;  % 换能系数，4C
        %BatResult(batNo,5) = 1140532-3158.36*X;                                     % 换能系数，3C
        BatResult(batNo,5) = (479329.63895-1150.96212*X)*(BatResult(batNo,4)/3644); % 换能系数，2C
        BatResult(batNo,6) = BatResult(batNo,5)/X*2;            % 循环次数
        BatResult(batNo,7) = 20/BatResult(batNo,6);             % 每次循环衰减/%
        if isnan(BatResult(batNo,7))
            BatResult(batNo,7) =0;
        end
    end
    lastBat = Bat(i,1);
    counterB = counterB+1;
end
BatDeath = sum(BatResult(:,7)); % SOC%
Days = 20/BatDeath;

Rall(1)=K1;
Rall(2)=K2;
Rall(3)=K3;
Rall(4)=KPall;
Rall(5)=Dall;
Rall(8)=Days;