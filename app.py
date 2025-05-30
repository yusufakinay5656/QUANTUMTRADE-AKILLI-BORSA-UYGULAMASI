from flask import Flask, jsonify
from flask_cors import CORS
import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import ta
import json

app = Flask(__name__)
CORS(app)

def get_market_data(symbol="BTC-USD", period="1d", interval="1m"):
    """Piyasa verilerini çeker ve teknik analiz göstergelerini hesaplar"""
    try:
        # Veriyi çek
        data = yf.download(symbol, period=period, interval=interval)
        
        # Teknik göstergeleri hesapla
        data['RSI'] = ta.momentum.RSIIndicator(data['Close']).rsi()
        data['MACD'] = ta.trend.MACD(data['Close']).macd()
        data['MACD_Signal'] = ta.trend.MACD(data['Close']).macd_signal()
        data['BB_Upper'] = ta.volatility.BollingerBands(data['Close']).bollinger_hband()
        data['BB_Lower'] = ta.volatility.BollingerBands(data['Close']).bollinger_lband()
        
        return data
    except Exception as e:
        print(f"Veri çekme hatası: {e}")
        return None

def analyze_market(data):
    """Piyasa verilerini analiz eder ve yapay zeka yorumu oluşturur"""
    if data is None or len(data) < 2:
        return {
            "analysis": "Yeterli veri yok",
            "trend": "neutral",
            "sentiment": "neutral",
            "riskLevel": "Orta"
        }
    
    # Son fiyat ve değişim
    last_price = data['Close'].iloc[-1]
    price_change = ((last_price - data['Close'].iloc[-2]) / data['Close'].iloc[-2]) * 100
    
    # RSI analizi
    rsi = data['RSI'].iloc[-1]
    rsi_trend = "neutral"
    if rsi > 70:
        rsi_trend = "overbought"
    elif rsi < 30:
        rsi_trend = "oversold"
    
    # MACD analizi
    macd = data['MACD'].iloc[-1]
    macd_signal = data['MACD_Signal'].iloc[-1]
    macd_trend = "neutral"
    if macd > macd_signal:
        macd_trend = "bullish"
    else:
        macd_trend = "bearish"
    
    # Bollinger Bands analizi
    bb_upper = data['BB_Upper'].iloc[-1]
    bb_lower = data['BB_Lower'].iloc[-1]
    bb_position = (last_price - bb_lower) / (bb_upper - bb_lower)
    
    # Trend belirleme
    trend = "neutral"
    if price_change > 0.5 and macd_trend == "bullish" and rsi_trend != "overbought":
        trend = "up"
    elif price_change < -0.5 and macd_trend == "bearish" and rsi_trend != "oversold":
        trend = "down"
    
    # Risk seviyesi belirleme
    risk_level = "Orta"
    if abs(price_change) > 2 or rsi_trend in ["overbought", "oversold"]:
        risk_level = "Yüksek"
    elif abs(price_change) < 0.5 and rsi_trend == "neutral":
        risk_level = "Düşük"
    
    # Piyasa duyarlılığı
    sentiment = "positive" if trend == "up" else "negative"
    
    # Yapay zeka yorumu oluştur
    analysis = f"""
    Güncel fiyat: {last_price:.2f} (Değişim: {price_change:.2f}%)
    RSI: {rsi:.2f} - {rsi_trend.upper()}
    MACD: {macd_trend.upper()}
    Bollinger Bands pozisyonu: {bb_position:.2f}
    
    Teknik analiz göstergelerine göre piyasa {trend.upper()} trendinde hareket ediyor.
    Risk seviyesi: {risk_level}
    """
    
    return {
        "analysis": analysis,
        "trend": trend,
        "sentiment": sentiment,
        "riskLevel": risk_level
    }

@app.route('/api/ai-analysis')
def ai_analysis():
    """Yapay zeka analizi endpoint'i"""
    try:
        # Piyasa verilerini al
        data = get_market_data()
        
        # Verileri analiz et
        analysis = analyze_market(data)
        
        return jsonify(analysis)
    except Exception as e:
        return jsonify({
            "error": str(e),
            "analysis": "Analiz yapılırken bir hata oluştu",
            "trend": "neutral",
            "sentiment": "neutral",
            "riskLevel": "Orta"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 