import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.tsa.stattools import adfuller
from pmdarima import auto_arima
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import warnings
import math
warnings.filterwarnings("ignore")

#constants
SEQ_LEN = 14
FUTURE_HORIZON = 30
ROLLING_WINDOWS = [7, 14]
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

#creating set
class TimeSeriesDataset(Dataset):
    def __init__(self, X, y):
        self.X = torch.tensor(X, dtype=torch.float32)
        self.y = torch.tensor(y, dtype=torch.float32)

    def __len__(self):
        return len(self.X)

    def __getitem__(self, idx):
        return self.X[idx], self.y[idx]


#128 was small enough since both sets were under 2k in size

class LSTMModel(nn.Module):
    def __init__(self, input_size, hidden_size=128, num_layers=1, dropout=0.2, num_heads=4):
        super().__init__()
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers=num_layers, batch_first=True)
        self.attention = nn.MultiheadAttention(hidden_size, num_heads=num_heads)
        self.batch_norm = nn.BatchNorm1d(hidden_size)
        self.dropout = nn.Dropout(dropout)
        self.fc = nn.Linear(hidden_size, 1)

    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        attn_input = lstm_out.permute(1, 0, 2)  # seq_len, batch, hidden
        attn_out, _ = self.attention(attn_input, attn_input, attn_input)
        final_out = attn_out[-1]
        final_out = self.batch_norm(final_out)
        final_out = self.dropout(final_out)
        return self.fc(final_out)


def fit_sarima_model(series):
    if adfuller(series.dropna())[1] > 0.05:
        print("Applying differencing for stationarity.")
        series = series.diff().dropna()

    model = auto_arima(series, seasonal=True, m=7, stepwise=True, suppress_warnings=True)
    print(f"Selected SARIMA{model.order} x {model.seasonal_order}")
    return model.fit(series)


def prepare_features(series, external=None, seq_len=SEQ_LEN):
    df = pd.DataFrame({'target': series})
    correlations = {}

    if external:
        for name, ext_series in external.items():
            aligned = ext_series.reindex(series.index).ffill().bfill()
            corr = series.corr(aligned)
            correlations[name] = corr

            if abs(corr) > 0.2:
                df[name] = aligned
                for lag in [1, 3, 7, 14]:
                    df[f'{name}_lag_{lag}'] = aligned.shift(lag)

    for i in range(1, seq_len + 1):
        df[f'lag_{i}'] = series.shift(i)

    for w in ROLLING_WINDOWS:
        df[f'mean_{w}'] = series.rolling(w, min_periods=1).mean()
        df[f'std_{w}'] = series.rolling(w, min_periods=1).std().fillna(0)

    df = df.fillna(0)

    print(f"Using features: {list(df.columns)}")
    print(f"Correlations: {correlations}")

    scaler = MinMaxScaler(feature_range=(-1, 1))
    scaled = scaler.fit_transform(df)

    X, y = [], []
    for i in range(len(scaled) - seq_len):
        X.append(scaled[i:i + seq_len])
        y.append(scaled[i + seq_len, 0])

    return np.array(X), np.array(y), scaler


