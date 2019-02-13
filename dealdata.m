%等差插入数值
data2=zeros(3600,4);
data2(1:6:3600,:)=data(1:600,:);
data2(3600,:)=data(600,:);
data2(3599,:)=data(600,:);
for i=7:6:3600
    data2(i-6:i,1)=linspace(data2(i-6,1),data2(i,1),7);
    data2(i-6:i,3)=linspace(data2(i-6,3),data2(i,3),7);
    data2(i-6:i,2)=data2(i,2);
end
Pall=data2(:,3);
Agc=data2(:,1);
Pdg=data2(:,2);
GD2
%等额赋值
for i=1:600
    for j=1:6
        data1(j+(i-1)*6,:)=data(i,:);
    end
end
Pall=data1(:,3);
Agc=data1(:,1);
Pdg=data1(:,2);
GD2

%% 1217的模板
clear
load('YHdata1217.mat')
data=YHdata1217.data21;
for i=1:1200
    for j=1:3
        data1(j+(i-1)*3,:)=data(i,:);
    end
end
Pall=data1(:,1);
Agc=data1(:,2);
Pdg=data1(:,3);
GD2
%% 1222的模板
clear
load('YHdata1222.mat')
data=YHdata1222.data22;
for i=1:600
    for j=1:6
        data1(j+(i-1)*6,:)=data(i,:);
    end
end
Pall=data1(:,3);
Agc=data1(:,1);
Pdg=data1(:,2);
GD2