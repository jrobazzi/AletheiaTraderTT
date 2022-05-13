%load('quotes.mat');
%
lb = min(quotes.lastbar(:,end));
x = quotes.rlogaccum(1,1:lb)';
y = quotes.rlogaccum(2,1:lb)';

% Augment x with ones to accommodate possible offset in the
% regression
% between y vs x.
x=[x ones(size(x))];
delta=0.0001; % delta=0 allows no change (like traditional
% linear regression).
yhat=NaN(size(y)); % measurement prediction
e=NaN(size(y)); % measurement prediction error
Q=NaN(size(y)); % measurement prediction error variance
% For clarity, we denote R(t|t) by P(t).
% initialize P and beta.
P=zeros(2);
beta=NaN(2, size(x, 1));
Vw=delta/(1-delta)*diag(ones(2, 1));
Ve=0.001;
% Initialize beta(:, 1) to zero
beta(:, 1)=-0.5;

for t=1:length(y)
  if (t > 1)
    % Equation 3.7
    R=P+Vw; % state covariance prediction. Equation 3.8
    yhat(t)=x(t, :)*beta(:, t-1); % measurement prediction.
    % Equation 3.9
    Q(t)=x(t, :)*R*x(t, :)'+Ve; % measurement variance
    % prediction. Equation 3.10
    % Observe y(t)
    e(t)=y(t)-yhat(t); % measurement prediction error
    K=R*x(t, :)'/Q(t); % Kalman gain
    beta(:, t)=beta(:, t-1)+K*e(t); % State update.
    % Equation 3.11
    P=R-K*x(t, :)*R; %State covariance update. Euqation 3.12
  end
end
%}
figure(1)
plot(beta(1,:));title('Slope')
figure(2)
plot(beta(2,:));title('Intercept')