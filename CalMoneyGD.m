function [Rall,RALL]=CalMoneyGD(Agc,Pall,Pbat,F)%
% F = [0.7,0.3,4]
% if lastK1 == 0
%     lastK1 = 1.7;
% end
% lastK1 = 0.7276;
Prate=300;
Emax=4.5;
LineMax=length(Agc(:,1));
% lastK1 = 1.7;
% global Prate;
% global Emax;
% global Result;
% global Rall;
% global LineMax;
% Pall(1:LineMax) = Pdg(1:LineMax)+Pbat(1:LineMax);  % �ܳ���
% Pall = Pdg;  % �ܳ���
% �������ݺϷ���
for i=1:1:LineMax
    if isnan(Agc(i))
        Agc(i) = Agc(i-1);
    end
    if isnan(Pall(i))
        Pall(i) = Pall(i-1);
    end
end

% ������ʼ��
Result = zeros(10,23); 
T1=0;
% ������1,   2,  3, 4,  5, 6,  7, 8, 9,10,  11,  12,13,14,15,16,  17,18,              19,        20,   21,  22,   23
% ���壺Pagc,Pt0,T0,Pt1,T1,Pt2,T2,T3,V,detP,detT,K1,K2,K3,KP,Pend,D, Agc-Pt0(1��-1��),ͬ�����ֵ,Pvst��Tvst,Pvend,Tvend,
Bat = zeros(LineMax,3);
% ������1,   2,        3
% ���壺Pbat,���б���/C,����DOD%
BatResult = zeros(100,7);
% ������1,         2,          3        ,4       ,5       ,6      ,7
% ���壺������DOD%,�����б���/C,���б���/C,ѭ������,����ϵ��,ѭ������,ÿ��ѭ��˥��/%
Result(1,1) = Agc(1);
Result(1,2) = Pall(1);
Result(1,3) = 1;
ctrlNo = 1;
Result(ctrlNo,1) = Agc(1);                  % Pagc
Result(ctrlNo,2) = Pall(1);                 % Pt0
Result(ctrlNo,3) = 1;                       % T0
if Agc(1) > Result(ctrlNo,2)
    Result(ctrlNo,18)=1;
else
    Result(ctrlNo,18)=-1;
end

PALL = Pall(1);

detAGC = 1.0*Prate/100; % detAGC��AGCָ��仯�������������ڲ���仯��0.5
K3dead = 0.5*Prate/100; % K1ָ���ã����鹦�ʴﵽ��AGCָ���������Ŀǰȡ��0.5%�������ʡ�
K2dead = 0.5*Prate/100; % K2ָ���ã����鹦�ʴﵽ��AGCָ���������Ŀǰȡ��0.5%�������ʡ�
Psd    = max(1.0*Prate/100,5); % �����ż�

K1rate = 0.01903;       % ƽ������
K2rate = 300;           % ��׼��Ӧʱ��
K3rate = 0.015;         % ��׼����

K1set = -1;
K2set = -1;
K3set = -1;

