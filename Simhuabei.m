% ȫ�ֱ�������
clear
tic
global T             % ȫ��ʱ��
global lastPdg       % ��һʱ�̵Ĵ��ܳ���
global lastPall      % ��һʱ�̵����ϳ���
global LastAgc
global AgcStart
global Pdg_record
global flag
global Rall
global SigFM
global T_fantiao     % ����ʱ��
global T_butiao      % ����ʱ��
global detP
global detP_100
global detP_0
global Pvar
%% ���SOC-P-V-I��ϵ
load('D:\�����뷨ʵ��\PV.mat')
KNAh = 40;Pmax =18;
%%%strct�к��г���ѹ�����SOC�ͷŵ��ѹ�ͷŵ�SOC%%%
%% ����
load('D:\�㶫�ƺ�\YHEMSdata.mat')
data = YHdata.data0331;
Agc = data(:,1);% AGCָ��
Pdg = data(:,2);% �������
Pall3=data(:,3);% ʵ�ʵ����ϳ���
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
    % ���ݸ���
    if i<=3600
        Pdg_record(i)=Pdg(i);
    else
        if Pdg_record(3600)~=0
            Pdg_record(1)=[];
            Pdg_record(3600)=Pdg(i);
        end
    end
    [lastPbat,Status] = ControlMethod(Agc(i),Pdg(i),lastSOC);      % AGC�㷨��������ɽ��
    Pbat(i) = lastPbat;
    Pall(i) = Pdg(i)+Pbat(i);
    SOC(i+1)=SOC(i)-lastPbat/3600*100/Emax;

    % �����ݸ���
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
% Result=[k1 k2 k3 kp D Income/��Ԫ ��سɱ� ����]
toc