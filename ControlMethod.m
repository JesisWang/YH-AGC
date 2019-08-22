function [BatPower,status] = ControlMethod(Agc,Pdg,BatSoc)
% ������ּ��ʵ�ִ���AGC�㷨��������AGC������ֵ�ͻ��鹦������财���ܳ����������
% ���룺
%	Agc��   ��������ʾAGC������ֵ���ɵ��ȸ�������λ��MW��
%	Pdg��   ��������ʾ�������ʵ�⹦��ֵ����λ��MW��
%   BatSoc��     ��������ؿ���������0��100����λ��%��
% �����
%	BatPower��	��������ʾ�����ܹ��ʣ���λ��MW���ŵ�Ϊ����
%	status��     ��������ʾ����״̬
% �汾������޸��� 2016-09-13
% 2019-01-17 wby
% 1. ��������������������������Ƴ���׫дע�͡�
% ȫ�ֱ�������
global T             % ȫ��ʱ��
global PdgStart      % ��ʼ����
global AgcStart      % ��ʼAgc
global LastAgc       % ��һ�ε��ڵ�Agc
global Tstart        % ��ʼʱ��
% global Pdg_adj_start % ����ĳ����������ʼ����
global fang          % ���ڷ���
global lastPdg       % ��һʱ�̵Ĵ��ܳ���
global T_fantiao     % ����ʱ��
global T_butiao      % ����ʱ��
global lastPall      % ��һʱ�̵����ϳ���
% global Pdg_record    % ���鹦�ʣ���ʷ1Сʱ��¼
global flag          % ���鲻����¼��־
global SigFM         % һ�ε�Ƶ�ź�
global Agc_adj       % ʵ����Ӧָ��
% global Pall_adj_start % �������ʱ����ʼ���Ϲ���
global PallStart     % ������ʼʱ�̵����Ϲ���
global detP
global detP_0
global Pvar

T01=5;% ��С����Ӧ����ʱ��
ParaSOC=[50 10 90 10];%15 85
% ParaSoc=[����ֵ ���� ���� �ͻ���С]

deadK3=0.005;% K3��Ӧ����
Prgen=300;
Pmax=9;
% Cdead=0.01;
Cdead_Res=0.005;
Flag_adj=1; % �Ƿ���Ӧ�����ı�־λ,1��Ӧ,0����Ӧ
Portion_adj=1; % ��Ӧ����,1->100%
if abs(Agc-AgcStart)>3 % Cdead*Prgen % �̶���С:1 % �����С:Cdead*Prgen
    % ������һ��ָ���Ҫ���³�ʼ״̬
    PdgStart=Pdg;% ��ʼ�Ļ��鹦��
    LastAgc=AgcStart;
    PallStart=lastPall;
    AgcStart=Agc;% ��ʼ��AGC����
    Tstart=T;% ��ʼ�Ļ��鹦��
%     T_fantiao=0;
%     T_butiao=0;
    if PallStart<=AgcStart
        fang=1;% ������
    else
        fang=-1;
    end
    Agc_adj=(AgcStart-PdgStart)*Portion_adj+PdgStart;
end
DetP=Agc_adj-PdgStart;% �������
Vn=0.01903*Prgen;% ��׼�����ٶ�MW/min
V_ideal=2*Vn/60;% ����ĵ����ٶ�,MW/s
Socflag=0;
Ts=T-Tstart;
lastPbat=(lastPall-lastPdg);
if Ts <= T01
    % �ڶ�ʱ�Ĳ����£��ݲ����ǻ��鷴��������
    if Pdg-PallStart < fang*PallStart*deadK3 % ��2MW��  %��������1%�㣺PdgStart*0.01
        % �����鹦��δ�ﵽ��Ӧ������Χ��
        Pall_resp_ideal=lastPall+fang*V_ideal*1;% ��������Ϲ���
        if fang>0 && Pdg>Pall_resp_ideal
            Pall_resp_ideal=Pdg;
        end
        if fang<0 && Pdg<Pall_resp_ideal
            Pall_resp_ideal=Pdg;
        end
        BatPower=Pall_resp_ideal-Pdg;% ���ܳ���
        BatPower=min(BatPower*fang,DetP*fang)*fang;% ���ܲ�ֵ�Ƚ�
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0);% �����ޣ�ֻ�ܳ䲻�ܷ�
            Socflag=1;% Socά����־
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0);% �����ޣ�ֻ�ܷŲ��ܳ�
            Socflag=1;% Socά����־
        end
    else
        Pall_resp_ideal=lastPall+(PallStart*deadK3+0.5)*fang;% ��������Ϲ���
        BatPower=Pall_resp_ideal-Pdg;% ���ܳ���
        BatPower=min(BatPower*fang,DetP*fang)*fang;
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0.8*(lastPall-lastPdg));% �����ޣ�ֻ�ܳ䲻�ܷ�
            Socflag=1;% Socά����־
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0.8*(lastPall-lastPdg));% �����ޣ�ֻ�ܷŲ��ܳ�
            Socflag=1;% Socά����־
        end
    end
else
    % ����5s��Ĳ���
    if Flag_adj==1
%         if Ts == T01+1
%             Pdg_adj_start=Pdg;
%             Pall_adj_start=lastPall;
%         end
        if lastPall>Agc_adj+fang*Cdead_Res*Prgen && lastPall<Agc_adj-fang*Cdead_Res*Prgen
            % ���ϳ����ڵ���������Χ��
            Pall_adj_ideal=Agc_adj;
        else