V1 = 0;
Va = F(1);
Vb = F(2);
Tconst = F(3);
Pvend = Va*Result(ctrlNo,1)+Vb*PALL;
PMAX = 0;
PMIN = Prate;
VVn = [];
%% ������ط�������
scanRate = 1;
for i=1:1:LineMax
    if ((mod(i,scanRate)==1)||(scanRate==1))
        if (Agc(i) > detAGC+Result(ctrlNo,1)) ||  (Agc(i) < Result(ctrlNo,1)-detAGC) && abs(Agc(i)-Agc(i+1))<0.5
            % ===========================AGCָ��ı䣬ָ��ϲ����=====================================
            if (((Agc(i)-Result(ctrlNo,2))* Result(ctrlNo,18)>0)...         % 1)ָ����ڷ�����ͬ HB
                    &&((Agc(i)-Result(ctrlNo,1))* Result(ctrlNo,18)>0)...   % 2) ���������󣬽�������С
                        && (Result(ctrlNo,8)-Result(ctrlNo,7)<20))          % 3��������������20s 
                if ctrlNo == 1
                    Result(ctrlNo,:) = 0;
                    ctrlNo = ctrlNo+1;
                    Result(ctrlNo,1) = Agc(i);
                    Result(ctrlNo,2) = Pall(i);
                    Result(ctrlNo,3) = i;
                    PALL = Pall(i);
                    Pvend = Va*Result(ctrlNo,1)+Vb*PALL;
                    if Agc(i) > Result(ctrlNo,2)
                        Result(ctrlNo,18)=1;
                    else
                        Result(ctrlNo,18)=-1;
                    end
                else
                    Result(ctrlNo,1) = Agc(i);
                    Result(ctrlNo,6) = 0;
                    Result(ctrlNo,7) = 0;
                    Result(ctrlNo,8) = 0;
                    Result(ctrlNo,10) = 0;
                    PALL = Pall(i);
                    Pvend = Va*Result(ctrlNo,1)+Vb*PALL;
                    if Result(ctrlNo,23) == 0
                        Result(ctrlNo,20:23) = 0;
                    else
                        if abs(Result(ctrlNo,22)-Result(ctrlNo,20))>K3dead && (Result(ctrlNo,23)-Result(ctrlNo,21))>Tconst
                            if V1 ==0
                                V1 = abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60;
                            else
                                V1 = [V1,abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60];
                            end
                        else
                            if V1 == 0
                                V1 = K1set;
                            else
                                V1 = [V1,K1set];
                            end
                        end
                    end
                end
                Result(ctrlNo,20) = 0;
                Result(ctrlNo,21) = 0;
                Result(ctrlNo,22) = 0;
                Result(ctrlNo,23) = 0;
           else
                if ctrlNo == 1
                    Result(ctrlNo,:) = 0;
                    ctrlNo = ctrlNo+1;
                    Result(ctrlNo,1) = Agc(i);
                    Result(ctrlNo,2) = Pall(i);
                    Result(ctrlNo,3) = i;
                    PALL = Pall(i);
                    Pvend = Va*Result(ctrlNo,1)+Vb*PALL;
                    if Agc(i) > Result(ctrlNo,2)
                        Result(ctrlNo,18)=1;
                    else
                        Result(ctrlNo,18)=-1;
                    end
                else
                    Result(ctrlNo,16) = Pall(i);
                    if Result(ctrlNo,18)>0
                        Result(ctrlNo,19) = PMAX;
                    else
                        Result(ctrlNo,19) = PMIN;
                    end
                % ===========================AGCָ��ı䣬�����ϴε������ݣ���¼��һ�ε�����ʼ����=====================================
                    % ����V detP detT K1 K3 K2 Ki D
                    % ==========����K2 ��Ӧʱ��============
                    if (Result(ctrlNo,5)==0) % (��T1)
                        Result(ctrlNo,11) = K2set;
                    else
                        % detT = (T1-T0)
                        Result(ctrlNo,11) = (Result(ctrlNo,5)-Result(ctrlNo,3)); 
                        if (Result(ctrlNo,11)<= K2rate)
                            Result(ctrlNo,13) = 1-Result(ctrlNo,11)/K2rate;
                        else
                            Result(ctrlNo,13) = 0;
                        end
                    end

                    % ==========����K1 ��������============
    %                 if (Result(ctrlNo,7)-Result(ctrlNo,5)>30) % T2-T1>30s
    %                     % V = ABS(Pt2-Pt0)/(T2-T0)*60
    %                     Result(ctrlNo,9) = abs(Result(ctrlNo,6)-Result(ctrlNo,4))/(Result(ctrlNo,7)-Result(ctrlNo,5))*60; % P2-P1/T2-T1
    %                     % K1 = V/K1rate*Prate
    %                     Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
    %                 else
    %                     Result(ctrlNo,9) = K1set;
    %                 end
                    if V1 == 0
                        % �Ǻϲ�
                        V1 = V1(V1>0);
                        if Result(ctrlNo,21) == 0 || Result(ctrlNo,23) == 0
                            Result(ctrlNo,9) = K1set;
                        else
                            if abs(Result(ctrlNo,22)-Result(ctrlNo,20))>=K3dead && (Result(ctrlNo,23)-Result(ctrlNo,21))>Tconst
                                % V = ABS(Pt2-Pt0)/(T2-T0)*60
                                Result(ctrlNo,9) = abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60;
                                V1 = Result(ctrlNo,9);
                                % K1 = V/K1rate*Prate
                                Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                            else
                                Result(ctrlNo,9) = K1set;
                            end
                        end
                    else
                        % �ϲ�ָ��
                        V1 = V1(V1>0);
                        if Result(ctrlNo,21) == 0 || Result(ctrlNo,23) == 0
                            if isempty(V1)
                                Result(ctrlNo,9) = K1set;
                            else
                                Result(ctrlNo,9) = mean(V1);
                                Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                            end
                        else
                            if abs(Result(ctrlNo,22)-Result(ctrlNo,20))>=K3dead && (Result(ctrlNo,23)-Result(ctrlNo,21))>Tconst
                                % V = ABS(Pt2-Pt0)/(T2-T0)*60
                                Result(ctrlNo,9) = abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60;
                                if isempty(V1)
                                    V1 = Result(ctrlNo,9);
                                else
                                    V1 = [V1,Result(ctrlNo,9)];
                                    Result(ctrlNo,9) = mean(V1);
                                end
                                % K1 = V/K1rate*Prate
                                Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                            else
                                if isempty(V1)
                                    Result(ctrlNo,9) = K1set;
                                else
                                    Result(ctrlNo,9) = mean(V1);
                                    Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                                end
                            end
                        end
