function plotTrainingPerformance(mousedata)

mouse_responses = [];

for x = 1:length(mousedata)
   
    if strcmp(mousedata(x).daqdata.metadata.experiment_type,'Training')
    else
        mousedata(x).daqdata.metadata.experiment_data
        % This is a numbered session that is not
        for each = 1:length(mousedata(x).daqdata.experiment_data.trial_response)
            value = mousedata(x).daqdata.experiment_data.trial_response(each);
            mouse_responses(x,value) = mouse_responses(x,value) + 1;
            
        end

        
    end
    
end



end
