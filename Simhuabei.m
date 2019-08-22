% 全局变量定义
clear
tic
global T             % 全局时间
global lastPdg       % 上一时刻的储能出力
global lastPall      % 上一时刻的联合出力
global LastAgc
global AgcStart
global Pdg_record
global flag
global Rall
global SigFM
global T_fantiao     % 反调时间
global T_butiao      % 不调时间
global detP
global detP_100
global detP_0
global Pvar
%% 电池SOC-P-V-I关系
load('D:\控制想法实验\PV.mat')
KNAh = 40;Pmax =18;
%%%strct中含有充电电压、充电SOC和放电电压和放电SOC%%%
%% 测试
load('D:\广东云河\YHEMSdata.mat')
data = YHdata.data0331;
Agc = data(:,1);% AGC指令
Pdg = data(:,2);% 机组出力
Pall3=data(:,3);% 实际的联合出力
SigFM=0;
Pdg_record=zeros(3600,1);
LineMax=length(Agc);
SOCini=50;
Emax=9;
SOC=zeros(LineMax,1);
Pbat=zeros(LineMax,1);
Pall=zeros(LineMax,1);
I = zeros(LineMax,1);
SOC(1)=SOCini;
for i=1:LineMax
    T=i;
    if T==1
        lastPdg=Pdg(1);
        lastPall=Pdg(1);
        LastAgc=0;
        AgcStart=0;
        flag=0;
        T_butiao=0;
        T_fantiao=0;
        Pvar=Pdg;
        detP=0;
        detP_100=0;
        detP_0=zeros(70,1);
        lastSOC=SOCini;
    else
        lastSOC=SOC(i-1);
    end
    % 数据更新
    if i<=3600
        Pdg_record(i)=Pdg(i);
    else
        if Pdg_record(3600)~=0
            Pdg_record(1)=[];
            Pdg_record(3600)=Pdg(i);
        end
    end
    [lastPbat,Status] = ControlMethod(Agc(i),Pdg(i),lastSOC);      % AGC算法，华北、山西
    Pbat(i) = lastPbat;
    Pall(i) = Pdg(i)+Pbat(i);
    SOC(i+1)=SOC(i)-lastPbat/3600*100/Emax;

    % 总数据更新
%     if T==1
%         if lastPbat>0
%             SOC(i)=SOCini-lastPbat/3600*100/(Emax*3.07/3.2);
%         else
%             SOC(i)=SOCini-lastPbat/3600*100/(Emax*3.44/3.2);
%         end
% %         SOC(i)=SOCini-lastPbat/3600/Emax*100;
%     else
%         if lastPbat>0
%             SOC(i)=SOC(i-1)-lastPbat/3600*100/(Emax*3.07/3.2);
%         else
%             SOC(i)=SOC(i-1)-lastPbat/3600*100/(Emax*3.44/3.2);
%         end
% %         SOC(i)=SOC(i-1)-lastPbat/3600/Emax*100;
%     end
    SOC(i+1) = min(SOC(i+1),100);  
    SOC(i+1) = max(0,SOC(i+1));    
end
[Rall,RALL,M] = CalMoneyGD(Agc,Pall,Pbat,[0.7,0.3,4]);
% Result=Rall;
% Result=[k1 k2 k3 kp D Income/万元 电池成本 能量]
toc