%                         if V1 > 0
%                             Result(ctrlNo,9) = V1;
%                             Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
%                         else
%                             Result(ctrlNo,9) = V1;
%                             Result(ctrlNo,12) = 0;
%                         end
                    end

                    % ==========����K3 ���ھ���============
                    if (Result(ctrlNo,8)-Result(ctrlNo,7)>20) % T3-T2>20s
                        % detP = detP/(T3-T2)
                        Result(ctrlNo,10) = Result(ctrlNo,10)/(Result(ctrlNo,8)-Result(ctrlNo,7)+1)*scanRate;
                        % K3 = 1-detP/(K3rate*Prate)
                        Result(ctrlNo,14) = 1-Result(ctrlNo,10)/(K3rate*Prate);
                    else
                        Result(ctrlNo,10) = K3set;
                    end

                    if (Result(ctrlNo,5)>0)     % T1>0
                        if (Result(ctrlNo,7)>0) % T2>0
                           % D = Pt2-Pt0
                           Result(ctrlNo,17) = Result(ctrlNo,18)*(Result(ctrlNo,1)-Result(ctrlNo,2));
                        else
                           % D = Pmax-Pt0  
                           Result(ctrlNo,17) = abs((Result(ctrlNo,19)-Result(ctrlNo,2)));
                        end
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
                    if isempty(V1)
                    else
                        VVn = [VVn,V1];
                    end
                    V1 = 0;
                    PALL = Pall(i);
                    Pvend = Va*Result(ctrlNo,1)+Vb*PALL;
                    PMAX = 0;
                    PMIN = Prate;
                end
            end
        else        % ===========================AGCָ��䣬����T1��T2��T3���ۼ�detP=====================================
            PMAX = max(PMAX,Pall(i));
            PMIN = min(PMIN,Pall(i));
            if (Result(ctrlNo,21) == 0)% Pvstû�еõ�
                if (Result(ctrlNo,1) > PALL)
                    if (Pall(i) > PALL+Psd)
                         Result(ctrlNo,21) = i;
                         Result(ctrlNo,20) = Pall(i);
                    end
                else
                    if (Pall(i) < PALL-Psd)
                        Result(ctrlNo,21) = i;
                        Result(ctrlNo,20) = Pall(i);
                    end
                end
            elseif (Result(ctrlNo,23) == 0) % Pvendû�еõ�
                if Result(ctrlNo,18)>0
                    if (Pall(i) > Pvend)
                        Result(ctrlNo,22) = Pall(i);
                        Result(ctrlNo,23) = i;
                    end
                else
                    if (Pall(i) < Pvend)
                        Result(ctrlNo,22) = Pall(i);
                        Result(ctrlNo,23) = i;
                    end
                end
            end
            if (Result(ctrlNo,5) == 0)  % T1δ�õ�
                if (((Result(ctrlNo,1)-Result(ctrlNo,2))*(Pall(i)-Result(ctrlNo,2)))>0)     % �仯����һ��
                    if (abs(Pall(i)-Result(ctrlNo,2))>K2dead)  % ��Pt0����
                        T1 = T1+1;
                        if (T1>4)
                            Result(ctrlNo,4) = Pall(i-4);         % Pt1
                            Result(ctrlNo,5) = i-4;               % T1
                            T1=0;
                        end
                    else
                        T1 = 0;
                    end
                end
            elseif (Result(ctrlNo,7) == 0)  % T2δ�õ�
                if (Result(ctrlNo,1) > Result(ctrlNo,2))    % AGCָ�����Pt0
                    if (Pall(i) > Result(ctrlNo,1)-K3dead)
                        Result(ctrlNo,6) = Pall(i);     % Pt2
                        Result(ctrlNo,7) = i;           % T2
                        Result(ctrlNo,8) = i;           % T3,����ʱ�̾Ϳ�ʼ����
                        Result(ctrlNo,10) = Result(ctrlNo,10) + abs(Agc(i) - Pall(i));
                    end
                else    % AGCָ��С�ڳ���
                    if (Pall(i) < Result(ctrlNo,1)+K3dead)
                        Result(ctrlNo,6) = Pall(i);     % Pt2
                        Result(ctrlNo,7) = i;           % T2
                        Result(ctrlNo,8) = i;           % T3
                        Result(ctrlNo,10) = Result(ctrlNo,10) + abs(Agc(i) - Pall(i));
                    end
                end
            else    % ����T3���ۼ�detP
                if (i-Result(ctrlNo,7))<41  % 40s���ۼ�
                    Result(ctrlNo,8) = i;                   % T3
                    Result(ctrlNo,10) = Result(ctrlNo,10) + abs(Agc(i) - Pall(i));
                end
            end
        end
        if i==LineMax
            % ���һ�����ݺ󣬼���V detP detT K1 K2 K3 KP D M E
            % ����V detP detT K1 K3 K2 Ki D M E
            Result(ctrlNo,16) = Pall(i);
            if Result(ctrlNo,18)>0
                Result(ctrlNo,19) = PMAX;
            else
                Result(ctrlNo,19) = PMIN;
            end
            % ==========����K2 ��Ӧʱ��============
            if (Result(ctrlNo,5)==0) % (��T1)
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

            % ==========����K1 ��������============
