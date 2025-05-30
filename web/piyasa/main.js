// Anlık Piyasa Verileri (market-dashboard) için canlı veri
let lastMarketPrices = {};
async function updateMarketDashboard() {
    console.log('updateMarketDashboard çağrıldı');
    try {
        const response = await fetch('http://localhost:3000/api/market/popular');
        const coins = await response.json();
        const dashboard = document.getElementById('market-dashboard');
        if (!dashboard) return;
        dashboard.innerHTML = coins.map(coin => {
            const last = lastMarketPrices[coin.symbol] || coin.price;
            const up = coin.price > last;
            const down = coin.price < last;
            lastMarketPrices[coin.symbol] = coin.price;
            return `
                <div class="coin ${up ? 'up' : down ? 'down' : ''}">
                    <strong>${coin.symbol.replace('USDT','')}:</strong> <span class="coin-price">$${coin.price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
                    <span class="coin-change ${coin.change >= 0 ? 'up' : 'down'}">${coin.change >= 0 ? '+' : ''}${coin.change.toFixed(2)}%</span>
                </div>
            `;
        }).join('');
        setTimeout(updateMarketDashboard, 1000);
    } catch (error) {
        console.log('updateMarketDashboard hata:', error);
        setTimeout(updateMarketDashboard, 3000);
    }
}

// Anlık canlı ticker kutuları (sadece live-ticker için)
let lastTickerPrices = {};
async function updateLiveTicker() {
    try {
        const response = await fetch('http://localhost:3000/api/market/live-ticker');
        const coins = await response.json();
        const ticker = document.getElementById('live-ticker');
        if (!ticker) return;
        ticker.innerHTML = coins.map(coin => {
            const last = lastTickerPrices[coin.symbol] || coin.price;
            const up = coin.price > last;
            const down = coin.price < last;
            lastTickerPrices[coin.symbol] = coin.price;
            return `
                <div class="live-coin ${up ? 'up' : down ? 'down' : ''}">
                    <span class="live-symbol">${coin.symbol.replace('USDT','')}</span>
                    <span class="live-price">$${coin.price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
                    <span class="live-change ${coin.change >= 0 ? 'up' : 'down'}">${coin.change >= 0 ? '+' : ''}${coin.change.toFixed(2)}%</span>
                </div>
            `;
        }).join('');
        setTimeout(updateLiveTicker, 1000);
    } catch (error) {
        setTimeout(updateLiveTicker, 3000);
    }
}

// Kripto haberlerini çek ve göster (yatay slider)
async function updateCryptoNews() {
    try {
        const response = await fetch('http://localhost:3000/api/market/crypto-news');
        const news = await response.json();
        const newsTrack = document.getElementById('crypto-news-track');
        if (!newsTrack) return;

        newsTrack.innerHTML = news.map(item => `
            <div class="news-card" onclick="window.open('${item.url}', '_blank')">
                ${item.urlToImage ? `<img src="${item.urlToImage}" alt="${item.title}">` : ''}
                <h3>${item.title}</h3>
                <p>${item.description || ''}</p>
                <div class="news-meta">
                    <span>${new Date(item.publishedAt).toLocaleDateString()}</span>
                    <span>${item.source && item.source.name ? item.source.name : ''}</span>
                </div>
            </div>
        `).join('');

        // Her 5 dakikada bir haberleri güncelle
        setTimeout(updateCryptoNews, 300000);
    } catch (error) {
        setTimeout(updateCryptoNews, 60000); // Hata durumunda 1 dakika sonra tekrar dene
    }
}

document.addEventListener('DOMContentLoaded', () => {
    updateMarketDashboard();
    updateLiveTicker();
    updateCryptoNews();
}); 