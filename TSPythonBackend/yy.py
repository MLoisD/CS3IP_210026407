from statsmodels.tsa.stattools import kpss
import pandas  as pd
data = pd.read_csv('datasets/temperature.csv', parse_dates=['date'], index_col='date')
stat, p, lags, crit = kpss(data)
print('stat=%.3f, p=%.3f' % (stat, p))
if p > 0.05:
	print('Probably Stationary - KPSS')
else:
	print('Probably not Stationary - KPSS')

from statsmodels.tsa.stattools import adfuller
data = pd.read_csv('datasets/temperature.csv', parse_dates=['date'], index_col='date')
stat, p, lags, obs, crit, t = adfuller(data)
print('stat=%.3f, p=%.3f' % (stat, p))
if p > 0.05:
	print('Probably not Stationary - ADF')
else:
	print('Probably Stationary - ADF')