%             if (Result(ctrlNo,7)-Result(ctrlNo,5)>30) % T2-T1>30s
%                 % V = ABS(Pt2-Pt0)/(T2-T0)*60
%                 Result(ctrlNo,9) = abs(Result(ctrlNo,6)-Result(ctrlNo,4))/(Result(ctrlNo,7)-Result(ctrlNo,5))*60; % P2-P1/T2-T1
%                 % K1 = V/K1rate*Prate
%                 Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
%             else
%                 Result(ctrlNo,9) = K1set;
%             end
            if V1 == 0
                V1 = V1(V1>0);
                if Result(ctrlNo,21) == 0 || Result(ctrlNo,23) == 0
                    Result(ctrlNo,9) = K1set;
                else
                    if abs(Result(ctrlNo,22)-Result(ctrlNo,20))>=K3dead && (Result(ctrlNo,23)-Result(ctrlNo,21))>Tconst
                        % V = ABS(Pt2-Pt0)/(T2-T0)*60
                        Result(ctrlNo,9) = abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60;
                        V1 = Result(ctrlNo,9);
                        % K1 = V/K1rate*Prate
                        Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                    else
                        Result(ctrlNo,9) = K1set;
                    end
                end
            else
                V1 = V1(V1>0);
                if Result(ctrlNo,21) == 0 || Result(ctrlNo,23) == 0
                    if isempty(V1)
                        Result(ctrlNo,9) = K1set;
                    else
                        Result(ctrlNo,9) = mean(V1);
                        Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                    end
                else
                    if abs(Result(ctrlNo,22)-Result(ctrlNo,20))>=K3dead && (Result(ctrlNo,23)-Result(ctrlNo,21))>Tconst
                        % V = ABS(Pt2-Pt0)/(T2-T0)*60
                        Result(ctrlNo,9) = abs(Result(ctrlNo,22)-Result(ctrlNo,20))/(Result(ctrlNo,23)-Result(ctrlNo,21))*60;
                        if isempty(V1)
                            V1 = Result(ctrlNo,9);
                        else
                            V1 = [V1,Result(ctrlNo,9)];
                            Result(ctrlNo,9) = mean(V1);
                        end
                        % K1 = V/K1rate*Prate
                        Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                    else
                        if isempty(V1)
                            Result(ctrlNo,9) = K1set;
                        else
                            Result(ctrlNo,9) = mean(V1);
                            Result(ctrlNo,12) = min(5, Result(ctrlNo,9)/(K1rate*Prate));
                        end
                    end
                end
            end

            % ==========����K3 ���ھ���============
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
                    Result(ctrlNo,17) = abs(Result(ctrlNo,19)-Result(ctrlNo,2));
                end
            end
            % KP = 0.5*K1+0.25*K2+0.25*K3
            Result(ctrlNo,15) = 0.5*Result(ctrlNo,12)+ 0.25*Result(ctrlNo,13)+ 0.25*Result(ctrlNo,14);
            if isempty(V1)
            else
                VVn = [VVn,V1];
            end
        end
    end
