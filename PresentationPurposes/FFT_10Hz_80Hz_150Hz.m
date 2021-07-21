%% Sensor system validation
clear all
close all
clc
t_step=0.005;

%% Bag Read
varname = strings;
filename = "2021-06-08-15-01-03.bag";
bag = rosbag(filename);
k = 1;
for i = 1 : length(bag.AvailableTopics.Row)
    if ((string(bag.AvailableTopics.Row{i}) ~= "/rosout") && (string(bag.AvailableTopics.Row{i}) ~= "/rosout_agg"))
        if (string(bag.AvailableTopics.Row{i}) == "/FSS")
            [t_temp,temp] = topic_read(bag,bag.AvailableTopics.Row{i},'Data');
        else
            [t_temp,temp] = topic_read(bag,bag.AvailableTopics.Row{i},'Data');
        end
        Data.(['t_' bag.AvailableTopics.Row{i}(2:end)]) = t_temp;
        varname(k) = string([bag.AvailableTopics.Row{i}(2:end)]);
        Data.(varname(k)) = temp;
        k = k+1;
    end
    clear t_temp temp
end
clear i bag temp_data k

%% Load cell data interpolation
range_temp_min = [];
range_temp_max = [];
for i = 1 : length(varname)-1
    range_temp_min = [range_temp_min min(Data.(['t_' char(varname(i))]))];
    range_temp_max = [range_temp_max max(Data.(['t_' char(varname(i))]))];
end
t_range = max(range_temp_min) : t_step : min(range_temp_max) ;
t = t_range-max(range_temp_min);

for i = 1 : length(varname)-1
    Data.(varname(i)) = double(Data.(varname(i)));
end

% interp1
for i = 1 : length(varname)-1
    Data_i.(varname(i))=interp1(Data.(['t_' char(varname(i))]),Data.(varname(i)),t_range);
end

%%
Data_i.t_HCmotor = [];
Data_i.HCmotor = [];
temp = 0;
i = 1;
k = 1;
while (i<length(Data.t_HCmotor) && k<length(t_range))
   Data_i.t_HCmotor(k) = t_range(k);
   Data_i.HCmotor(k) = Data.HCmotor(i);
   temp = temp + t_step;
   if(i<length(Data.t_HCmotor)+1)
       if(Data_i.t_HCmotor(k) >= Data.t_HCmotor(i+1))
           i=i+1;
       end
   end
   k = k+1;
end

%%
FSS_sum = sum(transpose(Data_i.FSS));
Initial = 4400;
Final = 5600;
for i = Initial:10:Final
    figure(1)
    set(gcf, 'Position', [0 0 1850 1000])
    
    Fs = 20;
    FSS_sum_array = FSS_sum(i-Fs:i);
    FSS_sum_FFT = fft(FSS_sum_array);
    P2 = abs(FSS_sum_FFT/Fs);
    P1 = P2(1:Fs/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(Fs/2))/Fs;
    f = f(2:end);
    P1 = P1(2:end);
    
    subplot(3,1,1)
    stem(f,P1, 'LineWidth', 2.5)    
    xlim([0 11])
    ylim([0 300000])
    grid on
    title('FFT Data of Sample Frequency 10Hz')
    ylabel('FFT Amplitude')
    xlabel('Sample Frequency(Hz)')
    if(abs(Data_i.HCmotor(i+Fs-1))==10)
        text(8, 180000, 'Slip', 'Color', 'red', 'FontSize', 60)
    else
        text(8, 180000, 'No Slip', 'FontSize', 60)
    end
    
    Fs_2 = 160;
    FSS_sum_array_2 = FSS_sum(i-Fs_2:i);
    FSS_sum_FFT_2 = fft(FSS_sum_array_2);
    P2_2 = abs(FSS_sum_FFT_2/Fs_2);
    P1_2 = P2_2(1:Fs_2/2+1);
    P1_2(2:end-1) = 2*P1_2(2:end-1);
    f_2 = Fs_2*(0:(Fs_2/2))/Fs_2;
    f_2 = f_2(2:end);
    P1_2 = P1_2(2:end);
    
    subplot(3,1,2)
    stem(f_2, P1_2, 'LineWidth', 2.5)
    xlim([0 81])
    ylim([0 300000])
    grid on
    title('FFT Data of Sample Frequency 80Hz')
    ylabel('FFT Amplitude')
    xlabel('Sample Frequency(Hz)')
    
    Fs_3 = 300;
    FSS_sum_array_3 = FSS_sum(i-Fs_3:i);
    FSS_sum_FFT_3 = fft(FSS_sum_array_3);
    P2_3 = abs(FSS_sum_FFT_3/Fs_3);
    P1_3 = P2_3(1:Fs_3/2+1);
    P1_3(2:end-1) = 2*P1_3(2:end-1);
    f_3 = Fs_3*(0:(Fs_3/2))/Fs_3;
    f_3 = f_3(2:end);
    P1_3 = P1_3(2:end);
    
    subplot(3,1,3)
    stem(f_3, P1_3, 'LineWidth', 2.5)
    xlim([0 151])
    ylim([0 300000])
    grid on
    title('FFT Data of Sample Frequency 150Hz')
    ylabel('FFT Amplitude')
    xlabel('Sample Frequency(Hz)')
    
    suptitle(['FFT Data of Sample Frequencies 10Hz, 80Hz, 150Hz (Timestep: ' num2str(i-Initial),')'])
    
    frame = getframe(1);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im,256);
    filename_ = 'FFT_10Hz_80Hz_150Hz.gif';
    del = 0.1;
    if(i == Initial)
      imwrite(imind,cm,filename_,'gif','Loopcount',inf,'DelayTime',del);
    else
      imwrite(imind,cm,filename_,'gif','WriteMode','append','DelayTime',del);
    end
   
end











