function [BatPower,status] = ControlMethod(Agc,Pdg,BatSoc)
% 本函数旨在实现储能AGC算法，即根据AGC功率限值和机组功率求解需储能总出力并输出。
% 输入：
%	Agc：   标量，表示AGC功率限值，由调度给定，单位：MW。
%	Pdg：   标量，表示发电机组实测功率值，单位：MW。
%   BatSoc：     标量，电池可用容量，0～100，单位：%。
% 输出：
%	BatPower：	标量，表示储能总功率，单位：MW，放电为正。
%	status：     标量，表示储能状态
% 版本：最后修改于 2016-09-13
% 2019-01-17 wby
% 1. 建立函数，定义输入输出，编制程序，撰写注释。
% 全局变量定义
global T             % 全局时间
global PdgStart      % 起始出力
global AgcStart      % 起始Agc
global LastAgc       % 上一次调节的Agc
global Tstart        % 起始时间
% global Pdg_adj_start % 机组的出死区后的起始出力
global fang          % 调节方向
global lastPdg       % 上一时刻的储能出力
global T_fantiao     % 反调时间
global T_butiao      % 不调时间
global lastPall      % 上一时刻的联合出力
% global Pdg_record    % 机组功率：历史1小时记录
global flag          % 机组不调记录标志
global SigFM         % 一次调频信号
global Agc_adj       % 实际响应指标
% global Pall_adj_start % 进入调节时的起始联合功率
global PallStart     % 调节起始时刻的联合功率
global detP
global detP_0
global Pvar

T01=5;% 最小出响应死区时间
ParaSOC=[50 10 90 10];%15 85
% ParaSoc=[期望值 下限 上限 滞环大小]

deadK3=0.005;% K3响应死区
Prgen=300;
Pmax=9;
% Cdead=0.01;
Cdead_Res=0.005;
Flag_adj=1; % 是否响应后续的标志位,1响应,0不响应
Portion_adj=1; % 响应比例,1->100%
if abs(Agc-AgcStart)>3 % Cdead*Prgen % 固定大小:1 % 区间大小:Cdead*Prgen
    % 新来了一条指令，需要更新初始状态
    PdgStart=Pdg;% 初始的机组功率
    LastAgc=AgcStart;
    PallStart=lastPall;
    AgcStart=Agc;% 初始的AGC功率
    Tstart=T;% 初始的机组功率
%     T_fantiao=0;
%     T_butiao=0;
    if PallStart<=AgcStart
        fang=1;% 升出力
    else
        fang=-1;
    end
    Agc_adj=(AgcStart-PdgStart)*Portion_adj+PdgStart;
end
DetP=Agc_adj-PdgStart;% 调节深度
Vn=0.01903*Prgen;% 标准调节速度MW/min
V_ideal=2*Vn/60;% 理想的调节速度,MW/s
Socflag=0;
Ts=T-Tstart;
lastPbat=(lastPall-lastPdg);
if Ts <= T01
    % 在短时的策略下，暂不考虑机组反调的问题
    if Pdg-PallStart < fang*PallStart*deadK3 % 按2MW算  %死区按照1%算：PdgStart*0.01
        % 若机组功率未达到响应死区范围外
        Pall_resp_ideal=lastPall+fang*V_ideal*1;% 理想的联合功率
        if fang>0 && Pdg>Pall_resp_ideal
            Pall_resp_ideal=Pdg;
        end
        if fang<0 && Pdg<Pall_resp_ideal
            Pall_resp_ideal=Pdg;
        end
        BatPower=Pall_resp_ideal-Pdg;% 储能出力
        BatPower=min(BatPower*fang,DetP*fang)*fang;% 与总差值比较
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0);% 超下限，只能充不能放
            Socflag=1;% Soc维护标志
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0);% 超上限，只能放不能冲
            Socflag=1;% Soc维护标志
        end
    else
        Pall_resp_ideal=lastPall+(PallStart*deadK3+0.5)*fang;% 理想的联合功率
        BatPower=Pall_resp_ideal-Pdg;% 储能出力
        BatPower=min(BatPower*fang,DetP*fang)*fang;
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0.8*(lastPall-lastPdg));% 超下限，只能充不能放
            Socflag=1;% Soc维护标志
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0.8*(lastPall-lastPdg));% 超上限，只能放不能冲
            Socflag=1;% Soc维护标志
        end
    end
else
    % 超过5s后的策略
    if Flag_adj==1
%         if Ts == T01+1
%             Pdg_adj_start=Pdg;
%             Pall_adj_start=lastPall;
%         end
        if lastPall>Agc_adj+fang*Cdead_Res*Prgen && lastPall<Agc_adj-fang*Cdead_Res*Prgen
            % 联合出力在调节死区范围捏
            Pall_adj_ideal=Agc_adj;
        else
%             Pall_adj_ideal=Pall_adj_start+fang*V_ideal*(Ts-T01);
            Pall_adj_ideal=lastPall+fang*V_ideal*1;
            Pall_adj_ideal=fang*min(abs(PallStart-Pall_adj_ideal),abs(PallStart-Agc))+PallStart;
        end
        BatPower=Pall_adj_ideal-Pdg;% 储能出力
        BatPower=min(BatPower*fang,DetP*fang)*fang;
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0.8*lastPbat);% 超下限，只能充不能放
            Socflag=1;% Soc维护标志
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0.8*lastPbat);% 超上限，只能放不能冲
            Socflag=1;% Soc维护标志
        end
        if BatSoc<ParaSOC(3) && BatSoc>ParaSOC(2)
            % 储能SOC正常
            Socflag=0;
            if abs(Agc_adj-Pdg)<Cdead_Res*Prgen
