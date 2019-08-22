% 生成时间序列,可以用seconds,minutes,days,hours,years来生成时间
% datetime(y,m,d,H,M,S)生成时间点
t1 = datetime(2019,3,31,0,0,0);
t2 = datetime(2019,3,31,23,59,59);
T = t1:seconds(1):t2;
% 生成Key-Values的数据存储方式用containers.Map的形式
Tables = contaiT;
Tabels('赵尚玉') = '数据分析师';
