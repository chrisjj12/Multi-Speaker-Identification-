function test_timit_general_kl_recurrent(modelname_in, theta, eI, stage, iter)
% Copyright (c) 2014-present University of Illinois at Urbana-Champaign
% All rights reserved.
% 		
% Developed by:     Po-Sen Huang, Paris Smaragdis
%                   Department of Electrical and Computer Engineering
%                   Department of Computer Science
%
eval_types={'test'};
normalize = inline('x./max(abs(x)+1e-3)');

for ieval=1:numel(eval_types)

    [s1, fs]=audioread(['audio_denoised.wav']);
    mixture = s1;
    winsize = eI.winsize;    nFFT = eI.nFFT;    hop = eI.hop;    scf=eI.scf; %scf = 2/3;
    windows=sin(0:pi/winsize:pi-pi/winsize);

    %% warpped test_feature into one column -- different results from the matrix version
    if eI.train_mode==3
        testmode=3; % setting
    else
        testmode=1; %test
    end
    [test_data_cell, target_ag, mixture_spectrum]=formulate_data_test(mixture, eI, testmode);

    % convert into matrix
    if isfield(eI, 'isdiscrim')  && eI.isdiscrim==2,
        [ cost, grad, numTotal, pred_cell ] = drdae_discrim_joint_kl_obj( theta, eI, test_data_cell, [], mixture_spectrum, true, true);
%         [ cost, grad, numTotal, pred_cell ] = drdae_discrim_joint_obj( theta, eI, test_data_cell, [], mixture_spectrum, true, true);
    elseif isfield(eI, 'isdiscrim')  && eI.isdiscrim==1,
        [ cost, grad, numTotal, pred_cell ] = drdae_discrim_obj( theta, eI, test_data_cell, [], true, true);
    else
        [ cost, grad, numTotal, pred_cell ] = drdae_obj( theta, eI, test_data_cell, [], true, true);
    end

    %%
    if eI.cleanonly==1,
        pred_source_signal=pred_cell{1};
        pred_source_noise=zeros(size(pred_source_signal));
    else
        outputdim=size(pred_cell{1},1)/2;
        pred_source_noise=pred_cell{1}(1:outputdim,:);
        pred_source_signal=pred_cell{1}(outputdim+1:end,:);
    end

    %% input
    spectrum.mix = scf * stft(mixture, nFFT ,windows, hop);
    phase_mix=angle(spectrum.mix);

    if eI.cleanonly==1,
        pred_source_signal=pred_cell{1};
        pred_source_noise=spectrum.mix-pred_source_signal;
    end

    %% softmask
    gain=1.0;
    % m= double(abs(source_signal)> (gain*abs(source_noise)));
    m= double(abs(pred_source_signal)./(abs(pred_source_signal)+ (gain*abs(pred_source_noise))+eps));

    source_signal = m .*spectrum.mix;
    source_noise  = spectrum.mix-source_signal;

    wavout_noise  = istft(source_noise, nFFT ,windows, hop)';
    wavout_signal = istft(source_signal, nFFT ,windows, hop)';


    if isfield(eI,'ioffset'),
        %fprintf('%s %s ioffset:%d iter:%d - soft mask - \tSDR:%.3f\tSIR:%.3f\tSAR:%.3f\tNSDR:%.3f\n', modelname, stage, eI.ioffset, iter, Parms.SDR, Parms.SIR, Parms.SAR, Parms.NSDR);
          if isfield(eI,'writewav') && eI.writewav==1
            if exist('stage','var')&& (strcmp(stage,'done')||strcmp(stage,'iter'))
                audiowrite(['audio_offset_softmask_source_signal.wav'], normalize(wavout_signal), fs);
            end
          end
    else % finish at once
       %fprintf('%s %s iter:%d - soft mask - \tSDR:%.3f\tSIR:%.3f\tSAR:%.3f\tNSDR:%.3f\n', modelname, stage, iter, Parms.SDR, Parms.SIR, Parms.SAR, Parms.NSDR);
        if isfield(eI,'writewav') && eI.writewav==1
           if exist('stage','var')&& (strcmp(stage,'done')||strcmp(stage,'iter')) % not called by save_callback
               % audiowrite([modelname,num2str(iter),'_softmask_source_noise.wav'], normalize(wavout_noise), fs);
                audiowrite(['ProcessingReady.wav'], normalize(wavout_signal), fs);
           end
        end
    end

    %% record max dev soft SDR: dev/test SDR, iter
%     global SDR;
%     if ieval==1
%         if Parms.SDR> SDR.devmax
%             SDR.devmax=Parms.SDR;
%             SDR.deviter=iter;
%         end
%     else
%         if SDR.deviter==iter
%             SDR.testmax=Parms.SDR;
%         end
%     end
end % eval_type -dev test

return;

%% unit test
% savedir='.';
% iter=200;
% modelname='model_demo';
% load([savedir,modelname, filesep, 'model_',num2str(iter),'.mat']);
% test_timit(modelname, theta, eI)

end