%               % 在部分响应出力时，机组到达设定值后，储能转入调节
                % 机组出力到达调节死区，进行SOC补偿维护
                BatPower=Agc_adj-Pdg;% 储能出力
                if BatSoc<ParaSOC(1)-ParaSOC(4)
                    BatPower=min(BatPower,BatPower/2);% 在目标区域以下，尽量充少放
                    Socflag=1;% Soc维护标志
                end
                if BatSoc>ParaSOC(1)+ParaSOC(4)
                    BatPower=max(BatPower,BatPower/2);% 在目标区域以上，尽量放少充
                    Socflag=1;% Soc维护标志
                end
            else
                % 机组未到达死区
                if abs(lastPall-Agc_adj)<Cdead_Res*Prgen
                    % 机组未到达响应设定值，但上一时刻联合到达设定值
                    Pall_adj_ideal=Agc_adj;% 设定为出力值
                    BatPower=Pall_adj_ideal-Pdg;% 储能出力
                end
            end
        end
    else
        BatPower=0.9*lastPbat;% 不响应后，缓慢退出
        if abs(BatPower)<0.1
            BatPower=0;
        end
    end
end
% if T==4681
%     ha=1;
% end
if Pdg-lastPdg~=0
    if (Pdg-Pvar)*(Pdg-Agc)>0
        T_fantiao=T_fantiao+1;
        Pvar=Pdg;
    else
        T_fantiao=0;
        Pvar=Pdg;
    end
end
if T_fantiao>5
    BatPower=0.8*lastPbat;
end
if abs(Pdg-lastPdg)<3 && abs(Pdg-Agc)>Cdead_Res*Prgen
    % 变化小于3MW，且没进入死区
    T_butiao=T_butiao+1;
end

Line=70;
MINN=Vn/60*0.85;% 平均变化速率,MW/s,定为85%的标准调节速率0.1275

if T<=Line
    % 运行时间小于70s内，记录变化差值
    detP_0(T,1)=abs(Pdg-lastPdg);
else
    % 差值只保留70s的时间
    detP_0(1)=[];
    detP_0(70,1)=abs(Pdg-lastPdg);
end
detP=sum(detP_0);
if detP/Line>MINN
    T_butiao=0;
    flag=0;
end
if T_butiao>Line && detP/Line<0.075 && Socflag==0
    % 平均调节速率小于0.075MW/s,标准调节速率的50%
    BatPower=0.9*lastPbat;% 以每秒10%退出
    flag=1;
elseif T_butiao>Line && Socflag==0 && detP/Line<MINN %0.15*0.85
    % 平均调节速率小于标准调节速率的85%
    BatPower=0.95*lastPbat;% 以每秒5%退出
    flag=1;
end

% if (Pdg-lastPdg)*fang<0
%     % 机组反调
%     T_fantiao=T_fantiao+1;
%     if T_fantiao>30
%         % 30s反调
%         BatPower=0.8*lastPbat;% 以每秒20%退出
%     else
%         BatPower=1*lastPbat;
%     end
% else
%     if T_fantiao>0
%         T_fantiao=T_fantiao-1;
%     end
%     if T_record==0
%         if abs(Pdg-lastPdg)<Prgen*0.001
%             T_record=T;
%             T_butiao=T_butiao+1;
%         end
%     else
% %         a=find(Pdg_record~=0,1,'last');
%         detP_0=detP_0+abs(Pdg-lastPdg);
%         if T>100
%             detP_100=detP_100+abs(Pdg-lastPdg);
%             detP=detP_0-detP_100;
%         else
%             detP=detP_0;
%         end
%         if abs(Pdg-lastPdg)<1.5 %0.003*Prgen/60(标准调节速率的20%)
%             % 机组不反调情况下，基本不调
%             T_butiao=T_butiao+1;
%             if T_butiao>100 && detP/100<0.1
%                 % 平局变化量在0.6MW以下算是不动
%                 BatPower=0.9*lastPbat;% 以每秒10%退出
%                 flag=1;
%             end
%         elseif abs(Pdg-lastPdg)<3
%             T_butiao=T_butiao+1;
%             if T_butiao>100 && detP/100<0.15
%                 BatPower=0.98*lastPbat;% 以每秒2%退出
%                 flag=1;
%             end
%         else
%             T_record=0;
%             T_butiao=0;
%             flag=0;
%         end
%         if (Pdg-lastPdg)*fang<0.015*Prgen/60*0.75 && flag==0
%             % 机组不反调情况下，缓调，按标准调节速率算的75%算
%             T_huantiao=T_huantiao+1;
%             if T_huantiao>60
%                 BatPower=0.95*lastPbat;
%             end
%         else
%             T_huantiao=0;
%         end
%     end
% end
%%% 一次调频信号不响应 %%%
if SigFM==1
    BatPower=lastPbat;
end
a=BatPower-lastPbat;
if abs(a)>3.6
    % 瞬间切出特殊情况后，会有一个较大的数值改变，避免这种情况，每秒2MW升降出力
    BatPower=abs(a)/a*2+lastPbat;
end
BatPower=min(BatPower,Pmax);
BatPower=max(BatPower,-Pmax);
status=Socflag;
lastPdg=Pdg;% 上一秒钟的机组出力
lastPall=BatPower+Pdg;% 上一秒中的联合出力