end
% ͳ���վ�K1 K2 K3����K D
K1=0;
K2=0;
K3=0;
K11=0;
K22=0;
K33=0;
K1counter=0;
K2counter=0;
K3counter=0;
%Dall = 0;
for i=2:1:ctrlNo
    if i == ctrlNo
        if Result(i,7)<3600
            if ((Result(i,9))>-1)
                K1 = K1+Result(i,9);
                K1counter=K1counter+1;
                K11 = K11+Result(i,12);
            end
            if ((Result(i,11))>-1)
                K2 = K2+Result(i,11);
                K2counter=K2counter+1;
                K22 = K22+Result(i,13);
            end
            if ((Result(i,10))>-1)
                K3 = K3+Result(i,10);
                K3counter=K3counter+1;
                K33 = K33+Result(i,14);
            end
        end
    else
        if ((Result(i,9))>-1)
            K1 = K1+Result(i,9);
            K1counter=K1counter+1;
            K11 = K11+Result(i,12);
        end
        if ((Result(i,11))>-1)
            K2 = K2+Result(i,11);
            K2counter=K2counter+1;
            K22 = K22+Result(i,13);
        end
        if ((Result(i,10))>-1)
            K3 = K3+Result(i,10);
            K3counter=K3counter+1;
            K33 = K33+Result(i,14);
        end
    end
end
if K1counter==0
    K1counter=1;
    if K2>0
        K1 = lastK1*K1rate*Prate;
        K11 = lastK1;
    else
        K1 = 0;
    end
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
% K2counter/ctrlNo
% Dall
KPall = 0.5*K1+0.25*K2+0.25*K3;
K11 = K11/K1counter;
K22 = K22/K2counter;
K33 = K33/K3counter;
KKPall = 0.5*K11+0.25*K22+0.25*K33;
%% ���������ط�������
batNo = 1;
Bat(:,1) = Pbat;
Bat(:,2) = Bat(:,1);        % ���й���
Bat(:,3) = Bat(:,2)/3600;   % ���е���%
lastBat = Bat(1,1);
counterB = 0;
for i=1:1:LineMax
    if (Bat(i,1)*lastBat<0) % ��ŵ緽��ı�
        BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/120/24; %����ƽ���������������ֵ,2C
        %BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/6/3/6/72; %����ƽ���������������ֵ,3C
        if (BatResult(batNo,2)<0) %����ƽ��������ص���
            BatResult(batNo,2)=BatResult(batNo,2)/3.4;
        else
            BatResult(batNo,2)=BatResult(batNo,2)/3.2;
        end
        BatResult(batNo,2) = abs(BatResult(batNo,2))/120; %����ƽ��������ر��� % �����б���/C
        %BatResult(batNo,2) = abs(BatResult(batNo,2))/40;  %����ƽ��������ر��� % �����б���/C
        BatResult(batNo,1) = BatResult(batNo,2)*counterB/3600*100;                % ������DOD%    
        
        % 2C
        if (BatResult(batNo,2)>1)                               % ���б���/C 1/2,ѭ������ 6000/4000
            BatResult(batNo,3) = 2;
            BatResult(batNo,4) = 4000;
        else
            BatResult(batNo,3) = 1;
            BatResult(batNo,4) = 6000;
        end