%             Pall_adj_ideal=Pall_adj_start+fang*V_ideal*(Ts-T01);
            Pall_adj_ideal=lastPall+fang*V_ideal*1;
            Pall_adj_ideal=fang*min(abs(PallStart-Pall_adj_ideal),abs(PallStart-Agc))+PallStart;
        end
        BatPower=Pall_adj_ideal-Pdg;% ���ܳ���
        BatPower=min(BatPower*fang,DetP*fang)*fang;
        if BatSoc<ParaSOC(2)
            BatPower=min(BatPower,0.8*lastPbat);% �����ޣ�ֻ�ܳ䲻�ܷ�
            Socflag=1;% Socά����־
        end
        if BatSoc>ParaSOC(3)
            BatPower=max(BatPower,0.8*lastPbat);% �����ޣ�ֻ�ܷŲ��ܳ�
            Socflag=1;% Socά����־
        end
        if BatSoc<ParaSOC(3) && BatSoc>ParaSOC(2)
            % ����SOC����
            Socflag=0;
            if abs(Agc_adj-Pdg)<Cdead_Res*Prgen
%               % �ڲ�����Ӧ����ʱ�����鵽���趨ֵ�󣬴���ת�����
                % ������������������������SOC����ά��
                BatPower=Agc_adj-Pdg;% ���ܳ���
                if BatSoc<ParaSOC(1)-ParaSOC(4)
                    BatPower=min(BatPower,BatPower/2);% ��Ŀ���������£��������ٷ�
                    Socflag=1;% Socά����־
                end
                if BatSoc>ParaSOC(1)+ParaSOC(4)
                    BatPower=max(BatPower,BatPower/2);% ��Ŀ���������ϣ��������ٳ�
                    Socflag=1;% Socά����־
                end
            else
                % ����δ��������
                if abs(lastPall-Agc_adj)<Cdead_Res*Prgen
                    % ����δ������Ӧ�趨ֵ������һʱ�����ϵ����趨ֵ
                    Pall_adj_ideal=Agc_adj;% �趨Ϊ����ֵ
                    BatPower=Pall_adj_ideal-Pdg;% ���ܳ���
                end
            end
        end
    else
        BatPower=0.9*lastPbat;% ����Ӧ�󣬻����˳�
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
    % �仯С��3MW����û��������
    T_butiao=T_butiao+1;
end

Line=70;
MINN=Vn/60*0.85;% ƽ���仯����,MW/s,��Ϊ85%�ı�׼��������0.1275

if T<=Line
    % ����ʱ��С��70s�ڣ���¼�仯��ֵ
    detP_0(T,1)=abs(Pdg-lastPdg);
else
    % ��ֵֻ����70s��ʱ��
    detP_0(1)=[];
    detP_0(70,1)=abs(Pdg-lastPdg);
end
detP=sum(detP_0);
if detP/Line>MINN
    T_butiao=0;
    flag=0;
end
if T_butiao>Line && detP/Line<0.075 && Socflag==0
    % ƽ����������С��0.075MW/s,��׼�������ʵ�50%
    BatPower=0.9*lastPbat;% ��ÿ��10%�˳�
    flag=1;
elseif T_butiao>Line && Socflag==0 && detP/Line<MINN %0.15*0.85
    % ƽ����������С�ڱ�׼�������ʵ�85%
    BatPower=0.95*lastPbat;% ��ÿ��5%�˳�
    flag=1;
end

% if (Pdg-lastPdg)*fang<0
%     % ���鷴��
%     T_fantiao=T_fantiao+1;
%     if T_fantiao>30
%         % 30s����
%         BatPower=0.8*lastPbat;% ��ÿ��20%�˳�
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
%         if abs(Pdg-lastPdg)<1.5 %0.003*Prgen/60(��׼�������ʵ�20%)
%             % ���鲻��������£���������
%             T_butiao=T_butiao+1;
%             if T_butiao>100 && detP/100<0.1
%                 % ƽ�ֱ仯����0.6MW�������ǲ���
%                 BatPower=0.9*lastPbat;% ��ÿ��10%�˳�
%                 flag=1;
%             end
%         elseif abs(Pdg-lastPdg)<3
%             T_butiao=T_butiao+1;
%             if T_butiao>100 && detP/100<0.15
%                 BatPower=0.98*lastPbat;% ��ÿ��2%�˳�
%                 flag=1;
%             end
%         else
%             T_record=0;
%             T_butiao=0;
%             flag=0;
%         end
%         if (Pdg-lastPdg)*fang<0.015*Prgen/60*0.75 && flag==0
%             % ���鲻��������£�����������׼�����������75%��
%             T_huantiao=T_huantiao+1;
%             if T_huantiao>60
%                 BatPower=0.95*lastPbat;
%             end
%         else
%             T_huantiao=0;
%         end
%     end
% end
%%% һ�ε�Ƶ�źŲ���Ӧ %%%
if SigFM==1
    BatPower=lastPbat;
end
a=BatPower-lastPbat;
if abs(a)>3.6
    % ˲���г���������󣬻���һ���ϴ����ֵ�ı䣬�������������ÿ��2MW��������
    BatPower=abs(a)/a*2+lastPbat;
end
BatPower=min(BatPower,Pmax);
BatPower=max(BatPower,-Pmax);
status=Socflag;
lastPdg=Pdg;% ��һ���ӵĻ������
lastPall=BatPower+Pdg;% ��һ���е����ϳ���