def train_model(model, X_train, y_train, X_val, y_val, batch_size=32, epochs=200):
    model.to(DEVICE)
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'min', patience=5)
    criterion = nn.MSELoss()

    train_loader = DataLoader(TimeSeriesDataset(X_train, y_train), batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(TimeSeriesDataset(X_val, y_val), batch_size=batch_size)

    best_loss = float('inf')
    patience_counter = 0
    train_losses, val_losses = [], []

    for epoch in range(epochs):
        model.train()
        epoch_loss = 0

        for X_batch, y_batch in train_loader:
            X_batch, y_batch = X_batch.to(DEVICE), y_batch.to(DEVICE)
            optimizer.zero_grad()
            loss = criterion(model(X_batch), y_batch.unsqueeze(1))
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        model.eval()
        val_loss = sum(criterion(model(X.to(DEVICE)), y.to(DEVICE).unsqueeze(1)).item()
                       for X, y in val_loader) / len(val_loader)

        train_loss = epoch_loss / len(train_loader)
        train_losses.append(train_loss)
        val_losses.append(val_loss)
        scheduler.step(val_loss)

        if val_loss < best_loss:
            best_loss = val_loss
            best_model = model.state_dict().copy()
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= 10:
                break

        if epoch % 10 == 0:
            print(f"Epoch {epoch+1} | Train Loss: {train_loss:.4f} | Val Loss: {val_loss:.4f}")

    model.load_state_dict(best_model)
    
    # Return the losses for plotting
    return model, train_losses, val_losses


def generate_forecast(mood_df, temp_df=None, forecast_days=FUTURE_HORIZON):
    mood_series = mood_df.iloc[:, 0]

    try:
        sarima = fit_sarima_model(mood_series)
        in_sample_pred = sarima.predict_in_sample()
        residuals = mood_series - in_sample_pred
    except Exception as e:
        print(f"SARIMA failed: {e}")
        return naive_forecast(mood_series, forecast_days)

    external = {'temp': temp_df.iloc[:, 0]} if temp_df is not None else None

    try:
        X, y, scaler = prepare_features(residuals, external)
    except Exception as e:
        print(f"Feature prep failed: {e}")
        return sarima_forecast_only(sarima, forecast_days)

    # Train/test split
    split = int(len(X) * 0.8)
    X_train, X_test = X[:split], X[split:]
    y_train, y_test = y[:split], y[split:]

    model = LSTMModel(input_size=X.shape[2])
    model, train_losses, val_losses = train_model(model, X_train, y_train, X_test, y_test)

    model.eval()
    with torch.no_grad():
        preds = model(torch.tensor(X, dtype=torch.float32).to(DEVICE)).cpu().numpy().flatten()

    forecast_dates = mood_series.index[SEQ_LEN:]
    hist = pd.DataFrame({
        'actual': mood_series[SEQ_LEN:],
        'sarima_pred': in_sample_pred[SEQ_LEN:],
        'hybrid_pred': in_sample_pred[SEQ_LEN:] + preds
    }, index=forecast_dates)

    future_residual = preds[-1]
    future_base = sarima.predict(n_periods=forecast_days)
    final = pd.DataFrame({
        'forecast': np.round(future_base.values + future_residual),
        'sarimax_pred': np.round(future_base.values)
    }, index=future_base.index)

    return hist, final, train_losses, val_losses


def naive_forecast(series, horizon):
    last = round(series.iloc[-1])
    index = pd.date_range(series.index[-1] + pd.Timedelta(days=1), periods=horizon)
    return pd.DataFrame({'forecast': [last]*horizon, 'sarimax_pred': [last]*horizon}, index=index)

def sarima_forecast_only(model, horizon):
    future = model.predict(n_periods=horizon)
    return pd.DataFrame({'forecast': future, 'sarimax_pred': future}, index=future.index)


def plot_forecast(history, forecast):
    plt.figure(figsize=(16, 8))
    plt.plot(history.index, history['actual'], label='Actual Plot')
    plt.plot(history.index, history['hybrid_pred'], label='Hybrid (SARIMA+LSTM)')
    #plt.plot(history.index, history['sarima_pred'], label='SARIMA', linestyle='--')
    plt.plot(forecast.index, forecast['forecast'], label='Hybrid Forecast')
    plt.plot(forecast.index, forecast['sarimax_pred'], label='SARIMA Forecast', linestyle='--')
    plt.title('Mood Forecast')
    plt.xlabel('Date')
    plt.ylabel('Score')
    plt.legend()
    plt.grid()
    plt.tight_layout()
    plt.show()


def plot_residuals(history):
    plt.figure(figsize=(14, 7))
    
    #calc and plot residuals
    sarima_residuals = history['actual'] - history['sarima_pred']
    hybrid_residuals = history['actual'] - history['hybrid_pred']
    plt.plot(history.index, sarima_residuals, label='SARIMA Residuals', color='blue', alpha=0.7)
    plt.plot(history.index, hybrid_residuals, label='Hybrid Model Residuals', color='red', alpha=0.7)
    
    plt.axhline(y=0, color='black', linestyle='-', alpha=0.3)
    plt.title('Model Residuals Comparison')
    plt.xlabel('Date')
    plt.ylabel('Residual Value')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()
    
    # Print statistics
    print("\nResidual Statistics:")
    print(f"SARIMA - Mean: {sarima_residuals.mean():.4f}, Std: {sarima_residuals.std():.4f}")
    print(f"Hybrid - Mean: {hybrid_residuals.mean():.4f}, Std: {hybrid_residuals.std():.4f}")


def plot_training_losses(train_losses, val_losses):
    plt.figure(figsize=(12, 6))
    epochs = range(1, len(train_losses) + 1)
    
    plt.plot(epochs, train_losses, 'b-', label='Training Loss')
    plt.plot(epochs, val_losses, 'r-', label='Validation Loss')
    
    plt.title('Training and Validation Loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


def calculate_and_print_metrics(history):
    models = ['sarima', 'hybrid']
    if 'arima_pred' in history.columns:
        models.append('arima')
    
    # Calculate metrics
    metrics = {}
    
    for model_name in models:
        predictions = history[f'{model_name}_pred']
        actual = history['actual']
        
        mse = mean_squared_error(actual, predictions)
        rmse = math.sqrt(mse)
        mae = mean_absolute_error(actual, predictions)
        
        # Calculate MAPE
        mape = np.mean(np.abs((actual - predictions) / np.where(actual == 0, 1, actual))) * 100
        
        r2 = r2_score(actual, predictions)
        
        metrics[model_name] = {
            'MSE': round(mse, 4),
            'RMSE': round(rmse, 4),
            'MAE': round(mae, 4),
            'MAPE': round(mape, 4),
            'R²': round(r2, 4)
        }
    
    # Print the metrics table
    print("\n" + "="*80)
    print("Model Performance Metrics")
    print("="*80)
    metric_names = list(list(metrics.values())[0].keys())

    header = "Metric".ljust(10)
    for model_name in metrics.keys():
        header += f" | {model_name.upper().ljust(15)}"
    print(header)
    print("-"*80)
    
    for metric in metric_names:
        row = metric.ljust(10)
        for model_name in metrics.keys():
            row += f" | {str(metrics[model_name][metric]).ljust(15)}"
        print(row)
    
    print("="*80)
    
    # Print percentages
    if 'sarima' in metrics and 'hybrid' in metrics:
        print("\nImprovement of Hybrid over SARIMA:")
        for metric in metric_names:
            if metric == 'R²':
                improvement = (metrics['hybrid'][metric] - metrics['sarima'][metric])
                print(f"{metric}: +{improvement:.4f} absolute")
            else:
                improvement = (metrics['sarima'][metric] - metrics['hybrid'][metric]) / metrics['sarima'][metric] * 100
                print(f"{metric}: {improvement:.2f}% reduction")
                

def main():
    mood_df = pd.read_csv('datasets/mood.csv', parse_dates=['date'], index_col='date')
    temp_df = pd.read_csv('datasets/temperature.csv', parse_dates=['date'], index_col='date')

    print("Data Loaded:")
    print("Mood:", mood_df.shape)
    print("Temperature:", temp_df.shape)

    history, forecast, train_losses, val_losses = generate_forecast(mood_df, temp_df)
    
    if forecast is not None:
        plot_forecast(history, forecast)
        plot_residuals(history)
        plot_training_losses(train_losses, val_losses)
        sarima_mae = mean_absolute_error(history['actual'], history['sarima_pred'])
        hybrid_mae = mean_absolute_error(history['actual'], history['hybrid_pred'])
        
        sarima_mse = mean_squared_error(history['actual'], history['sarima_pred'])
        hybrid_mse = mean_squared_error(history['actual'], history['hybrid_pred'])

        print(f"\nModel Performance Metrics:")
        print(f"SARIMA - MAE: {round(sarima_mae, 2)}, MSE: {round(sarima_mse, 2)}")
        print(f"Hybrid - MAE: {round(hybrid_mae, 2)}, MSE: {round(hybrid_mse, 2)}")
        print(f"Improvement - MAE: {round((sarima_mae-hybrid_mae)/sarima_mae*100, 1)}%, MSE: {round((sarima_mse-hybrid_mse)/sarima_mse*100, 1)}%")
    else:
        print("Forecasting failed.")

if __name__ == "__main__":
    main()