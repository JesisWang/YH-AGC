function [BatPower,status] = BatAgcMethod(Agc,GenPower,BatSoc,Verbose)
% function [BatPower,status] = BatAgcMethod(Agc,GenPower,BatSoc,Verbose)
%
% 本函数旨在实现储能AGC算法，即根据AGC功率限值和机组功率求解需储能总出力并输出。
% 输入：
%	Agc：        标量，表示AGC功率限值，由调度给定，单位：MW。
%	GenPower：   标量，表示发电机组实测功率值，单位：MW。
%   BatSoc：     标量，电池可用容量，0～100，单位：%。
%   Verbose：    标量，表示告警显示等级，0-9，9显示最多告警，0不显示告警。
% 输出：
%	BatPower：	标量，表示储能总功率，单位：MW，放电为正。
% 版本：最后修改于 2019-06-12
% 2019-06-12 wby
% 1. 建立函数，定义输入输出，编制程序，撰写注释。
    
%% 控制部分
    % 全局变量定义
    global T                            % 指令内总计时
    global Para                         % 参数表
    global Pvstart                      % 测速起始功率
    global Pvend                        % 测速终止功率
    global Tsdi                         % 响应计时
    global Tvi                          % 测速计时
    global Tcontinue                    % 调节死区计时
    global Pallsddead                   % 出死区的功率
    global Tsd                          % 出死区的最小时间
    global Pallddead                    % 进入调节死区的功率
    global Pmax                         % 储能最大功率
    global lastPower                    % 上一步优化的储能功率
    global State                        % 不响应K1的调节
    global Pvbatstart                   % 测速区，储能起始出力判别点
    global AgcTowards                   % 调节方向标志
    global DetP                         % 本次指令的调节深度
    global StateTx
    global StateTv
    global StateTj
    global Tjm
    
    status = -1;            % 完成初始化，状态为-1
    %% 输入检查
    if (isempty(Verbose)||isnan(Verbose))
        Verbose = 0;
    end
    if (isempty(Agc)||isempty(GenPower)||isempty(BatSoc)||isempty(Para)) || ...
       (isnan(Agc)||isnan(GenPower)||isnan(BatSoc)||(sum(isnan(Para))>0)) 
        % 输入存在空数组或NAN，状态为-2
        status = -2;
        WarnLevel = 1;
        if WarnLevel < Verbose
            fprintf('Input data can not be empty or NaN!');
        end
        return
    elseif (length(Para) ~= 15)
        % 参数数据格式不符合要求，状态为-3
        status = -3;
        WarnLevel = 1;
        if WarnLevel < Verbose
            fprintf('Para data is not correct format!');
        end
        return
    elseif Agc <= 0
        % AGC限值小于等于0，状态为0
        status = 0;
        WarnLevel = 3;
        if WarnLevel < Verbose
            fprintf('AGC limit is 0!');
        end
        BatPower = 0; 
        return
    end
    BatPower = 0;
    %% AGC控制算法部分
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