%         % 3C
%         if (BatResult(batNo,2)>2)                               % ���б���/C 1/2/3/4,ѭ������ 10224/9725/9225/8726
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
        %BatResult(batNo,5) = 2502550-71290.22364*X+958.96523*X^2-4.30786*X^3;  % ����ϵ����4C
%         BatResult(batNo,5) = (126245.62675*X-4343.98492*X^2+55.75335*X^3-0.24209*X^4)*BatResult(batNo,4)/8726;           % ����ϵ����3C
%         if (X<4.28)
%             BatResult(batNo,5) = (479329.63895-1150.96212*X)*BatResult(batNo,4)/8726;                                     % ����ϵ����3C
%         end
        %BatResult(batNo,5) = 1140532-3158.36*X;                                     % ����ϵ����3C
        BatResult(batNo,5) = (479329.63895-1150.96212*X)*(BatResult(batNo,4)/3644); % ����ϵ����2C
        BatResult(batNo,6) = BatResult(batNo,5)/X*2;            % ѭ������
        BatResult(batNo,7) = 20/BatResult(batNo,6);             % ÿ��ѭ��˥��/%
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
        BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/120/24; %����ƽ���������������ֵ,2C
        %BatResult(batNo,2) = BatResult(batNo,1)/counterB*3600*1000000/Emax/6/3/6/72; %����ƽ���������������ֵ,3C
        if (BatResult(batNo,2)<0) %����ƽ��������ص���
            BatResult(batNo,2)=BatResult(batNo,2)/3.4;
        else
            BatResult(batNo,2)=BatResult(batNo,2)/3.2;
        end
        BatResult(batNo,2) = abs(BatResult(batNo,2))/120; %����ƽ��������ر��� % �����б���/C
        %BatResult(batNo,2) = abs(BatResult(batNo,2))/40;  %����ƽ��������ر��� %
        %�����б���/C
        BatResult(batNo,1) = BatResult(batNo,2)*counterB/3600*100;                % ������DOD%    
        
        if (BatResult(batNo,2)>1)                               % ���б���/C 1/2,ѭ������ 6000/4000
            BatResult(batNo,3) = 2;
            BatResult(batNo,4) = 4000;
        else
            BatResult(batNo,3) = 1;
            BatResult(batNo,4) = 6000;
        end
        X = abs(BatResult(batNo,1));
        %BatResult(batNo,5) = 2502550-71290.22364*X+958.96523*X^2-4.30786*X^3;  % ����ϵ����4C
        %BatResult(batNo,5) = 1140532-3158.36*X;                                     % ����ϵ����3C
        BatResult(batNo,5) = (479329.63895-1150.96212*X)*(BatResult(batNo,4)/3644); % ����ϵ����2C
        BatResult(batNo,6) = BatResult(batNo,5)/X*2;            % ѭ������
        BatResult(batNo,7) = 20/BatResult(batNo,6);             % ÿ��ѭ��˥��/%
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
Rall(5)=Dall;% *15
Rall(6)=sum(abs(Pbat));% ���ܳɱ�
Rall(7)=Rall(5)-Rall(6);
Rall(8)=Days;
RALL(1)=K11;
RALL(2)=K22;
RALL(3)=K33;
RALL(4)=KKPall;
lastK1 = K11;
end
% RALL